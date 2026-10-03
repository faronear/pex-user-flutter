// ignore_for_file: avoid_print
/// 开发辅助脚本：验证「实时通道」（WebSocket）能连通并按 skevent 收到推送。
///
/// 运行：`dart run tool/check_socket.dart [baseUrl]`
/// 流程：注册 A / B → 以 A 的身份连 ws 并认领连接（`SOCKET_OWNER_RECONNECT`）
/// → B 给 A 发消息（后端会 `sendToOne({skevent:'MIA_SENT'})`）→ 断言 A 的 socket 收到该事件。
///
/// 之所以用 `send_mia` 来验证：它是**客户端可触发且不产生副作用**（不发邮件）的推送源；
/// 充值推送 `RECHARGE_SUCCESS` 只能由支付门户的 `System/deposit_callback`（sysapi）触发，
/// 且会真发邮件给值班邮箱，因此不在自检里跑。
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  final String wsUrl = baseUrl.replaceFirst(RegExp('^http'), 'ws');
  final String stamp = '${DateTime.now().millisecondsSinceEpoch}';
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  WebSocketChannel? channel;
  try {
    print('--- 1) 注册 A / B 两个临时用户');
    final Map<String, String> a =
        await register(client, baseUrl, stamp.substring(0, 8));
    final Map<String, String> b =
        await register(client, baseUrl, stamp.substring(2, 10));
    print('    A=${a['usid']}  B=${b['usid']}');

    print('--- 2) 以 A 的身份连接 $wsUrl 并认领连接');
    final List<Map<String, dynamic>> events = <Map<String, dynamic>>[];
    channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    await channel.ready;
    print('    已连接');
    channel.sink.add(jsonEncode(<String, dynamic>{
      'skevent': 'SOCKET_OWNER_RECONNECT',
      '_passtoken': a['passtoken'],
    }));
    channel.stream.listen((dynamic data) {
      if (data is! String) return;
      final dynamic decoded = jsonDecode(data);
      if (decoded is Map) {
        events.add(decoded.cast<String, dynamic>());
        print('    收到事件：skevent=${decoded['skevent']}');
      }
    }, onDone: () => print('    连接已关闭'), onError: (Object e) => print('    连接错误：$e'));

    print('--- 3) 心跳 PING（应无异常）');
    channel.sink.add(jsonEncode(<String, dynamic>{'skevent': 'PING'}));
    await Future<void>.delayed(const Duration(milliseconds: 300));

    print('--- 4) B 给 A 发一条消息，等待 A 的推送');
    final Map<String, dynamic> sent = await post(
        client,
        baseUrl,
        'Mia',
        'send_mia',
        <String, dynamic>{
          'miaToUsid': a['usid'],
          'miaToMid': '',
          'miaStory': <Map<String, String>>[
            <String, String>{'text': '推送自检 / socket check'},
          ],
        },
        b['passtoken']!);
    print('    send_mia _state=${sent['_state']}');

    // 最多等 8 秒
    for (int i = 0; i < 80 && events.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final Map<String, dynamic>? push = events.isEmpty ? null : events.first;
    final bool gotPush = push != null &&
        push['skevent'] == 'MIA_SENT' &&
        push['usid'] == a['usid'];

    print(gotPush
        ? 'PASS  实时通道可用（认领连接后能收到 skevent 推送）'
        : 'FAIL  未收到预期推送，events=$events');
  } finally {
    await channel?.sink.close();
    client.close(force: true);
  }
}
