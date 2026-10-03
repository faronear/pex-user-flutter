// ignore_for_file: avoid_print
/// 开发辅助脚本：端到端验证「创作者主页」相关接口契约（对本地后端）。
///
/// 运行：`dart run tool/check_creator.dart [baseUrl]`
/// 流程：注册 A / B → 按 usid / haid / unid 三种方式查 A（含两种错误码）→ 取 A 的创作品列表
/// → B 关注 / 取消关注 A 并复查 `followState` → B 屏蔽 / 解除屏蔽 A 并复查 `blockState`。
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
  final String stamp = '${DateTime.now().millisecondsSinceEpoch}';
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  try {
    print('--- 1) 注册 A / B 两个临时用户');
    final Map<String, String> a =
        await register(client, baseUrl, stamp.substring(0, 8));
    final Map<String, String> b =
        await register(client, baseUrl, stamp.substring(2, 10));
    print('    A=${a['usid']} haid=${a['haid']}');

    print('--- 2) 三种查人方式');
    final Map<String, dynamic> byUsid = await post(
        client,
        baseUrl,
        'User',
        'get_single_creator',
        <String, dynamic>{'usid': a['usid']},
        b['passtoken']!);
    final Map<String, dynamic> byHaid = await post(
        client,
        baseUrl,
        'User',
        'get_single_creator',
        <String, dynamic>{'haid': a['haid']},
        b['passtoken']!);
    final Map<String, dynamic> byUnid = await post(
        client,
        baseUrl,
        'User',
        'get_single_creator',
        <String, dynamic>{'unid': a['usid']},
        b['passtoken']!);
    print('    usid -> ${byUsid['_state']} nickname=${(byUsid['user'] as Map?)?['nickname']}');
    print('    haid -> ${byHaid['_state']}');
    print('    unid -> ${byUnid['_state']}');

    print('--- 3) 两种错误码');
    final Map<String, dynamic> none = await post(
        client, baseUrl, 'User', 'get_single_creator', <String, dynamic>{},
        b['passtoken']!);
    final Map<String, dynamic> bad = await post(
        client,
        baseUrl,
        'User',
        'get_single_creator',
        <String, dynamic>{'unid': 'zzz'},
        b['passtoken']!);
    print('    无参数 -> ${none['_state']}');
    print('    坏 unid -> ${bad['_state']}');

    print('--- 4) 取 A 的创作品列表');
    final Map<String, dynamic> creations = await post(
        client,
        baseUrl,
        'Creation',
        'get_user_creations',
        <String, dynamic>{'usid': a['usid'], 'takeLimit': 12},
        b['passtoken']!);
    print('    get_user_creations _state=${creations['_state']} '
        'count=${asList(creations['collection']).length}');

    print('--- 5) B 关注 / 取消关注 A，并复查 followState');
    await post(client, baseUrl, 'User', 'follow_user',
        <String, dynamic>{'followToUsid': a['usid']}, b['passtoken']!);
    final Map<String, dynamic> afterFollow = await post(
        client,
        baseUrl,
        'User',
        'get_single_creator',
        <String, dynamic>{'usid': a['usid']},
        b['passtoken']!);
    print('    关注后 followState=${(afterFollow['user'] as Map?)?['followState']} '
        'countFollower=${(afterFollow['user'] as Map?)?['countFollower']}');
    await post(client, baseUrl, 'User', 'unfollow_user',
        <String, dynamic>{'followToUsid': a['usid']}, b['passtoken']!);
    final Map<String, dynamic> afterUnfollow = await post(
        client,
        baseUrl,
        'User',
        'get_single_creator',
        <String, dynamic>{'usid': a['usid']},
        b['passtoken']!);
    print('    取关后 followState=${(afterUnfollow['user'] as Map?)?['followState']}');

    print('--- 6) B 屏蔽 / 解除屏蔽 A，并复查 blockState');
    await post(client, baseUrl, 'User', 'block_user',
        <String, dynamic>{'blockToUsid': a['usid']}, b['passtoken']!);
    final Map<String, dynamic> afterBlock = await post(
        client,
        baseUrl,
        'User',
        'get_single_creator',
        <String, dynamic>{'usid': a['usid']},
        b['passtoken']!);
    print('    屏蔽后 blockState=${(afterBlock['user'] as Map?)?['blockState']}');
    await post(client, baseUrl, 'User', 'unblock_user',
        <String, dynamic>{'blockToUsid': a['usid']}, b['passtoken']!);
    final Map<String, dynamic> afterUnblock = await post(
        client,
        baseUrl,
        'User',
        'get_single_creator',
        <String, dynamic>{'usid': a['usid']},
        b['passtoken']!);
    print('    解封后 blockState=${(afterUnblock['user'] as Map?)?['blockState']}');

    final bool pass = (byUsid['user'] as Map?)?['usid'] == a['usid'] &&
        (byHaid['user'] as Map?)?['usid'] == a['usid'] &&
        (byUnid['user'] as Map?)?['usid'] == a['usid'] &&
        none['_state'] == 'ERROR_USID_MISSING' &&
        bad['_state'] == 'ERROR_BAD_UNID' &&
        creations['_state'] == 'SUCCESS' &&
        (afterFollow['user'] as Map?)?['followState'] == 'FOLLOWED' &&
        (afterUnfollow['user'] as Map?)?['followState'] == 'UNFOLLOWED' &&
        (afterBlock['user'] as Map?)?['blockState'] == 'BLOCKED' &&
        (afterUnblock['user'] as Map?)?['blockState'] == 'UNBLOCKED';

    print(pass
        ? 'PASS  创作者主页相关接口契约正确（查人 / 作品 / 关注 / 屏蔽）'
        : 'FAIL  见上面的逐项输出');
  } finally {
    client.close(force: true);
  }
}
