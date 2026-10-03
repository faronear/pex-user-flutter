/// 创作者域接口封装（`apiWho: 'User'` 里的创作者相关 apiTodo）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_providers.dart';
import 'api_client.dart';

class CreatorApi {
  const CreatorApi(this._client);

  final ApiClient _client;

  static const String who = 'User';

  /// 创作者列表（源项目 `partCreatorAll` 的 `to_get_creator_list`）。
  Future<Map<String, dynamic>> getCreatorList({int takeLimit = 12}) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_creator_list',
        apiWhat: <String, dynamic>{'takeLimit': takeLimit},
      );

  /// 单个创作者 + 其创作品（源项目 `showCreator` 用）。
  ///
  /// 后端按 `usid` / `haid` / `unid` 三者之一查人；`unid` 既可以是 usid（uuid）
  /// 也可以是 haid（短码，长度 > 5 且能反解），后端自己判断。
  Future<Map<String, dynamic>> getSingleCreator({
    String? usid,
    String? haid,
    String? unid,
    int takeLimit = 12,
    int skip = 0,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_single_creator',
        apiWhat: <String, dynamic>{
          'usid': ?usid,
          'haid': ?haid,
          'unid': ?unid,
          'takeLimit': takeLimit,
          'skip': skip,
        },
      );
}

final Provider<CreatorApi> creatorApiProvider =
    Provider<CreatorApi>((ref) => CreatorApi(ref.watch(apiClientProvider)));
