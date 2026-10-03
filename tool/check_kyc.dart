// ignore_for_file: avoid_print
/// 开发辅助脚本：端到端验证「实名认证」接口契约（对本地后端）。
///
/// 运行：`dart run tool/check_kyc.dart [baseUrl]`
/// 流程：注册临时用户 → 缺字段应被拒（INPUT_MALFORMED，不发信）→ 完整提交（**会真发 1 封邮件**
/// 到 `envar.oncallMessage.to`，别在循环里跑）→ 复查 `kycStateL1` → 重复提交应被拒（BER_UNEXPECTED）。
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



Future<void> main(List<String> args) async {
  final String baseUrl = args.isNotEmpty ? args.first : 'http://localhost:7739';
  final String stamp = '${DateTime.now().millisecondsSinceEpoch}';
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  try {
    print('--- 1) 注册临时用户');
    final Map<String, String> me =
        await register(client, baseUrl, stamp.substring(0, 8));
    print('    usid=${me['usid']}');

    print('--- 2) 缺字段应被拒（INPUT_MALFORMED，不发信）');
    final Map<String, dynamic> bad = await post(
        client,
        baseUrl,
        'User',
        'update_kyc',
        <String, dynamic>{
          'User': <String, dynamic>{'realname': '缺字段测试'},
        },
        me['passtoken']!);
    print('    update_kyc(缺字段) _state=${bad['_state']}');

    print('--- 3) 完整提交（注意：后端会真发一封邮件给值班邮箱）');
    final Map<String, dynamic> ok = await post(
        client,
        baseUrl,
        'User',
        'update_kyc',
        <String, dynamic>{
          'User': <String, dynamic>{
            'realname': '契约自检用户',
            'citizen': 'CN',
            'idType': 'IDCARD',
            'idNumber': '110101199001011234',
            'idCardCover': 'kyc-check-cover.jpg',
            'idCardBack': 'kyc-check-back.jpg',
          },
        },
        me['passtoken']!);
    print('    update_kyc(完整) _state=${ok['_state']}');

    print('--- 4) 复查 kycStateL1 应为 SUBMITTED');
    final Map<String, dynamic> touched = await post(
        client, baseUrl, 'User', 'first_touch', <String, dynamic>{},
        me['passtoken']!);
    final Map<String, dynamic> online =
        (touched['onlineUser'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    print('    kycStateL1=${online['kycStateL1']} realname=${online['realname']} '
        'citizen=${online['citizen']} idType=${online['idType']}');

    print('--- 5) 重复提交应被拒（BER_UNEXPECTED，不发信）');
    final Map<String, dynamic> again = await post(
        client,
        baseUrl,
        'User',
        'update_kyc',
        <String, dynamic>{
          'User': <String, dynamic>{
            'realname': '契约自检用户',
            'citizen': 'CN',
            'idType': 'IDCARD',
            'idNumber': '110101199001011234',
            'idCardCover': 'kyc-check-cover.jpg',
            'idCardBack': 'kyc-check-back.jpg',
          },
        },
        me['passtoken']!);
    print('    update_kyc(重复) _state=${again['_state']}');

    final bool pass = bad['_state'] == 'INPUT_MALFORMED' &&
        ok['_state'] == 'SUBMITTED' &&
        online['kycStateL1']?.toString() == 'SUBMITTED' &&
        online['realname']?.toString() == '契约自检用户' &&
        again['_state'] == 'BER_UNEXPECTED';

    print(pass
        ? 'PASS  实名认证接口契约正确（缺字段 / 提交 / 落库 / 重复提交）'
        : 'FAIL  见上面的逐项输出');
  } finally {
    client.close(force: true);
  }
}
