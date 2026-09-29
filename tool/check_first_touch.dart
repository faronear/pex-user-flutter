/// 开发辅助脚本：验证本地后端 `first_touch` 的连通性与响应结构。
///
/// 运行：`dart run tool/checkFirstTouch.dart [baseUrl]`
/// 默认 baseUrl 为本地后端 `http://localhost:7739`。
library;

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final String baseUrl =
      args.isNotEmpty ? args.first : 'http://localhost:7739';
  final Uri uri = Uri.parse('$baseUrl/api/User/first_touch');

  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);
  try {
    final HttpClientRequest request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(<String, dynamic>{
      '_clientInfo': <String, dynamic>{
        'appkey': 'AKAGIDIN',
        'lang': 'enUS',
        'uniPlatform': 'app',
        'deviceType': 'phone',
        'osName': 'macos',
      },
      '_passtoken': '',
    }));
    final HttpClientResponse response = await request.close();
    final String body = await response.transform(utf8.decoder).join();
    stdout.writeln('POST $uri');
    stdout.writeln('HTTP ${response.statusCode}');

    final dynamic decoded = jsonDecode(body);
    if (decoded is! Map) {
      stdout.writeln('非 JSON 对象响应：${body.substring(0, body.length.clamp(0, 200))}');
      return;
    }
    stdout.writeln('_state       = ${decoded['_state']}');
    stdout.writeln('_stateLogin  = ${decoded['_stateLogin']}');
    final Object? envar = decoded['envarBase'];
    if (envar is Map) {
      final List<String> keys = envar.keys.map((Object? k) => '$k').toList();
      stdout.writeln('envarBase    = ${keys.length} 个键');
      stdout.writeln('  示例键: ${keys.take(25).join(', ')}');
      stdout.writeln('  webDomain=${envar['webDomain']}  idname=${envar['idname']}');
    } else {
      stdout.writeln('envarBase    = <无>');
    }
  } finally {
    client.close(force: true);
  }
}
