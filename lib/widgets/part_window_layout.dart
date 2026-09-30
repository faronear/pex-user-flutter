/// 页面基础布局，对应源项目 `parts/partWindowLayout.vue`：
/// `partWindow` + PC 顶栏 + 内容槽 + PC 页脚。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// 是否在手机端显示底部标签栏（源项目里只有注册为 tabBar 的页面才有）。
  final bool showTabBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: PexColors.bg,
      body: Column(
        children: <Widget>[
          PartWindowHeader(pageName: pageName),
          Expanded(child: child),
          if (showTabBar) PartTabBarPhone(currentPage: pageName),
          PartWindowFooter(),
        ],
      ),
    );
  }
}
