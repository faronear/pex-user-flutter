// ignore_for_file: avoid_print
/// 开发辅助脚本：端到端验证「我的空间」（账户域，对本地后端）。
///
/// 运行：`dart run tool/check_user_zone.dart [baseUrl]`
/// 流程：注册临时用户 → `update_nickname` → `update_aboutme` → `update_portrait`
/// → `first_touch` 复查三者已生效 → `logout_user`（放最后，会换发凭据）。
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
      '+86-135${DateTime.now().millisecondsSinceEpoch % 100000000}';

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
        <String, dynamic>{'commid': commid, 'passwordClient': hashStable('test1234$usid')},
        passtoken);
    passtoken = registered['_passtoken']?.toString() ?? passtoken;
    final String registerState = registered['_state']?.toString() ?? '';
    print('  register _state=$registerState  usid=$usid');
    if (!registerState.contains('SUCCESS')) {
      print('FAIL  注册失败');
      return;
    }

    final int stamp = DateTime.now().millisecondsSinceEpoch;
    final String nickname = 'zone$stamp';
    final String portrait = '/uploads/check-portrait-$stamp.png';

    print('--- 2) update_nickname');
    final Map<String, dynamic> nameData = await post(client, baseUrl, 'User',
        'update_nickname', <String, dynamic>{'nickname': nickname}, passtoken);
    print('  _state=${nameData['_state']}  nickname=${nameData['nickname']}');
    final bool nameOk =
        nameData['_state'] == 'SUCCESS' && nameData['nickname'] == nickname;

    print('--- 3) update_aboutme');
    final List<dynamic> aboutme = <dynamic>[
      <String, dynamic>{'text': '自我介绍契约校验 $stamp'},
    ];
    final Map<String, dynamic> aboutData = await post(client, baseUrl, 'User',
        'update_aboutme', <String, dynamic>{'aboutme': aboutme}, passtoken);
    print('  _state=${aboutData['_state']}  aboutme=${aboutData['aboutme']}');
    final bool aboutOk = aboutData['_state'] == 'SUCCESS';

    // 空段落应被前端过滤（`wo.tt.filter_story`），后端只接受数组。
    final Map<String, dynamic> badAbout = await post(client, baseUrl, 'User',
        'update_aboutme', <String, dynamic>{'aboutme': 'not-a-list'}, passtoken);
    print('  非数组入参 _state=${badAbout['_state']}（期望 FAIL_INVALID_ABOUTME）');
    final bool badAboutOk = badAbout['_state'] == 'FAIL_INVALID_ABOUTME';

    print('--- 4) update_portrait');
    final Map<String, dynamic> portraitData = await post(client, baseUrl, 'User',
        'update_portrait',
        <String, dynamic>{
          'User': <String, dynamic>{'portrait': portrait},
        },
        passtoken);
    print('  _state=${portraitData['_state']}');
    final bool portraitOk = portraitData['_state'] == 'SUCCESS';

    print('--- 5) first_touch 复查三处改动');
    final Map<String, dynamic> touch = await post(
        client, baseUrl, 'User', 'first_touch', <String, dynamic>{}, passtoken);
    final Map<String, dynamic> user =
        (touch['onlineUser'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    print('  _state=${touch['_state']}  _stateLogin=${touch['_stateLogin']}');
    print('  nickname=${user['nickname']}  portrait=${user['portrait']}');
    print('  aboutme=${jsonEncode(user['aboutme'])}');
    final bool savedOk = user['nickname'] == nickname &&
        user['portrait'] == portrait &&
        jsonEncode(user['aboutme']) == jsonEncode(aboutme);

    print('--- 6) logout_user');
    final Map<String, dynamic> out =
        await post(client, baseUrl, 'User', 'logout_user', <String, dynamic>{}, passtoken);
    print('  _state=${out['_state']}');
    final bool logoutOk = out['_state'] == 'SUCCESS';

    print(nameOk && aboutOk && badAboutOk && portraitOk && savedOk && logoutOk
        ? 'PASS  我的空间账户域契约（昵称 / 自我介绍 / 头像 / 退出）正确'
        : 'FAIL  账户域存在异常');
  } finally {
    client.close(force: true);
  }
}
