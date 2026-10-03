/// 消息域接口封装，对应源项目 `apiWho: 'Mia'`。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_providers.dart';
import 'api_client.dart';

class MiaApi {
  const MiaApi(this._client);

  final ApiClient _client;

  static const String who = 'Mia';

  /// 我的消息列表（源项目 `list_my_mia`）。
  ///
  /// [beforeTime] 为向下翻页游标，取上一页最后一条的 `miaCreatedAt`。
  Future<Map<String, dynamic>> listMyMia({
    int takeLimit = 10,
    int? beforeTime,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'list_my_mia',
        apiWhat: <String, dynamic>{
          'takeLimit': takeLimit,
          'beforeTime': ?beforeTime,
        },
      );

  /// 消息详情（源项目 `get_mia_detail`）。
  ///
  /// 若是「我收到的未读消息」，后端会顺带标记为已读并返回 `miaUnread: 'UNREAD'`。
  Future<Map<String, dynamic>> getMiaDetail(String miaUuid) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_mia_detail',
        apiWhat: <String, dynamic>{'miaUuid': miaUuid},
      );

  /// 回复消息（源项目 `send_mia`）。
  ///
  /// [miaToUsid] 为原消息的**发送者**，[miaToMid] 为原消息的 `miaUuid`。
  Future<Map<String, dynamic>> sendMia({
    required String miaToUsid,
    required String miaToMid,
    required List<dynamic> miaStory,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'send_mia',
        apiWhat: <String, dynamic>{
          'miaToUsid': miaToUsid,
          'miaToMid': miaToMid,
          'miaStory': miaStory,
        },
      );
}

final Provider<MiaApi> miaApiProvider =
    Provider<MiaApi>((ref) => MiaApi(ref.watch(apiClientProvider)));
