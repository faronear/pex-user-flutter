// ignore_for_file: avoid_print
/// 开发辅助脚本：端到端验证 showCreation 2C 付费链路（对本地后端）。
///
/// 运行：`dart run tool/check_creation_pay.dart [baseUrl]`
/// 流程：注册临时用户 → 找一个「需付费解密」的作品 → 校验余额 → `pay_to_view`
/// → 复查 `get_single_creation` 是否已带 `pexdataUser`（即已解锁）。
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

Future<void> main(List<String> args) async {
  final String baseUrl = args.isNotEmpty ? args.first : 'http://localhost:7739';
  final String commid =
      '+86-138${DateTime.now().millisecondsSinceEpoch % 100000000}';

  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);
  String passtoken = '';

  try {
    print('--- 1) 注册临时用户 $commid');
    final Map<String, dynamic> ident = await post(
        client, baseUrl, 'User', 'identify_user', <String, dynamic>{'commid': commid}, '');
    passtoken = ident['_passtoken']?.toString() ?? '';
    if (ident['_state'] != 'NEW_USER') {
      print('FAIL  非新用户，终止');
      return;
    }
    final String usid = ident['usid'].toString();
    final Map<String, dynamic> sent = await post(
        client, baseUrl, 'User', 'send_passcode',
        <String, dynamic>{'passcodeType': 'REGISTER', 'commid': commid}, passtoken);
    passtoken = sent['_passtoken']?.toString() ?? passtoken;
    final Map<String, dynamic> verified = await post(
        client, baseUrl, 'User', 'verify_passcode',
        <String, dynamic>{'passcode': sent['passcode'], 'inviterHaid': ''}, passtoken);
    passtoken = verified['_passtoken']?.toString() ?? passtoken;
    final Map<String, dynamic> registered = await post(
        client, baseUrl, 'User', 'register_new_user',
        <String, dynamic>{
          'commid': commid,
          'passwordClient': hashStable('test1234$usid'),
        },
        passtoken);
    passtoken = registered['_passtoken']?.toString() ?? passtoken;
    final Map<String, dynamic> me =
        (registered['onlineUser'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final num balance = (me['balanceTUC'] is num) ? me['balanceTUC'] as num : 0;
    print('  register _state=${registered['_state']}  余额=$balance');

    print('--- 2) 找一个需付费解密的作品');
    final Map<String, dynamic> list = await post(client, baseUrl, 'Creation',
        'get_creation_list', <String, dynamic>{'takeLimit': 12}, passtoken);
    final List<dynamic> items = (list['creationList'] as List?) ?? <dynamic>[];
    Map<String, dynamic>? target;
    for (final dynamic item in items) {
      final Map<String, dynamic> c = (item as Map).cast<String, dynamic>();
      final Object? pact = c['viewerPact'];
      final num amount = pact is Map
          ? ((pact['amount'] is num) ? pact['amount'] as num : 0)
          : 0;
      final bool locked = c['pexdataUser'] == null;
      final bool forbidden = pact is Map && pact['type']?.toString() == 'FORBIDDEN';
      if (locked && !forbidden && amount > 0) {
        target = c;
        print('  csid=${c['csid']}  解密价=$amount  余额=$balance');
        break;
      }
    }
    if (target == null) {
      print('FAIL  列表里没有「需付费且可解密」的作品（可能都已解锁）');
      return;
    }
    final String csid = target['csid'].toString();

    print('--- 3) pay_to_view');
    final Map<String, dynamic> paid = await post(client, baseUrl, 'Creation',
        'pay_to_view', <String, dynamic>{'viewCsid': csid}, passtoken);
    print('  _state=${paid['_state']}  _msg=${paid['_msg']}');
    if (paid['_state'] != 'SUCCESS') {
      print('FAIL  解密支付未成功');
      return;
    }
    final bool hasPexdata = paid['pexdataUser'] != null;
    print('  返回 pexdataUser? $hasPexdata');

    print('--- 4) 复查 get_single_creation 是否已解锁');
    final Map<String, dynamic> single = await post(client, baseUrl, 'Creation',
        'get_single_creation', <String, dynamic>{'csid': csid}, passtoken);
    final Map<String, dynamic> c =
        (single['creation'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final bool unlocked = c['pexdataUser'] != null;
    final bool myView = c['mytxView_txAmount'] != null;
    print('  pexdataUser? $unlocked   mytxView_txAmount? $myView   countViewer=${c['countViewer']}');

    print('--- 5) 名单接口（2D）契约核对');
    final List<(String, String, String)> lists = <(String, String, String)>[
      ('get_viewer_list', 'viewerList', 'viewCsid'),
      ('get_holder_list', 'holderList', 'holdCsid'),
      ('get_fueler_list', 'fuelerList', 'fuelCsid'),
      ('get_liker_list', 'likerList', 'likeCsid'),
    ];
    bool listsOk = true;
    for (final (String api, String key, String param) in lists) {
      final Map<String, dynamic> data = await post(
          client,
          baseUrl,
          'Creation',
          api,
          <String, dynamic>{param: csid, 'takeLimit': 5},
          passtoken);
      final bool isList = data[key] is List;
      if (!isList) listsOk = false;
      print('  $api _state=${data['_state']}  $key=${isList ? (data[key] as List).length : data[key]}');
    }

    print('--- 6) 2E 接口契约（隐藏/显示可逆；上下架与删除对非本人应被拒绝）');
    bool e2Ok = true;
    final Map<String, dynamic> target2 = (single['creation'] as Map).cast<String, dynamic>();
    final Map<String, dynamic> hidden = await post(
        client,
        baseUrl,
        'Creation',
        'hide_creation',
        <String, dynamic>{'hideTarget': target2['pexdataCidHashRoot'], 'hideCsid': csid},
        passtoken);
    print('  hide_creation   _state=${hidden['_state']}');
    e2Ok &= hidden['_state'] == 'SUCCESS';

    final Map<String, dynamic> shown = await post(
        client,
        baseUrl,
        'Creation',
        'unhide_creation',
        <String, dynamic>{'hideTarget': target2['pexdataCidHashRoot'], 'hideCsid': csid},
        passtoken);
    print('  unhide_creation _state=${shown['_state']}');
    e2Ok &= shown['_state'] == 'SUCCESS';

    final List<(String, String, String)> guarded = <(String, String, String)>[
      ('unlist_creation', 'unlistCsid', 'ERROR_UNAUTHORIZED_USER'),
      ('list_creation', 'listCsid', 'ERROR_UNAUTHORIZED_USER'),
      ('delete_creation_from_remove', 'delCsid', 'ERROR_UNAUTHORIZED_USER'),
    ];
    for (final (String api, String param, String expect) in guarded) {
      final Map<String, dynamic> data = await post(
          client, baseUrl, 'Creation', api, <String, dynamic>{param: csid}, passtoken);
      final bool ok = data['_state']?.toString() == expect;
      e2Ok &= ok;
      print('  $api _state=${data['_state']}（期望 $expect）${ok ? ' OK' : ' ✗'}');
    }

    print('--- 7) 2F 举报接口（User/report_complain）');
    final Map<String, dynamic> reported = await post(
        client,
        baseUrl,
        'User',
        'report_complain',
        <String, dynamic>{
          'reportTargetId': csid,
          'reportTargetType': 'CREATION',
          'reportReason': 'contract check ${DateTime.now().millisecondsSinceEpoch}',
        },
        passtoken);
    print('  _state=${reported['_state']}  _msg=${reported['_msg']}');
    final bool reportOk = reported['_state'] == 'SUCCESS';

    print(hasPexdata && unlocked && listsOk && e2Ok && reportOk
        ? 'PASS  解密支付 + 名单 + 2E + 2F 举报契约均正确'
        : 'FAIL  存在异常');
  } finally {
    client.close(force: true);
  }
}
