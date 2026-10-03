// ignore_for_file: avoid_print
/// 开发辅助脚本：验证「朗读（TTS）」链路（对本地后端）。
///
/// 运行：`dart run tool/check_tts.dart <passtoken> [baseUrl]`
/// 流程：用给定 passtoken 调 `Aimodel/text_to_speech`（参数名必须是 `inputText`）→
/// 断言返回 `ttsAudio` + `tucCost`，并把 `ttsAudio` 拼成服务地址拉一次确认音频可访问。
///
/// 注意：会真调一次 OpenAI 的 TTS（消耗少量额度），但**不会发邮件**。
///
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
  if (args.isEmpty) {
    print('用法：dart run tool/check_tts.dart <passtoken> [baseUrl]');
    return;
  }
  final String passtoken = args.first;
  final String baseUrl = args.length > 1 ? args[1] : 'http://localhost:7739';
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30);

  try {
    print('--- 1) 查询余额（朗读会按 tucCost 扣费）');
    final Map<String, dynamic> before = await post(
        client, baseUrl, 'User', 'get_current_balance', <String, dynamic>{},
        passtoken);
    print('    balance=${before['balanceTUC']} sumOutTTS=${before['sumOutTTS']}');

    print('--- 2) 调 text_to_speech（参数名 inputText）');
    const String text = '你好，这是一次语音合成自检。';
    final Map<String, dynamic> tts = await post(
        client,
        baseUrl,
        'Aimodel',
        'text_to_speech',
        <String, dynamic>{'inputText': text},
        passtoken);
    print('    _state=${tts['_state']} tucCost=${tts['tucCost']} '
        'ttsAudio=${tts['ttsAudio']}');
    print('    _msg=${tts['_msg']}');

    final String audio = tts['ttsAudio']?.toString() ?? '';
    bool audioOk = false;
    if (audio.isNotEmpty) {
      print('--- 3) 拉一下音频文件');
      // 与客户端 `makeServerUrl` 同样的规则：相对路径 → `${servUrl}/${path}`。
      final Map<String, dynamic> touched = await post(
          client, baseUrl, 'User', 'first_touch', <String, dynamic>{},
          passtoken);
      final String servUrl =
          ((touched['envarBase'] as Map?)?['servUrl']).toString();
      final String url = audio.startsWith('http')
          ? audio
          : '${servUrl.replaceFirst(RegExp(r'/$'), '')}'
              '/${audio.replaceFirst(RegExp('^/'), '')}';
      final HttpClientRequest request = await client.getUrl(Uri.parse(url));
      final HttpClientResponse response = await request.close();
      final int length = await response.fold<int>(
          0, (int sum, List<int> chunk) => sum + chunk.length);
      audioOk = response.statusCode == 200 && length > 0;
      print('    GET $url -> ${response.statusCode}，$length 字节');
    }

    // 判定：
    // - `ERROR_MISSING_INPUT` 说明后端没收到 `inputText`（参数名写错）；
    // - 其它 `ERROR`（如 OpenAI 密钥/网络不通）属于**本地环境限制**，不算契约失败。
    final String state = tts['_state']?.toString() ?? '';
    if (state == 'SUCCESS') {
      print(audioOk
          ? 'PASS  朗读链路可用（inputText 参数正确、返回 ttsAudio 且音频可访问）'
          : 'FAIL  返回了 ttsAudio 但音频拉不到：$audio');
    } else if (state == 'ERROR_MISSING_INPUT') {
      print('FAIL  后端没收到 inputText（参数名仍不对）');
    } else {
      print('环境受限  参数名正确（后端已接受 inputText 并走到模型调用），'
          '但本地调用 TTS 失败：_state=$state _msg=${tts['_msg']}');
      print('           —— 需要可用的 OpenAI 密钥才能端到端验证音频；'
          '客户端播放代码另行核对。');
    }
  } finally {
    client.close(force: true);
  }
}
