// ignore_for_file: avoid_print
/// 开发辅助脚本：验证「资金域」读取契约（对本地后端 + 本地 sqlite）。
///
/// 运行：`dart run tool/check_fund.dart [baseUrl]`
/// 流程：注册临时用户 A → **直接用 sqlite 写入几条流水**（模拟充值/奖励等其它流程的产物；
/// 这些写入路径属于尚未迁移的 `partDeposit` 等页面，本工具只验证读取）→
/// 逐个标签调 `get_tx_list`、核对数量与 `beforeTime` 翻页 → 复查 `first_touch` 里的余额与汇总字段。
///
/// 注意：会向 `pex-server-torm/_datastore/pex.sqlite.db` 插入测试数据（仅用于本地开发）。
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



List<Map<String, dynamic>> asList(Object? value) => value is List
    ? value.whereType<Map>().map((Map e) => e.cast<String, dynamic>()).toList()
    : <Map<String, dynamic>>[];


Future<void> main(List<String> args) async {
  final String baseUrl = args.isNotEmpty ? args.first : 'http://localhost:7739';
  const String dbPath = '../pex-server-torm/_datastore/pex.sqlite.db';
  final String stamp = '${DateTime.now().millisecondsSinceEpoch}';
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  try {
    print('--- 1) 注册临时用户');
    final Map<String, String> a =
        await register(client, baseUrl, stamp.substring(stamp.length - 8));
    final String usid = a['usid']!;
    print('    usid=$usid');

    print('--- 2) 新建提现渠道');
    final Map<String, dynamic> added = await post(
        client,
        baseUrl,
        'User',
        'add_payto_channel',
        <String, dynamic>{
          'channel': <String, dynamic>{
            'coinType': 'TUC',
            'TUC_chainType': 'MATIC_MAINNET',
            'TUC_accountId': '0x1E70cd9E506F6081fce71E00103937b1946A716F',
          },
        },
        a['passtoken']!);
    final String channelUuid = added['channelUuid']?.toString() ?? '';
    print('    add_payto_channel _state=${added['_state']} channelUuid=$channelUuid');

    print('--- 3) 读回在线用户，确认渠道与字段都在');
    final Map<String, dynamic> touched = await post(
        client, baseUrl, 'User', 'first_touch', <String, dynamic>{},
        a['passtoken']!);
    final Map<String, dynamic> online =
        (touched['onlineUser'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final Map<String, dynamic> channels =
        (online['paytoChannels'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final Map<String, dynamic> channel =
        (channels[channelUuid] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    print('    渠道数=${channels.length} 该渠道 coinType=${channel['coinType']} '
        'chain=${channel['TUC_chainType']} account=${channel['TUC_accountId']} '
        'appkey=${channel['appkey']}');
    final bool channelOk = channel['coinType'] == 'TUC' &&
        channel['TUC_chainType'] == 'MATIC_MAINNET' &&
        (channel['TUC_accountId']?.toString() ?? '').startsWith('0x');

    Future<Map<String, dynamic>> withdraw(num amount, String uuid) => post(
        client,
        baseUrl,
        'User',
        'request_withdrawal',
        <String, dynamic>{'withdrawAmount': amount, 'channelUuid': uuid},
        a['passtoken']!);

    print('--- 4) 提现的三个拒绝分支（都不发信）');
    final Map<String, dynamic> noChannel =
        await withdraw(2000, 'not-a-real-uuid');
    print('    渠道不存在 -> ${noChannel['_state']}');
    final Map<String, dynamic> tooSmall = await withdraw(1, channelUuid);
    print('    低于下限(1) -> ${tooSmall['_state']}');
    final Map<String, dynamic> tooBig = await withdraw(999999, channelUuid);
    print('    超出余额 -> ${tooBig['_state']}');

    print('--- 5) 临时加余额（提现下限 1000，注册奖励只有 100）');
    await Process.run('sqlite3', <String>[
      dbPath,
      "UPDATE user SET balanceTUC = 5000 WHERE usid = '$usid'",
    ]);
    final Map<String, dynamic> topped = await post(
        client, baseUrl, 'User', 'first_touch', <String, dynamic>{},
        a['passtoken']!);
    final num balanceBefore = ((topped['onlineUser'] as Map?)?['balanceTUC'] as num?) ?? 0;
    print('    余额=$balanceBefore');

    print('--- 6) 正常提交（**后端会发一封邮件给值班邮箱**）');
    final Map<String, dynamic> ok = await withdraw(1000, channelUuid);
    print('    request_withdrawal _state=${ok['_state']}');
    final Map<String, dynamic> after = await post(
        client, baseUrl, 'User', 'first_touch', <String, dynamic>{},
        a['passtoken']!);
    final num balanceAfter = ((after['onlineUser'] as Map?)?['balanceTUC'] as num?) ?? 0;
    print('    扣款后余额=$balanceAfter');

    print('--- 7) 删渠道，确认 lifeState 变 DELETED');
    final Map<String, dynamic> removed = await post(
        client,
        baseUrl,
        'User',
        'delete_payto_channel',
        <String, dynamic>{'channelUuid': channelUuid},
        a['passtoken']!);
    final Map<String, dynamic> afterDelete =
        (removed['paytoChannels'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final String lifeState =
        ((afterDelete[channelUuid] as Map?)?['lifeState']).toString();
    print('    delete_payto_channel _state=${removed['_state']} lifeState=$lifeState');

    print('--- 8) 清理测试数据（提现流水 + 余额）');
    await Process.run('sqlite3', <String>[
      dbPath,
      "DELETE FROM user_fund_withdraw WHERE fwUsid = '$usid'; "
          "UPDATE user SET balanceTUC = 100 WHERE usid = '$usid';",
    ]);
    print('    已清理');

    final bool pass = added['_state'] == 'SUCCESS' &&
        channelUuid.isNotEmpty &&
        channelOk &&
        noChannel['_state'] == 'FAILED' &&
        tooSmall['_state'] == 'FAILED' &&
        tooBig['_state'] == 'FAILED' &&
        ok['_state'] == 'SUCCESS' &&
        (balanceBefore - balanceAfter) == 1000 &&
        removed['_state'] == 'SUCCESS' &&
        lifeState == 'DELETED';

    print(pass
        ? 'PASS  提现渠道 + 申请提现契约正确（建/查/四种提现分支/删除）'
        : 'FAIL  见上面的逐项输出');
  } finally {
    client.close(force: true);
  }
}
