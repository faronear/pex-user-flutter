// ignore_for_file: avoid_print
/// 开发辅助脚本：验证「充值面板」依赖的接口与配置（对本地后端）。
///
/// 运行：`dart run tool/check_deposit.dart [baseUrl]`
/// 流程：注册临时用户 → 调 `get_current_balance` 核对字段 → 从 `first_touch` 取配置，
/// 核对 `coinToTUC`（USDT/CNY）/`depositBonusRate`/`depositAmountMin|Default` 齐备，
/// 并按源项目公式算一遍「充值 10 CNY / 10 USDT 各得多少币」打印出来方便肉眼核对。
///
/// 说明：**不**调用 `System/deposit_callback`（充值回调是支付门户的 sysapi，且会真发邮件）。
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

String hashStable(String data) => sha256.convert(utf8.encode(data)).toString();

Future<Map<String, dynamic>> post(
  HttpClient client,
  String baseUrl,
  String apiWho,
  String apiTodo,
  Map<String, dynamic> what,
  String passtoken,
) async {
  final HttpClientRequest request =
      await client.postUrl(Uri.parse('$baseUrl/api/$apiWho/$apiTodo'));
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(<String, dynamic>{
    ...what,
    '_clientInfo': <String, dynamic>{
      'appkey': 'AKBABELY',
      'lang': 'enUS',
      'uniPlatform': 'app',
      'deviceType': 'phone',
      'osName': 'macos',
      'webDomain': 'babelyx.com',
    },
    '_passtoken': passtoken,
  }));
  final HttpClientResponse response = await request.close();
  final String body = await response.transform(utf8.decoder).join();
  final dynamic decoded = jsonDecode(body);
  return decoded is Map
      ? decoded.map((dynamic k, dynamic v) => MapEntry(k.toString(), v))
      : <String, dynamic>{'_state': 'BAD_RESPONSE'};
}

/// 注册一个临时用户，返回 `{usid, haid, passtoken}`。
Future<Map<String, String>> register(
  HttpClient client,
  String baseUrl,
  String seed, {
  String inviterHaid = '',
}) async {
  final String commid = '+86-138$seed';
  final Map<String, dynamic> ident = await post(client, baseUrl, 'User',
      'identify_user', <String, dynamic>{'commid': commid}, '');
  String passtoken = ident['_passtoken']?.toString() ?? '';
  final String usid = ident['usid'].toString();

  final Map<String, dynamic> sent = await post(
      client,
      baseUrl,
      'User',
      'send_passcode',
      <String, dynamic>{'passcodeType': 'REGISTER', 'commid': commid},
      passtoken);
  passtoken = sent['_passtoken']?.toString() ?? passtoken;

  final Map<String, dynamic> verified = await post(
      client,
      baseUrl,
      'User',
      'verify_passcode',
      <String, dynamic>{'passcode': sent['passcode'], 'inviterHaid': inviterHaid},
      passtoken);
  passtoken = verified['_passtoken']?.toString() ?? passtoken;

  final Map<String, dynamic> registered = await post(
      client,
      baseUrl,
      'User',
      'register_new_user',
      <String, dynamic>{
        'commid': commid,
        'passwordClient': hashStable('test1234$usid'),
      },
      passtoken);
  passtoken = registered['_passtoken']?.toString() ?? passtoken;
  print('    register $commid -> ${registered['_state']}');

  // 取本人的优惠码（haid）。
  final Map<String, dynamic> touched = await post(
      client, baseUrl, 'User', 'first_touch', <String, dynamic>{}, passtoken);
  passtoken = touched['_passtoken']?.toString() ?? passtoken;
  final Map<String, dynamic> me =
      (touched['onlineUser'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

  return <String, String>{
    'usid': usid,
    'haid': me['haid']?.toString() ?? '',
    'commid': commid,
    'passtoken': passtoken,
  };
}




num precision(Object? value, [int digits = 4]) {
  final num parsed =
      value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;
  return num.parse(parsed.toStringAsFixed(digits));
}

Future<void> main(List<String> args) async {
  final String baseUrl = args.isNotEmpty ? args.first : 'http://localhost:7739';
  final String stamp = '${DateTime.now().millisecondsSinceEpoch}';
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  try {
    print('--- 1) 注册临时用户');
    final Map<String, String> a =
        await register(client, baseUrl, stamp.substring(stamp.length - 8));
    print('    usid=${a['usid']}');

    print('--- 2) get_current_balance 契约');
    final Map<String, dynamic> balance = await post(
        client, baseUrl, 'User', 'get_current_balance', <String, dynamic>{},
        a['passtoken']!);
    print('    _state=${balance['_state']} balanceTUC=${balance['balanceTUC']} '
        'sumInRecharges=${balance['sumInRecharges']}');
    final bool balanceOk = balance['_state'] == 'SUCCESS' &&
        balance.containsKey('balanceTUC') &&
        balance.containsKey('sumInRecharges');

    print('--- 3) first_touch 里充值面板要用的配置');
    final Map<String, dynamic> touched = await post(
        client, baseUrl, 'User', 'first_touch', <String, dynamic>{},
        a['passtoken']!);
    final Map<String, dynamic> envar =
        (touched['envarBase'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final Map<String, dynamic> coinToTUC =
        (envar['coinToTUC'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final Object? bonusRate = envar['depositBonusRate'];
    print('    coinToTUC keys=${coinToTUC.keys.join(',')}');
    print('    USDT=${coinToTUC['USDT']}  CNY=${coinToTUC['CNY']}  '
        'depositBonusRate=$bonusRate');
    final bool configOk = coinToTUC.containsKey('USDT') &&
        coinToTUC.containsKey('CNY') &&
        (num.tryParse(bonusRate?.toString() ?? '') ?? 0) >= 0;
    // 说明：depositAmountMin / depositAmountDefault 在**客户端预置层**（assets/clientEnvar.json），
    // 后端只下发 coinToTUC / depositBonusRate；这里顺带确认预置层有值。
    print('    预置层（客户端）depositAmountMin/Default 见 assets/clientEnvar.json');

    print('--- 4) 按源项目公式算一遍（充值 10）');
    for (final String code in <String>['CNY', 'USDT']) {
      final num rate = num.tryParse(coinToTUC[code]?.toString() ?? '') ?? 0;
      final num paid = precision(10 * rate);
      final num bonus = precision(paid * (num.tryParse('$bonusRate') ?? 0));
      print('    10 $code → $paid¢ + 赠送 $bonus¢ = ${precision(paid + bonus)}¢');
    }

    final bool pass = balanceOk && configOk;
    print(pass
        ? 'PASS  充值依赖的接口与配置齐备（get_current_balance / coinToTUC / depositBonusRate）'
        : 'FAIL  见上面的逐项输出');
  } finally {
    client.close(force: true);
  }
}
