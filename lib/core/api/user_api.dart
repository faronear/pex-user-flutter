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

  /// 更换头像（源项目 `menuUzone.vue` 的 `to_update_portrait`）。
  /// [portrait] 为上传后 `chooseUrl` 得到的地址。
  Future<Map<String, dynamic>> updatePortrait(String portrait) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'update_portrait',
        apiWhat: <String, dynamic>{
          'User': <String, dynamic>{'portrait': portrait},
        },
      );

  /// 修改昵称（源项目 `to_update_nickname`）。
  Future<Map<String, dynamic>> updateNickname(String nickname) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'update_nickname',
        apiWhat: <String, dynamic>{'nickname': nickname},
      );

  /// 更新自我介绍（源项目 `to_update_aboutme`；story 数组，已过滤空段落）。
  Future<Map<String, dynamic>> updateAboutme(List<dynamic> aboutme) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'update_aboutme',
        apiWhat: <String, dynamic>{'aboutme': aboutme},
      );

  /// 退出登录（源项目 `to_logout`；服务端注销 socket 并换发一个已登出的凭据）。
  Future<Map<String, dynamic>> logoutUser() =>
      _client.callBase(apiWho: who, apiTodo: 'logout_user');
}

final Provider<UserApi> userApiProvider =
    Provider<UserApi>((ref) => UserApi(ref.watch(apiClientProvider)));
