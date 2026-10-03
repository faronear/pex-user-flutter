// ignore_for_file: avoid_print
/// 开发辅助脚本：端到端验证「消息域」三个接口的契约（对本地后端）。
///
/// 运行：`dart run tool/check_mia.dart [baseUrl]`
/// 流程：注册 A / B 两个临时用户 → B 给 A 发一条消息 → A 的列表出现该条且为 UNREAD
/// → A 打开详情（后端标记已读 + 返回 miaUnread）→ 再拉详情应为 READ 且不再返回 miaUnread
/// → A 回复 B → B 的列表出现回复。
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
    final Map<String, String> a = await register(client, baseUrl, stamp.substring(0, 8));
    final Map<String, String> b = await register(client, baseUrl, stamp.substring(2, 10));

    print('--- 2) B 给 A 发一条消息');
    const String storyText = '契约自检消息 / contract check message';
    final Map<String, dynamic> sent = await post(
        client,
        baseUrl,
        'Mia',
        'send_mia',
        <String, dynamic>{
          'miaToUsid': a['usid'],
          'miaToMid': '',
          'miaStory': <Map<String, String>>[
            <String, String>{'text': storyText},
          ],
        },
        b['passtoken']!);
    print('    send_mia _state=${sent['_state']}');

    print('--- 3) A 的消息列表里应有该条，且为 UNREAD');
    final Map<String, dynamic> listed = await post(client, baseUrl, 'Mia',
        'list_my_mia', <String, dynamic>{'takeLimit': 10}, a['passtoken']!);
    final List<Map<String, dynamic>> miaList = asList(listed['miaList']);
    final String miaUuid = miaList.isEmpty
        ? ''
        : miaList.first['miaUuid']?.toString() ?? '';
    print('    list_my_mia _state=${listed['_state']} count=${miaList.length} '
        'total=${listed['countMiaTotal']}');
    print('    第一条：from=${miaList.isEmpty ? '' : miaList.first['from_nickname']} '
        'title=${miaList.isEmpty ? '' : miaList.first['miaTitle']} '
        'state=${miaList.isEmpty ? '' : miaList.first['miaToState']}');

    print('--- 4) A 打开详情：后端应标记已读并返回 miaUnread');
    final Map<String, dynamic> detail1 = await post(client, baseUrl, 'Mia',
        'get_mia_detail', <String, dynamic>{'miaUuid': miaUuid},
        a['passtoken']!);
    print('    get_mia_detail(1) _state=${detail1['_state']} '
        'miaUnread=${detail1['miaUnread']} '
        'state=${(detail1['mia'] as Map?)?['miaToState']}');

    final Map<String, dynamic> detail2 = await post(client, baseUrl, 'Mia',
        'get_mia_detail', <String, dynamic>{'miaUuid': miaUuid},
        a['passtoken']!);
    print('    get_mia_detail(2) _state=${detail2['_state']} '
        'miaUnread=${detail2['miaUnread']} '
        'state=${(detail2['mia'] as Map?)?['miaToState']}');

    print('--- 5) A 回复 B，B 的列表里应出现该回复');
    final Map<String, dynamic> replied = await post(
        client,
        baseUrl,
        'Mia',
        'send_mia',
        <String, dynamic>{
          'miaToUsid': b['usid'],
          'miaToMid': miaUuid,
          'miaStory': <Map<String, String>>[
            <String, String>{'text': '契约自检回复 / contract reply'},
          ],
        },
        a['passtoken']!);
    print('    send_mia(回复) _state=${replied['_state']}');
    final Map<String, dynamic> listedB = await post(client, baseUrl, 'Mia',
        'list_my_mia', <String, dynamic>{'takeLimit': 10}, b['passtoken']!);
    final List<Map<String, dynamic>> miaListB = asList(listedB['miaList']);
    print('    B.list_my_mia count=${miaListB.length}');

    print('--- 6) 空 story 应被后端拒绝（INPUT_MALFORMED）');
    final Map<String, dynamic> bad = await post(
        client,
        baseUrl,
        'Mia',
        'send_mia',
        <String, dynamic>{
          'miaToUsid': b['usid'],
          'miaToMid': '',
          'miaStory': <dynamic>[],
        },
        a['passtoken']!);
    print('    send_mia(空) _state=${bad['_state']}');

    final bool pass = sent['_state'] == 'SUCCESS' &&
        miaList.length == 1 &&
        miaList.first['miaToState']?.toString() == 'UNREAD' &&
        (miaList.first['miaTitle']?.toString() ?? '').contains(storyText) &&
        detail1['_state'] == 'SUCCESS' &&
        detail1['miaUnread'] != null &&
        (detail1['mia'] as Map?)?['miaToState'] == 'READ' &&
        detail2['miaUnread'] == null &&
        replied['_state'] == 'SUCCESS' &&
        miaListB.length == 1 &&
        bad['_state'] == 'INPUT_MALFORMED';

    print(pass
        ? 'PASS  消息域三个接口契约正确（发送 / 列表 / 详情标记已读）'
        : 'FAIL  见上面的逐项输出');
  } finally {
    client.close(force: true);
  }
}
