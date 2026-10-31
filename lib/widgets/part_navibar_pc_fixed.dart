/// 二级页面固定导航栏（标题 + Back），对应源项目 `parts/partNavibarPcFixed.vue`。
///
/// 全形态渲染：PC（Web 宽窗口）与手机/平板/桌面原生都显示——源项目手机
/// 形态靠 uni-app 原生导航栏提供 Back，Flutter 版统一由本组件承担。
/// 组件名里的 Pc 是迁移历史遗留。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/lang_text.dart';
import 'part_navibar_pc.dart';

class PartNavibarPcFixed extends ConsumerWidget {
  const PartNavibarPcFixed({
    super.key,
    this.title,
    this.backToPage = '',
    this.leftText,
    this.leftIcon = '',
    this.leftPrefix = '',
    this.onLeftAction,
    this.rightText,
    this.rightIcon = '',
    this.rightPrefix = '',
    this.onRightAction,
    this.pageName = '',
  });

  final LangText? title;
  final String backToPage;
  final LangText? leftText;
  final String leftIcon;
  final String leftPrefix;
  final VoidCallback? onLeftAction;
  final LangText? rightText;
  final String rightIcon;
  final String rightPrefix;
  final VoidCallback? onRightAction;
  final String pageName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: PartNavibarPc(
            title: title,
            backToPage: backToPage,
            leftText: leftText,
            leftIcon: leftIcon,
            leftPrefix: leftPrefix,
            onLeftAction: onLeftAction,
            rightText: rightText,
            rightIcon: rightIcon,
            rightPrefix: rightPrefix,
            onRightAction: onRightAction,
            pageName: pageName,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
