/// 应用启动流程，对应源项目 `App.vue` 的 `onLaunch`：
/// 连接后端（first_touch）→ 取回 envar 配置 → 判定自动登录状态。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../i18n/i18n.dart';
import '../i18n/lang_text.dart';
import '../storage/local_store.dart';
import 'app_providers.dart';

/// 自动登录状态（对应源项目 `wo.ss.Ident.autologgingState`）。
enum AutologgingState { waiting, success, fail }

class AppStartupState {
  const AppStartupState({
    this.connecting = false,
    this.connected = false,
    this.attempt = 0,
    this.autologging = AutologgingState.waiting,
    this.envar = const <String, dynamic>{},
    this.onlineUser = const <String, dynamic>{},
    this.lastError,
  });

  final bool connecting;
  final bool connected;
  final int attempt;
  final AutologgingState autologging;

  /// 后端下发的配置（源项目 `first_touchResult.envarBase`）。
  final Map<String, dynamic> envar;

  /// 在线用户（源项目 `first_touchResult.onlineUser`）。
  final Map<String, dynamic> onlineUser;

  final String? lastError;

  bool get afterAutologging =>
      autologging == AutologgingState.success || autologging == AutologgingState.fail;

  AppStartupState copyWith({
    bool? connecting,
    bool? connected,
    int? attempt,
    AutologgingState? autologging,
    Map<String, dynamic>? envar,
    Map<String, dynamic>? onlineUser,
    String? lastError,
  }) =>
      AppStartupState(
        connecting: connecting ?? this.connecting,
        connected: connected ?? this.connected,
        attempt: attempt ?? this.attempt,
        autologging: autologging ?? this.autologging,
        envar: envar ?? this.envar,
        onlineUser: onlineUser ?? this.onlineUser,
        lastError: lastError ?? this.lastError,
      );
}

class AppStartupNotifier extends Notifier<AppStartupState> {
  @override
  AppStartupState build() => const AppStartupState();

  /// 连接后端并完成启动初始化。
  ///
  /// 失败时按源项目逻辑无限重试（间隔 1 秒）；本方法只执行一轮，
  /// 由调用方（或在 [run] 中）决定是否继续重试。
  Future<bool> runOnce() async {
    final ApiClient api = ref.read(apiClientProvider);
    final LocalStore store = ref.read(localStoreProvider);
    final String lang = ref.read(languageProvider);

    state = state.copyWith(
      connecting: true,
      attempt: state.attempt + 1,
      lastError: null,
    );

    final Map<String, dynamic> result = await api.callBase(
      apiWho: 'User',
      apiTodo: 'first_touch',
    );
    final String? stateCode = result['_state']?.toString();

    if (!bok(stateCode)) {
      state = state.copyWith(
        connecting: false,
        connected: false,
        lastError: result['_error']?.toString() ?? stateCode ?? 'unknown',
      );
      return false;
    }

    final Map<String, dynamic> envar =
        (result['envarBase'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final Map<String, dynamic> onlineUser =
        (result['onlineUser'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

    // 后端下发的语言优先，其次本地存储，最后回落当前语言。
    final String resolvedLang = onlineUser['lang']?.toString() ??
        store.getString(LocalStore.keyMylang, lang);
    if (LangCode.isSupported(resolvedLang)) {
      ref.read(languageProvider.notifier).set(resolvedLang);
      await store.setString(LocalStore.keyMylang, resolvedLang);
    }

    final bool loginOk = bok(result['_stateLogin']?.toString());
    if (loginOk) {
      await store.setPasstoken(store.passtoken);
    } else {
      await store.clearPasstoken();
    }

    state = state.copyWith(
      connecting: false,
      connected: true,
      envar: envar,
      onlineUser: onlineUser,
      autologging: loginOk ? AutologgingState.success : AutologgingState.fail,
    );
    return true;
  }
}

final NotifierProvider<AppStartupNotifier, AppStartupState> appStartupProvider =
    NotifierProvider<AppStartupNotifier, AppStartupState>(AppStartupNotifier.new);
