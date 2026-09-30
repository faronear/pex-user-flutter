/// 系统域接口封装（`apiWho: 'System'`）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_providers.dart';
import 'api_client.dart';

class SystemApi {
  const SystemApi(this._client);

  final ApiClient _client;

  static const String who = 'System';

  /// 联系客服（源项目 `umyContact.vue` 的 `to_send_message`）。
  /// 后端把留言 + 用户资料拼成邮件发给值班邮箱。
  Future<Map<String, dynamic>> contactCsr({
    required String message,
    required String email,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'contact_csr',
        apiWhat: <String, dynamic>{'message': message, 'email': email},
      );
}

final Provider<SystemApi> systemApiProvider =
    Provider<SystemApi>((ref) => SystemApi(ref.watch(apiClientProvider)));
