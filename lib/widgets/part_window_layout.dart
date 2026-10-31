/// 页面基础布局，对应源项目 `parts/partWindowLayout.vue`：
/// `partWindow` + PC 顶栏 + 内容槽 + PC 页脚。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive/device_info.dart';
import '../theme/app_theme.dart';
import 'part_tab_bar_phone.dart';
import 'part_window_footer.dart';
import 'part_window_header.dart';

class PartWindowLayout extends ConsumerWidget {
  const PartWindowLayout({
    super.key,
    required this.child,
    this.pageName = '',
    this.showTabBar = false,
  });

  final Widget child;
  final String pageName;

  /// 是否显示底部标签栏。null（默认）= 由布局形态决定：非 PC 布局
  /// （手机/平板/桌面原生）一律显示，作为全局导航；PC 布局不显示
  /// （有顶栏+页脚）。显式传 true/false 可覆盖（对应源项目里只有
  /// tabBar 页面才有标签栏的行为；PC 布局下源项目同样仅 tab 页才有）。
  final bool? showTabBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DeviceInfo device = DeviceInfo.of(context);
    // PC 布局（Web 桌面宽度）有顶栏+页脚做全局导航，不需要标签栏；
    // pad/phone/桌面原生布局一律显示标签栏，否则二级页面会被困住。
    final bool showBar = showTabBar ?? !device.inPc;
    return Scaffold(
      backgroundColor: PexColors.bg,
      body: Column(
        children: <Widget>[
          PartWindowHeader(pageName: pageName),
          Expanded(child: child),
          if (showBar) PartTabBarPhone(currentPage: pageName),
          PartWindowFooter(),
        ],
      ),
    );
  }
}
