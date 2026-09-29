// ignore_for_file: avoid_print
/// 开发辅助脚本：端到端验证账户域接口链路（对本地后端）。
///
/// 运行：`dart run tool/check_ident_flow.dart [baseUrl] [commid]`
/// 流程：identify_user → send_passcode → 校验 hash_stable → verify_passcode → register_new_user
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

String hashStable(String data) => sha256.convert(utf8.encode(data)).toString();

Future<Map<String, dynamic>> post(
  HttpClient client,
  String baseUrl,
  String apiTodo,
  Map<String, dynamic> what,
  String passtoken,
) async {
  final HttpClientRequest request =
      await client.postUrl(Uri.parse('$baseUrl/api/User/$apiTodo'));
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(<String, dynamic>{
    ...what,
    '_clientInfo': <String, dynamic>{
      'appkey': 'AKAGIDIN',
      'lang': 'enUS',
      'uniPlatform': 'app',
      'deviceType': 'phone',
      'osName': 'macos',
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
  final String commid = args.length > 1
      ? args[1]
      : '+86-139${DateTime.now().millisecondsSinceEpoch % 100000000}';

  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);
  String passtoken = '';

  try {
    print('--- 1) identify_user ($commid)');
    final Map<String, dynamic> ident = await post(
        client, baseUrl, 'identify_user', <String, dynamic>{'commid': commid}, passtoken);
    print('  _state=${ident['_state']}  usid=${ident['usid']}');
    passtoken = ident['_passtoken']?.toString() ?? passtoken;
    if (ident['_state'] != 'NEW_USER') {
      print('  非新用户，终止（如需可换 commid）');
      return;
    }
    final String usid = ident['usid'].toString();

    print('--- 2) send_passcode (REGISTER)');
    final Map<String, dynamic> sent = await post(
        client,
        baseUrl,
        'send_passcode',
        <String, dynamic>{'passcodeType': 'REGISTER', 'commid': commid},
        passtoken);
    print('  _state=${sent['_state']}  passcode=${sent['passcode']}');
    passtoken = sent['_passtoken']?.toString() ?? passtoken;

    print('--- 3) 校验本地 hash_stable 与后端 passcodeHash');
    final String passcode = sent['passcode'].toString();
    final String localHash = hashStable('$passcode$commid$usid');
    final String serverHash = sent['passcodeHash'].toString();
    print('  local =$localHash');
    print('  server=$serverHash');
    print('  一致? ${localHash == serverHash}');

    print('--- 4) verify_passcode');
    final Map<String, dynamic> verified = await post(
        client,
        baseUrl,
        'verify_passcode',
        <String, dynamic>{'passcode': passcode, 'inviterHaid': ''},
        passtoken);
    print('  _state=${verified['_state']}  verifyExpireAt=${verified['verifyExpireAt']}');
    passtoken = verified['_passtoken']?.toString() ?? passtoken;

    print('--- 5) register_new_user（密码 "test1234"）');
    final Map<String, dynamic> registered = await post(
        client,
        baseUrl,
        'register_new_user',
        <String, dynamic>{
          'commid': commid,
          'passwordClient': hashStable('test1234$usid'),
        },
        passtoken);
    print('  _state=${registered['_state']}');
    final Object? onlineUser = registered['onlineUser'];
    if (onlineUser is Map) {
      print('  onlineUser.usid=${onlineUser['usid']}  nickname=${onlineUser['nickname']}');
    }

    print('--- 6) 复登：identify_user → login_user');
    final Map<String, dynamic> reIdent = await post(
        client, baseUrl, 'identify_user', <String, dynamic>{'commid': commid}, passtoken);
    print('  identify _state=${reIdent['_state']}');
    passtoken = reIdent['_passtoken']?.toString() ?? passtoken;
    final Map<String, dynamic> logged = await post(
        client,
        baseUrl,
        'login_user',
        <String, dynamic>{
          'commid': commid,
          'passwordClient': hashStable('test1234$usid'),
        },
        passtoken);
    print('  login _state=${logged['_state']}');
  } finally {
    client.close(force: true);
  }
}
