/// TRYAPP 的中页（空白占位），对应源项目 `pages/midTryapp.vue`。
///
/// 源项目这里是「AI 对话 + 创作」两个大组件的容器；但 **TRYAPP 只是占位用的中性品牌**，
/// 老板决定（2026-10-03）：本页**不做业务**，只保持一张空白框架页——
/// 它代表一个与品牌无关的中立基础框架，等将来需要时装内容。
library;

import 'package:flutter/material.dart';

import '../core/router/app_routes.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_window_layout.dart';

class MidTryappPage extends StatelessWidget {
  const MidTryappPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PartWindowLayout(
      pageName: AppRoutes.midTryapp,
      child: Column(
        children: <Widget>[
          PartNavibarPcFixed(),
          Expanded(child: SizedBox.expand()),
        ],
      ),
    );
  }
}
