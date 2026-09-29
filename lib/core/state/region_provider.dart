/// 地区状态，对应源项目 `wo.ss.i18n.{userlandCode, weblandCode, phonelandNow}`。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/lands.dart';
import 'app_startup_notifier.dart';

/// 当前选择的电话区号国家（源项目 `phonelandNow`），用户可在注册页切换。
class PhoneLandNotifier extends Notifier<LandItem> {
  @override
  LandItem build() {
    // 默认美国（源项目 landSet.US）；启动完成后由外部按 `_uipl` 覆盖。
    return landByIso2('US') ?? kLands.first;
  }

  void set(LandItem land) => state = land;
}

final NotifierProvider<PhoneLandNotifier, LandItem> phoneLandProvider =
    NotifierProvider<PhoneLandNotifier, LandItem>(PhoneLandNotifier.new);

/// 用户 IP 所在国家/大洲（源项目 `userlandCode`）。
final Provider<String> userlandCodeProvider = Provider<String>((ref) {
  final String uipl = ref.watch(appStartupProvider).uipl;
  if (uipl.isNotEmpty) return uipl;
  return ref.watch(appStartupProvider).envar['userlandCode']?.toString() ?? 'EARTH';
});

/// 前端服务器所在国家（源项目 `weblandCode`）。
final Provider<String> weblandCodeProvider = Provider<String>((ref) {
  final String raw =
      ref.watch(appStartupProvider).envar['weblandCode']?.toString() ?? 'EARTH';
  return raw;
});
