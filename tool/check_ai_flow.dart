// ignore_for_file: avoid_print
/// 开发辅助脚本：端到端验证 AI 域接口链路（对本地后端）。
///
/// 运行：`dart run tool/check_ai_flow.dart [baseUrl] [aicode]`
/// 流程：注册/登录 → get_aipp → get_chat_history → reply_challenge → reset_thread
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

String hashStable(String data) => sha256.convert(utf8.encode(data)).toString();

class Client {
  Client(this.baseUrl);

  final String baseUrl;
  final HttpClient http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);
  String passtoken = '';

  Future<Map<String, dynamic>> post(
    String apiWho,
    String apiTodo,
    Map<String, dynamic> what, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final HttpClientRequest request =
        await http.postUrl(Uri.parse('$baseUrl/api/$apiWho/$apiTodo')).timeout(timeout);
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
    final HttpClientResponse response = await request.close().timeout(timeout);
    final String body = await response.transform(utf8.decoder).join().timeout(timeout);
    final dynamic decoded = jsonDecode(body);
    final Map<String, dynamic> result = decoded is Map
        ? decoded.map((dynamic k, dynamic v) => MapEntry(k.toString(), v))
        : <String, dynamic>{'_state': 'BAD_RESPONSE'};
    if (result['_passtoken'] != null) passtoken = result['_passtoken'].toString();
    return result;
  }

  void close() => http.close(force: true);
}

/// 注册一个可用账号并返回 (commid, usid)。
Future<List<String>> ensureAccount(Client c) async {
  final String commid =
      '+86-138${DateTime.now().millisecondsSinceEpoch % 100000000}';
  final Map<String, dynamic> ident = await c.post(
      'User', 'identify_user', <String, dynamic>{'commid': commid});
  var state = ident['_state'];
  print('1) identify_user -> $state');
  var usid = ident['usid'].toString();

  if (state == 'NEW_USER') {
    final Map<String, dynamic> sent = await c.post(
        'User',
        'send_passcode',
        <String, dynamic>{'passcodeType': 'REGISTER', 'commid': commid});
    print('2) send_passcode -> ${sent['_state']} (dev passcode=${sent['passcode']})');
    final Map<String, dynamic> verified = await c.post(
        'User',
        'verify_passcode',
        <String, dynamic>{'passcode': sent['passcode'], 'inviterHaid': ''});
    print('3) verify_passcode -> ${verified['_state']}');
    final Map<String, dynamic> registered = await c.post(
        'User',
        'register_new_user',
        <String, dynamic>{
          'commid': commid,
          'passwordClient': hashStable('test1234$usid'),
        });
    print('4) register_new_user -> ${registered['_state']}');
  } else {
    final Map<String, dynamic> logged = await c.post(
        'User',
        'login_user',
        <String, dynamic>{
          'commid': commid,
          'passwordClient': hashStable('test1234$usid'),
        });
    print('2) login_user -> ${logged['_state']}');
  }
  return <String>[commid, usid];
}

Future<void> main(List<String> args) async {
  final String baseUrl = args.isNotEmpty ? args.first : 'http://localhost:7739';
  final String aicode = args.length > 1 ? args[1] : 'deepseekr1';

  final Client c = Client(baseUrl);
  try {
    await ensureAccount(c);

    print('5) get_aipp(asst_By0qXqqOufjbJlkOlLM3omi5)');
    final Map<String, dynamic> aipp = await c.post(
        'Aimodel',
        'get_aipp',
        <String, dynamic>{'aicode': 'asst_By0qXqqOufjbJlkOlLM3omi5'});
    print('   -> ${aipp['_state']}  ainame=${aipp['aipp']?['ainame']}');

    print('6) get_aippList');
    final Map<String, dynamic> shared = await c.post(
        'Aimodel', 'get_all_aippList', <String, dynamic>{'skip': 0, 'takeLimit': 10});
    final List<dynamic>? sharedList = shared['aippList'] as List<dynamic>?;
    print('   -> ${shared['_state']}  共享 Aibot ${sharedList?.length ?? 0} 个');
    final Map<String, dynamic> mine = await c.post(
        'Aimodel', 'get_my_aippList', <String, dynamic>{'skip': 0, 'takeLimit': 10});
    final List<dynamic>? myList = mine['aippList'] as List<dynamic>?;
    print('   -> ${mine['_state']}  我的 Aibot ${myList?.length ?? 0} 个');

    print('7) get_chat_history($aicode)');
    final Map<String, dynamic> history = await c.post(
        'Aimodel',
        'get_chat_history',
        <String, dynamic>{'aicode': aicode, 'skip': 0, 'takeLimit': 10});
    print('   -> ${history['_state']}  history=${(history['chatHistory'] as List?)?.length ?? 0}');

    print('8) reply_challenge($aicode) 「Say hi in 3 words」');
    final Map<String, dynamic> reply = await c.post(
      'Aimodel',
      'reply_challenge',
      <String, dynamic>{
        'aicode': aicode,
        'prompt': 'Say hi in 3 words',
        'history': <Map<String, dynamic>>[],
        'imgNum': 1,
        'autoTTS': false,
      },
      timeout: const Duration(seconds: 180),
    );
    print('   -> _state=${reply['_state']}');
    if (reply['_msg'] != null) print('   _msg=${reply['_msg']}');
    final Object? aiReply = reply['aiReply'];
    if (aiReply is List && aiReply.isNotEmpty) {
      print('   aiReply[0].text=${(aiReply.first as Map)['text']}');
    }
    print('   tucCost=${reply['tucCost']} newBalance=${reply['newBalance']} '
        'timeCost=${reply['timeCost']} promptUuid=${reply['promptUuid']}');
  } on SocketException catch (error) {
    print('网络错误：$error');
  } finally {
    c.close();
  }
}
