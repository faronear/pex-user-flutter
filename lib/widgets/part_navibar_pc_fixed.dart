/// PC 固定导航栏容器，对应源项目 `parts/partNavibarPcFixed.vue`（仅 PC 显示）。
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
