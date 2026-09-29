/// AI 相关接口封装，对应源项目 `apiWho: 'Aimodel'` 的各个 apiTodo。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_providers.dart';
import 'api_client.dart';

class AimodelApi {
  const AimodelApi(this._client);

  final ApiClient _client;

  static const String who = 'Aimodel';

  /// 对话回复（长请求，源项目为同步等待 + 前端「思考中」倒计时）。
  Future<Map<String, dynamic>> replyChallenge({
    required String aicode,
    required Object prompt,
    required List<Map<String, dynamic>> history,
    required int imgNum,
    required bool autoTTS,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'reply_challenge',
        apiWhat: <String, dynamic>{
          'aicode': aicode,
          'prompt': prompt,
          'history': history,
          'imgNum': imgNum,
          'autoTTS': autoTTS,
        },
        timeout: const Duration(seconds: 300),
      );

  Future<Map<String, dynamic>> getAipp(String aicode) => _client.callBase(
        apiWho: who,
        apiTodo: 'get_aipp',
        apiWhat: <String, dynamic>{'aicode': aicode},
      );

  Future<Map<String, dynamic>> getChatHistory({
    required String aicode,
    int skip = 0,
    int takeLimit = 10,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_chat_history',
        apiWhat: <String, dynamic>{'aicode': aicode, 'skip': skip, 'takeLimit': takeLimit},
      );

  Future<Map<String, dynamic>> resetThread(String aicode) => _client.callBase(
        apiWho: who,
        apiTodo: 'reset_thread',
        apiWhat: <String, dynamic>{'aicode': aicode},
      );

  Future<Map<String, dynamic>> deleteChatItem(Map<String, dynamic> item) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'delete_chat_item',
        apiWhat: <String, dynamic>{'chatItem': item},
      );

  Future<Map<String, dynamic>> textToSpeech(String text) => _client.callBase(
        apiWho: who,
        apiTodo: 'text_to_speech',
        apiWhat: <String, dynamic>{'text': text},
        timeout: const Duration(seconds: 120),
      );

  /// 参数名为 `takeLimit`（与源项目一致）。
  Future<Map<String, dynamic>> getAllAippList({int skip = 0, int takeLimit = 10}) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_all_aippList',
        apiWhat: <String, dynamic>{'skip': skip, 'takeLimit': takeLimit},
      );

  Future<Map<String, dynamic>> getMyAippList({int skip = 0, int takeLimit = 10}) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_my_aippList',
        apiWhat: <String, dynamic>{'skip': skip, 'takeLimit': takeLimit},
      );

  Future<Map<String, dynamic>> pickAipp(String aicode) => _client.callBase(
        apiWho: who,
        apiTodo: 'pick_aipp',
        apiWhat: <String, dynamic>{'aicode': aicode},
      );

  Future<Map<String, dynamic>> cancelPickAipp(String aicode) => _client.callBase(
        apiWho: who,
        apiTodo: 'cancel_pick_aipp',
        apiWhat: <String, dynamic>{'aicode': aicode},
      );

  Future<Map<String, dynamic>> deleteAipp(String aicode) => _client.callBase(
        apiWho: who,
        apiTodo: 'delete_aipp',
        apiWhat: <String, dynamic>{'aicode': aicode},
      );
}

final Provider<AimodelApi> aimodelApiProvider =
    Provider<AimodelApi>((ref) => AimodelApi(ref.watch(apiClientProvider)));
