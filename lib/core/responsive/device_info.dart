/// 设备与布局判定，替代源项目 `App.data.js` 中的：
/// `inPc / inPad / inPhone / inWeb / inApp / inAppIos / inAppAndroid`。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum DeviceType { pc, pad, phone }

/// 布局断点（宽度，逻辑像素）。源项目按 `deviceType` 区分，这里以宽度近似。
class Breakpoints {
  const Breakpoints._();

  /// 桌面/网页布局起点。
  static const double pc = 900;

  /// 平板起点；小于此值为手机。
  static const double pad = 600;
}

class DeviceInfo {
  const DeviceInfo({
    required this.deviceType,
    required this.inWeb,
    required this.inApp,
    required this.osName,
  });

  final DeviceType deviceType;
  final bool inWeb;
  final bool inApp;

  /// `ios` / `android` / `macos` / `windows` / `web`
  final String osName;

  bool get inPc => deviceType == DeviceType.pc;
  bool get inPad => deviceType == DeviceType.pad;
  bool get inPhone => deviceType == DeviceType.phone;

  bool get inAppIos => inApp && osName == 'ios';
  bool get inAppAndroid => inApp && osName == 'android';

  /// 当前平台名（用于 `_clientInfo.osName`）。
  static String currentOsName() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  /// 依据平台与可用宽度判定设备类型（桌面平台恒为 pc）。
  static DeviceType deviceTypeOf(double width) {
    final bool isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);
    if (isDesktop) return DeviceType.pc;
    if (width >= Breakpoints.pc) return DeviceType.pc;
    if (width >= Breakpoints.pad) return DeviceType.pad;
    return DeviceType.phone;
  }

  static DeviceInfo fromSize(Size size) => DeviceInfo(
        deviceType: deviceTypeOf(size.width),
        inWeb: kIsWeb,
        inApp: !kIsWeb,
        osName: currentOsName(),
      );

  /// 在 Widget 树中取（基于当前 MediaQuery 尺寸）。
  static DeviceInfo of(BuildContext context) =>
      fromSize(MediaQuery.sizeOf(context));
}
