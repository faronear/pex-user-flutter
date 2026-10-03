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

Future<void> seed(String dbPath, String usid, String stamp) async {
  final int now = DateTime.now().millisecondsSinceEpoch;
  // uuid 必须「每次运行 × 每条记录」都不同（撞了会触发唯一约束）。
  String uuid(String suffix) =>
      '3f2a-${stamp.substring(stamp.length - 8)}-$suffix';
  final List<String> sql = <String>[
    // 两笔充值（TXG_RECHARGE）
    "INSERT INTO tx_user_recharge (txUuid, txType, txTimeUnix, txAmount, fromUsid, toUsid, json, dpCoinCode, dpAmount, dpTradeCode, dpOrderCode, txGroup, dpChannel, appkey) "
        "VALUES ('${uuid('r1')}', 'USER_RECHARGE', ${now - 3600000}, 10, 'AGENT_USID', '$usid', '{}', 'CNY', 10, 'check-fund-$stamp-1', 'check-fund-$stamp-order1', 'USER_DEPOSIT', 'WXPAY', 'AKBABELY')",
    "INSERT INTO tx_user_recharge (txUuid, txType, txTimeUnix, txAmount, fromUsid, toUsid, json, dpCoinCode, dpAmount, dpTradeCode, dpOrderCode, txGroup, dpChannel, appkey) "
        "VALUES ('${uuid('r2')}', 'USER_RECHARGE', ${now - 7200000}, 5, 'AGENT_USID', '$usid', '{}', 'CNY', 5, 'check-fund-$stamp-2', 'check-fund-$stamp-order2', 'USER_DEPOSIT', 'ALIPAY', 'AKBABELY')",
    // 一笔注册奖励（TXG_IN_REWARD）
    "INSERT INTO tx_user_reward (txUuid, txType, txTimeUnix, txAmount, fromUsid, toUsid, json, txGroup, appkey) "
        "VALUES ('${uuid('w1')}', 'TXT_IN_REGISTER', ${now - 10800000}, 100, 'AGENT_USID', '$usid', '{}', 'USER_REWARD', 'AKBABELY')",
    // 一条「我解密了」的支出（TXG_OUT_PEX）
    "INSERT INTO tx_pex_view (txUuid, txType, txTimeUnix, txAmount, fromUsid, toUsid, json, txGroup, appkey, viewCsid, pexBaseCidRoot) "
        "VALUES ('${uuid('v1')}', 'PAY_TO_VIEW', ${now - 14400000}, 3, '$usid', 'AGENT_USID', '{}', 'PEX_VIEW', 'AKBABELY', 'check-fund-csid', 'check-fund-root')",
    // 一条「被解密了」的收入（TXG_IN_PEX_CREATOR）
    "INSERT INTO tx_pex_view (txUuid, txType, txTimeUnix, txAmount, fromUsid, toUsid, json, txGroup, appkey, viewCsid, pexBaseCidRoot) "
        "VALUES ('${uuid('v2')}', 'PAY_TO_VIEW_TO_CREATOR', ${now - 18000000}, 7, 'AGENT_USID', '$usid', '{}', 'PEX_VIEW', 'AKBABELY', 'check-fund-csid', 'check-fund-root')",
  ];
  for (final String statement in sql) {
    final ProcessResult result =
        await Process.run('sqlite3', <String>[dbPath, statement]);
    if (result.exitCode != 0) {
      throw StateError('sqlite3 失败：${result.stderr}');
    }
  }
}

Future<void> main(List<String> args) async {
  final String baseUrl = args.isNotEmpty ? args.first : 'http://localhost:7739';
  const String dbPath = '../pex-server-torm/_datastore/pex.sqlite.db';
  final String stamp = '${DateTime.now().millisecondsSinceEpoch}';
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  try {
    print('--- 1) 注册临时用户 A');
    // 注意：注册用的是 `stamp` 的后 8 位——毫秒时间戳的**前 8 位**要好几个小时才变一次，
    // 连跑两次会撞号（第一次写这个工具时就踩了）。
    final Map<String, String> a = await register(
        client, baseUrl, stamp.substring(stamp.length - 8));
    final String usid = a['usid']!;
    print('    usid=$usid');

    print('--- 2) 直接写入测试流水（充值 x2 / 注册奖励 x1 / 我的支出 x1 / 我的收入 x1）');
    await seed(dbPath, usid, stamp);
    print('    已写入 $dbPath');

    Future<Map<String, dynamic>> txList(String tag,
            {int takeLimit = 10, int? beforeTime}) =>
        post(
            client,
            baseUrl,
            'User',
            'get_tx_list',
            <String, dynamic>{
              'txTag': tag,
              'takeLimit': takeLimit,
              'beforeTime': ?beforeTime,
            },
            a['passtoken']!);

    print('--- 3) 逐标签读取');
    final Map<String, dynamic> all = await txList('TXG_ALL');
    final Map<String, dynamic> recharge = await txList('TXG_RECHARGE');
    final Map<String, dynamic> reward = await txList('TXG_IN_REWARD');
    final Map<String, dynamic> outPex = await txList('TXG_OUT_PEX');
    final Map<String, dynamic> inPex = await txList('TXG_IN_PEX_CREATOR');
    print('    TXG_ALL          _state=${all['_state']} count=${all['count']} '
        'list=${asList(all['txList']).length}');
    print('    TXG_RECHARGE     _state=${recharge['_state']} '
        'list=${asList(recharge['txList']).length}');
    print('    TXG_IN_REWARD    _state=${reward['_state']} '
        'list=${asList(reward['txList']).length}');
    print('    TXG_OUT_PEX      _state=${outPex['_state']} '
        'list=${asList(outPex['txList']).length}');
    print('    TXG_IN_PEX_CREATOR _state=${inPex['_state']} '
        'list=${asList(inPex['txList']).length}');

    print('--- 4) 排序与 beforeTime 翻页');
    final List<Map<String, dynamic>> rechargeList = asList(recharge['txList']);
    final bool desc = rechargeList.length >= 2 &&
        (rechargeList.first['txTimeUnix'] as num) >
            (rechargeList[1]['txTimeUnix'] as num);
    final Map<String, dynamic> page1 =
        await txList('TXG_RECHARGE', takeLimit: 1);
    final List<Map<String, dynamic>> page1List = asList(page1['txList']);
    final Map<String, dynamic> page2 = await txList(
        'TXG_RECHARGE',
        takeLimit: 1,
        beforeTime: page1List.isEmpty
            ? null
            : (page1List.first['txTimeUnix'] as num).toInt());
    final List<Map<String, dynamic>> page2List = asList(page2['txList']);
    final bool paged = page1List.length == 1 &&
        page2List.length == 1 &&
        page1List.first['txUuid'] != page2List.first['txUuid'];
    print('    倒序=$desc  第1页=${page1List.length} 条  第2页=${page2List.length} 条  翻页正确=$paged');

    print('--- 5) 资金页要用的用户字段');
    final Map<String, dynamic> touched = await post(
        client, baseUrl, 'User', 'first_touch', <String, dynamic>{},
        a['passtoken']!);
    final Map<String, dynamic> online =
        (touched['onlineUser'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final List<String> wanted = <String>[
      'balanceTUC',
      'sumInRecharges',
      'sumInRewards',
      'sumInPexCreator',
      'sumInPexOwner',
      'sumOutPexView',
      'sumOutPexHold',
      'sumOutPexOwn',
      'caddTUC',
    ];
    final List<String> missing = wanted
        .where((String key) => !online.containsKey(key))
        .toList();
    print('    onlineUser 字段齐全=${missing.isEmpty}${missing.isEmpty ? '' : ' 缺：$missing'}');

    print('--- 6) 清理测试流水');
    for (final String table in <String>[
      'tx_user_recharge',
      'tx_user_reward',
      'tx_pex_view',
    ]) {
      await Process.run('sqlite3', <String>[
        dbPath,
        "DELETE FROM $table WHERE toUsid = '$usid' OR fromUsid = '$usid'",
      ]);
    }
    print('    已清理');

    // 说明：`TXG_ALL` 不返回 count（后端只返回聚合后的列表）；
    // `TXG_IN_REWARD` 除了脚本写的 1 条，注册本身也会送一条注册奖励，故用 >= 1。
    final bool pass = all['_state'] == 'SUCCESS' &&
        asList(all['txList']).length >= 5 &&
        asList(recharge['txList']).length == 2 &&
        asList(reward['txList']).isNotEmpty &&
        asList(outPex['txList']).length == 1 &&
        asList(inPex['txList']).length == 1 &&
        desc &&
        paged &&
        missing.isEmpty;

    print(pass
        ? 'PASS  资金域读取契约正确（各标签 / 排序 / beforeTime 翻页 / 用户汇总字段）'
        : 'FAIL  见上面的逐项输出');
  } finally {
    client.close(force: true);
  }
}
