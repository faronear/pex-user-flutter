/// 全局 Provider 定义（对应源项目 `wo.ss` 的拆解）。
///
/// - [brandProvider] / [localStoreProvider]：由 `main*` 在 `ProviderScope.overrides` 注入。
/// - 其余为派生 Provider。
library;

import 'dart:ui' show FlutterView;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../brands/brand_config.dart';
import '../api/api_client.dart';
import '../api/client_info.dart';
import '../responsive/device_info.dart';
import '../storage/local_store.dart';

/// 当前品牌（在 `ProviderScope.overrides` 中注入）。
final Provider<BrandConfig> brandProvider = Provider<BrandConfig>(
  (ref) => throw StateError('brandProvider 必须在 ProviderScope.overrides 中注入'),
);

/// 本地存储（在 `ProviderScope.overrides` 中注入）。
final Provider<LocalStore> localStoreProvider = Provider<LocalStore>(
  (ref) => throw StateError('localStoreProvider 必须在 ProviderScope.overrides 中注入'),
);

/// 启动时快照的设备信息（供 API `_clientInfo` 使用）。
/// 界面内的响应式判定请用 `DeviceInfo.of(context)`。
final Provider<DeviceInfo> deviceInfoProvider = Provider<DeviceInfo>((ref) {
  final FlutterView? view =
      WidgetsBinding.instance.platformDispatcher.implicitView;
  final Size size = view == null
      ? const Size(390, 844)
      : view.physicalSize / view.devicePixelRatio;
  return DeviceInfo.fromSize(size);
});

final Provider<ClientInfo> clientInfoProvider = Provider<ClientInfo>(
  (ref) => ClientInfo.forBrand(ref.watch(brandProvider), ref.watch(deviceInfoProvider)),
);

/// 后端地址（编译期 `--dart-define=API_BASE=` 可覆盖）。
final Provider<String> apiBaseUrlProvider =
    Provider<String>((ref) => ApiEndpoint.baseUrl);

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final LocalStore store = ref.watch(localStoreProvider);
  return ApiClient(
    clientInfo: ref.watch(clientInfoProvider),
    baseUrl: ref.watch(apiBaseUrlProvider),
    passtokenGetter: () => store.passtoken,
    // 对应源项目 callBase 内部自动持久化后端下发的凭据。
    onPasstoken: (String value) => store.setPasstoken(value),
    // 后端下发的客户端标识，存下来给支付门户用（源项目 `uni.getStorageSync('clid')`）。
    onClid: (String value) => store.setString(LocalStore.keyClid, value),
  );
});
