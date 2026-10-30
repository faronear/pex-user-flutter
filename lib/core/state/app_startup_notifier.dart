/// 应用启动流程，对应源项目 `App.vue` 的 `onLaunch`：
/// 连接后端（first_touch）→ 取回 envar 配置 → 判定自动登录状态。
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../i18n/i18n.dart';
import '../i18n/lands.dart';
import '../i18n/lang_text.dart';
import '../storage/local_store.dart';
import 'app_providers.dart';
import 'region_provider.dart';
import 'socket_provider.dart';

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
    this.uipl = '',
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

  /// 后端判定的用户所在国家代码（源项目 `wo.ss._uipl`）。
  final String uipl;

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
    String? uipl,
    String? lastError,
  }) =>
      AppStartupState(
        connecting: connecting ?? this.connecting,
        connected: connected ?? this.connected,
        attempt: attempt ?? this.attempt,
        autologging: autologging ?? this.autologging,
        envar: envar ?? this.envar,
        onlineUser: onlineUser ?? this.onlineUser,
        uipl: uipl ?? this.uipl,
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

    // 语言解析，对齐源项目 `App.vue:113` 的优先级，并按 Flutter 多平台
    // 能力插入设备系统语言回退：
    // ① 登录用户偏好 onlineUser.lang → ② 本地保存的 mylang
    // → ③ 设备系统语言（本地 App 为系统语言；Web 为浏览器语言，
    //    platformDispatcher.locales 两者都能拿到）
    // → ④ IP 国家映射 land2lang[userlandCode]（仅 CN→zhCN，其余→enUS；
    //    在系统语言不在支持范围内时兜底）
    // → ⑤ 默认 enUS。
    final String userlandCode = (result['_uipl']?.toString() ?? '').isNotEmpty
        ? result['_uipl'].toString()
        : store.getString(LocalStore.keyUserlandCode, 'EARTH');
    final String land2lang = userlandCode == 'CN' ? LangCode.zhCN : LangCode.enUS;
    final String systemLang = systemLanguageCode();
    final String savedLang = store.getString(LocalStore.keyMylang, '');
    final String? preferred = onlineUser['lang']?.toString();
    // 依次回退：账号偏好 → 本地保存 → 设备/浏览器语言 → 国家映射（恒非空）。
    final String resolved = (preferred != null && LangCode.isSupported(preferred))
        ? preferred
        : savedLang.isNotEmpty
            ? savedLang
            : systemLang.isNotEmpty
                ? systemLang
                : land2lang;
    if (LangCode.isSupported(resolved)) {
      ref.read(languageProvider.notifier).set(resolved);
      await store.setString(LocalStore.keyMylang, resolved);
    }

    final bool loginOk = bok(result['_stateLogin']?.toString());
    if (loginOk) {
      await store.setPasstoken(store.passtoken);
    } else {
      await store.clearPasstoken();
    }

    // 后端判定的用户所在国家（源项目 `wo.ss._uipl`）→ 更新默认电话区号国家。
    final String uipl = result['_uipl']?.toString() ?? '';
    if (uipl.isNotEmpty) {
      final LandItem? land = landByIso2(uipl);
      if (land != null) {
        ref.read(phoneLandProvider.notifier).set(land);
      }
    }

    // 缓存本次成功拉取的配置，供断线时兜底（轻量缓存层）。
    await store.setEnvarCache(envar);

    state = state.copyWith(
      connecting: false,
      connected: true,
      envar: envar,
      onlineUser: onlineUser,
      uipl: uipl,
      autologging: loginOk ? AutologgingState.success : AutologgingState.fail,
    );

    // 连接实时通道（源项目 `App.vue` 的 `wo.unisocket.initSocket({url: wo.ss.servUrl})`）。
    unawaited(ref.read(socketProvider.notifier).connect(
          envar['servUrl']?.toString() ?? '',
        ));
    if (loginOk) {
      ref.read(socketProvider.notifier).sendObject(<String, String>{
        'skevent': 'SOCKET_OWNER',
      });
    }
    return true;
  }

  /// 登录/注册成功后写入在线用户（对应源项目 `wo.ss.User.onlineUser = onlineUser`）。
  void setOnlineUser(Map<String, dynamic> user) {
    state = state.copyWith(
      onlineUser: user,
      autologging: AutologgingState.success,
    );
    // 登录成功 → 向实时通道认领本连接（源项目 `App.vue` 登录后的 `SOCKET_OWNER`）。
    ref.read(socketProvider.notifier).sendObject(<String, String>{
      'skevent': 'SOCKET_OWNER',
    });
  }

  /// 等待自动登录结束（对应源项目 `wo.tt.wait_autologin`）。
  Future<void> waitAutologin() async {
    while (!state.afterAutologging) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  /// 局部更新在线用户字段（如对话后刷新余额）。
  void mergeOnlineUser(Map<String, dynamic> patch) {
    state = state.copyWith(
      onlineUser: <String, dynamic>{...state.onlineUser, ...patch},
    );
  }

  /// 退出登录（对应源项目 `wo.tt.logout_local_account`）。
  void logout() {
    state = state.copyWith(
      onlineUser: <String, dynamic>{},
      autologging: AutologgingState.fail,
    );
  }

  /// 重启应用（对应源项目 `wo.store.commit('reset_all')` + `uni.reLaunch({url:'homePortal'})`）。
  /// 与源项目一致：**保留登录态**（本地 `_passtoken` 不动），只清空会话内数据，
  /// 并重新向后端拉取配置。各业务域的列表缓存由调用方一并重置（见 `menuUzone`）。
  Future<void> restart() async {
    state = const AppStartupState();
    await runOnce();
  }
}

final NotifierProvider<AppStartupNotifier, AppStartupState> appStartupProvider =
    NotifierProvider<AppStartupNotifier, AppStartupState>(AppStartupNotifier.new);

/// 设备系统语言 → 支持的语言代码；不支持或拿不到时返回空串（继续回退）。
///
/// 源项目基于 uniapp Web 技术无法可靠获取系统语言；Flutter 原生可取，
/// 故作为回退层插入。只认语言主码（`zh` / `en` / `de` / `ja`），
/// 地区变体（如 `zh-TW`）按主码粗分：zh 归 zhCN，en 归 enUS。
String systemLanguageCode() {
  final List<Locale> locales =
      WidgetsBinding.instance.platformDispatcher.locales;
  for (final Locale locale in locales) {
    switch (locale.languageCode) {
      case 'zh':
        return LangCode.zhCN;
      case 'en':
        return LangCode.enUS;
      case 'de':
        return LangCode.deDE;
      case 'ja':
        return LangCode.jaJP;
    }
  }
  return '';
}
