/// 页面基础布局，对应源项目 `parts/partWindowLayout.vue`：
/// `partWindow` + PC 顶栏 + 内容槽 + PC 页脚。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'part_window_footer.dart';
import 'part_window_header.dart';

class PartWindowLayout extends ConsumerWidget {
  const PartWindowLayout({
    super.key,
    required this.child,
    this.pageName = '',
  });

  final Widget child;
  final String pageName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: PexColors.bg,
      body: Column(
        children: <Widget>[
          PartWindowHeader(pageName: pageName),
          Expanded(child: child),
          PartWindowFooter(),
        ],
      ),
    );
  }
}
