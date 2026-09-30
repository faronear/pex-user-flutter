// ignore_for_file: avoid_print
/// 开发辅助脚本：端到端验证「账号安全闭环」（对本地后端）。
///
/// 运行：`dart run tool/check_account.dart [baseUrl]`
/// 流程：注册临时用户 → 改密码（错/对）→ 用新密码复登 → 验证当前账号（CHECK_OLD）
/// → 设置新账号（CHECK_NEW，改邮箱）→ 复查 → 销毁账号（错/对）。
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
  const String oldPassword = 'test1234';
  const String newPassword = 'test5678';
  final String commid =
      '+86-138${DateTime.now().millisecondsSinceEpoch % 100000000}';
  final String newEmail = 'zone${DateTime.now().millisecondsSinceEpoch}@example.com';

  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);
  String passtoken = '';

  try {
    print('--- 1) 注册临时用户 $commid（密码 $oldPassword）');
    final Map<String, dynamic> ident = await post(
        client, baseUrl, 'User', 'identify_user', <String, dynamic>{'commid': commid}, '');
    passtoken = ident['_passtoken']?.toString() ?? '';
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
        <String, dynamic>{'commid': commid, 'passwordClient': hashStable('$oldPassword$usid')},
        passtoken);
    passtoken = registered['_passtoken']?.toString() ?? passtoken;
    print('  register _state=${registered['_state']}  usid=$usid');
    if (!(registered['_state']?.toString() ?? '').contains('SUCCESS')) {
      print('FAIL  注册失败');
      return;
    }
    final Map<String, dynamic> me = await post(
        client, baseUrl, 'User', 'first_touch', <String, dynamic>{}, passtoken);
    print('  phone=${(me['onlineUser'] as Map?)?['phone']}');

    print('--- 2) changePassword（错误的原密码，应被拒绝）');
    final Map<String, dynamic> badOld = await post(
        client,
        baseUrl,
        'User',
        'changePassword',
        <String, dynamic>{
          'passwordClient': hashStable('wrongpass$usid'),
          'passwordNewClient': hashStable('$newPassword$usid'),
        },
        passtoken);
    print('  _state=${badOld['_state']}');
    final bool badOldOk = badOld['_state'] == 'PASSWORD_UNMATCH';

    print('--- 3) changePassword（正确）');
    final Map<String, dynamic> changed = await post(
        client,
        baseUrl,
        'User',
        'changePassword',
        <String, dynamic>{
          'passwordClient': hashStable('$oldPassword$usid'),
          'passwordNewClient': hashStable('$newPassword$usid'),
        },
        passtoken);
    print('  _state=${changed['_state']}');
    final bool changeOk = changed['_state'] == 'SUCCESS';
    passtoken = changed['_passtoken']?.toString() ?? passtoken;

    print('--- 4) 用新密码复登（验证改动真的生效）');
    final Map<String, dynamic> relogin = await post(
        client, baseUrl, 'User', 'identify_user', <String, dynamic>{'commid': commid}, passtoken);
    passtoken = relogin['_passtoken']?.toString() ?? passtoken;
    final Map<String, dynamic> logged = await post(
        client, baseUrl, 'User', 'login_user',
        <String, dynamic>{'commid': commid, 'passwordClient': hashStable('$newPassword$usid')},
        passtoken);
    passtoken = logged['_passtoken']?.toString() ?? passtoken;
    print('  identify=${relogin['_state']}  login=${logged['_state']}');
    final bool reloginOk =
        (relogin['_state']?.toString() ?? '').contains('OLD_USER') ||
            logged['_state'] == 'LOGIN_SUCCESS';
    final bool loginOk = logged['_state'] == 'LOGIN_SUCCESS';

    print('--- 5) 验证当前账号（CHECK_OLD → verify_passcode）');
    final Map<String, dynamic> oldSent = await post(
        client, baseUrl, 'User', 'send_passcode',
        <String, dynamic>{'passcodeType': 'CHECK_OLD', 'commid': commid}, passtoken);
    passtoken = oldSent['_passtoken']?.toString() ?? passtoken;
    final String oldCode = oldSent['passcode']?.toString() ?? '';
    final String oldHash = oldSent['passcodeHash']?.toString() ?? '';
    print('  send _state=${oldSent['_state']}  hash_matches_local='
        '${oldHash == hashStable('$oldCode$commid$usid')}');
    final Map<String, dynamic> oldVerified = await post(
        client, baseUrl, 'User', 'verify_passcode',
        <String, dynamic>{'passcode': oldCode}, passtoken);
    passtoken = oldVerified['_passtoken']?.toString() ?? passtoken;
    print('  verify _state=${oldVerified['_state']}  '
        'verifyExpireAt=${oldVerified['verifyExpireAt']}');
    final bool checkOldOk = oldSent['_state'] == 'PASSCODE_SENT' &&
        oldHash == hashStable('$oldCode$commid$usid') &&
        oldVerified['_state'] == 'VERIFY_SUCCESS';

    print('--- 6) 设置新账号（CHECK_NEW，改邮箱为 $newEmail）');
    final Map<String, dynamic> newSent = await post(
        client, baseUrl, 'User', 'send_passcode',
        <String, dynamic>{'passcodeType': 'CHECK_NEW', 'commid': newEmail}, passtoken);
    passtoken = newSent['_passtoken']?.toString() ?? passtoken;
    final String newCode = newSent['passcode']?.toString() ?? '';
    print('  send _state=${newSent['_state']}');
    final Map<String, dynamic> newVerified = await post(
        client, baseUrl, 'User', 'verify_passcode',
        <String, dynamic>{'passcode': newCode}, passtoken);
    passtoken = newVerified['_passtoken']?.toString() ?? passtoken;
    print('  verify _state=${newVerified['_state']}');
    final Map<String, dynamic> after = await post(
        client, baseUrl, 'User', 'first_touch', <String, dynamic>{}, passtoken);
    final String emailNow =
        ((after['onlineUser'] as Map?)?['email'] ?? '').toString();
    print('  email_now=$emailNow');
    final bool checkNewOk = newSent['_state'] == 'PASSCODE_SENT' &&
        newVerified['_state'] == 'VERIFY_SUCCESS' &&
        emailNow == newEmail;

    print('--- 7) 销毁账号（错误密码应被拒绝）');
    final Map<String, dynamic> badTerminate = await post(
        client, baseUrl, 'User', 'terminate_account',
        <String, dynamic>{'passwordClient': hashStable('wrongpass$usid')}, passtoken);
    print('  _state=${badTerminate['_state']}');
    final bool badTerminateOk = badTerminate['_state'] == 'PASSWORD_UNMATCH';

    print('--- 8) 销毁账号（正确密码）');
    final Map<String, dynamic> terminated = await post(
        client, baseUrl, 'User', 'terminate_account',
        <String, dynamic>{'passwordClient': hashStable('$newPassword$usid')}, passtoken);
    print('  _state=${terminated['_state']}');
    final bool terminateOk = terminated['_state'] == 'SUCCESS';

    print(badOldOk && changeOk && reloginOk && loginOk && checkOldOk &&
            checkNewOk && badTerminateOk && terminateOk
        ? 'PASS  账号闭环契约（改密码 / 复登 / 验证当前账号 / 设置新账号 / 销毁账号）正确'
        : 'FAIL  账号闭环存在异常');
  } finally {
    client.close(force: true);
  }
}
