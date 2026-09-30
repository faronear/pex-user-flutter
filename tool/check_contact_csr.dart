// ignore_for_file: avoid_print
/// 开发辅助脚本：验证「联系客服」链路（`System/contact_csr`，对本地后端）。
///
/// 运行：`dart run tool/check_contact_csr.dart [baseUrl]`
///
/// ⚠️ **这会真的发出一封邮件**给后端 `wo.envar.oncallMessage.to`（值班邮箱）——
/// 别在循环里跑；每次执行只发一封。
library;

import 'dart:convert';
import 'dart:io';

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
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);
  try {
    // 注意：后端 `contact_csr` **不做入参校验**（空内容也会发信），
    // 所以这里只发一封正常的，不额外试探空值，免得给对方邮箱添垃圾。
    print('--- 留言（会真发一封邮件）');
    final int stamp = DateTime.now().millisecondsSinceEpoch;
    final Map<String, dynamic> sent = await post(
        client,
        baseUrl,
        'System',
        'contact_csr',
        <String, dynamic>{
          'message': '契约自检留言（check_contact_csr $stamp），非真实用户反馈。',
          'email': 'noreply@example.com',
        },
        '');
    print('  _state=${sent['_state']}  _msg=${sent['_msg']}');

    print(sent['_state'] == 'SUCCESS'
        ? 'PASS  contact_csr 契约正确（邮件已投递到值班邮箱）'
        : 'FAIL  contact_csr 未返回 SUCCESS');
  } finally {
    client.close(force: true);
  }
}
