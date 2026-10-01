// ignore_for_file: avoid_print
/// 开发辅助脚本：端到端验证「我的圈子 / 邀请」三个接口的契约（对本地后端）。
///
/// 运行：`dart run tool/check_circle.dart [baseUrl]`
/// 流程：注册 A / B 两个临时用户 → B 关注 A → 双向核对关注与粉丝名单
/// → 以 A 的优惠码注册 C → 核对邀请名单与 `skip` 翻页。
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

bool containsUsid(List<Map<String, dynamic>> list, String usid) =>
    list.any((Map<String, dynamic> e) => e['usid']?.toString() == usid);

Future<void> main(List<String> args) async {
  final String baseUrl = args.isNotEmpty ? args.first : 'http://localhost:7739';
  final String stamp = '${DateTime.now().millisecondsSinceEpoch}';
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  try {
    print('--- 1) 注册 A / B 两个临时用户');
    final Map<String, String> a =
        await register(client, baseUrl, stamp.substring(0, 8));
    final Map<String, String> b =
        await register(client, baseUrl, stamp.substring(2, 10));
    print('    A.usid=${a['usid']} haid=${a['haid']}');
    print('    B.usid=${b['usid']} haid=${b['haid']}');

    print('--- 2) B 关注 A');
    final Map<String, dynamic> followed = await post(
        client,
        baseUrl,
        'User',
        'follow_user',
        <String, dynamic>{'followToUsid': a['usid']},
        b['passtoken']!);
    print('    follow_user _state=${followed['_state']}');

    print('--- 3) B 的关注名单里应有 A，A 的粉丝名单里应有 B');
    final Map<String, dynamic> followings = await post(client, baseUrl, 'User',
        'get_my_followings', <String, dynamic>{'takeLimit': 12}, b['passtoken']!);
    final List<Map<String, dynamic>> followingList =
        asList(followings['followingList']);
    print('    get_my_followings _state=${followings['_state']} '
        'count=${followingList.length} hasA=${containsUsid(followingList, a['usid']!)}');

    final Map<String, dynamic> followers = await post(client, baseUrl, 'User',
        'get_my_followers', <String, dynamic>{'takeLimit': 12}, a['passtoken']!);
    final List<Map<String, dynamic>> followerList =
        asList(followers['followerList']);
    print('    get_my_followers  _state=${followers['_state']} '
        'count=${followerList.length} hasB=${containsUsid(followerList, b['usid']!)}');

    print('--- 4) 用 A 的优惠码注册 C');
    final Map<String, String> c = await register(
        client, baseUrl, stamp.substring(4, 12),
        inviterHaid: a['haid']!);
    print('    C.usid=${c['usid']}  inviterHaid=${a['haid']}');

    print('--- 5) A 的邀请名单里应有 C（并核对 skip 翻页）');
    final Map<String, dynamic> invitees = await post(client, baseUrl, 'User',
        'get_invitee_list', <String, dynamic>{'takeLimit': 10, 'skip': 0},
        a['passtoken']!);
    final List<Map<String, dynamic>> inviteeList = asList(invitees['inviteeList']);
    print('    get_invitee_list _state=${invitees['_state']} '
        'count=${invitees['count']} list=${inviteeList.length} '
        'hasC=${containsUsid(inviteeList, c['usid']!)}');

    final Map<String, dynamic> page1 = await post(client, baseUrl, 'User',
        'get_invitee_list', <String, dynamic>{'takeLimit': 1, 'skip': 0},
        a['passtoken']!);
    final Map<String, dynamic> page2 = await post(client, baseUrl, 'User',
        'get_invitee_list', <String, dynamic>{'takeLimit': 1, 'skip': 1},
        a['passtoken']!);
    print('    skip=0 -> ${asList(page1['inviteeList']).length} 条, '
        'skip=1 -> ${asList(page2['inviteeList']).length} 条');

    final bool pass = followed['_state'] == 'SUCCESS' &&
        containsUsid(followingList, a['usid']!) &&
        containsUsid(followerList, b['usid']!) &&
        containsUsid(inviteeList, c['usid']!) &&
        asList(page1['inviteeList']).length == 1 &&
        asList(page2['inviteeList']).isEmpty;

    print(pass
        ? 'PASS  关注 / 粉丝 / 邀请 三个名单接口契约正确（含 skip 翻页）'
        : 'FAIL  见上面的逐项输出');
  } finally {
    client.close(force: true);
  }
}
