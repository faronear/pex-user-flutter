/// 账户域接口封装，对应源项目 `apiWho: 'User'` 中迁移期用到的部分。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_providers.dart';
import 'api_client.dart';

class UserApi {
  const UserApi(this._client);

  final ApiClient _client;

  static const String who = 'User';

  /// 提交举报（源项目 `partComplain.vue` 的 `to_send_complain`）。
  /// [reportTargetType] 如 `CREATION` / `USER`。
  Future<Map<String, dynamic>> reportComplain({
    required String reportTargetId,
    required String reportTargetType,
    required String reportReason,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'report_complain',
        apiWhat: <String, dynamic>{
          'reportTargetId': reportTargetId,
          'reportTargetType': reportTargetType,
          'reportReason': reportReason,
        },
      );
}

final Provider<UserApi> userApiProvider =
    Provider<UserApi>((ref) => UserApi(ref.watch(apiClientProvider)));
