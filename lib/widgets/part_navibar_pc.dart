/// PC 二级导航栏，对应源项目 `parts/partNavibarPc.vue`（仅 PC 显示）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/appmeta/page_meta.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import 'part_texts.dart';

class PartNavibarPc extends ConsumerWidget {
  const PartNavibarPc({
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
    this.canGoBack = true,
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

  /// 当前页面名（用于取 `i18nPageTitle`）。
  final String pageName;
  final bool canGoBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final LangText? effectiveTitle =
        title ?? pageMetaOf(pageName)?.i18nPageTitle;
    final bool canBack = canGoBack && context.canPop();
    return SizedBox(
      height: 50,
      child: Stack(
        children: <Widget>[
          Center(
            child: Text(
              effectiveTitle == null ? '' : ll(lang, effectiveTitle),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (canBack)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onLeftAction ??
                    () {
                      if (context.canPop()) {
                        context.pop();
                      } else if (backToPage.isNotEmpty) {
                        context.go('/$backToPage');
                      }
                    },
                icon: leftPrefix == 'icont'
                    ? PexIcon.icont(leftIcon.isEmpty ? 'icont-back' : leftIcon, size: 18)
                    : PexIcon.uni(leftIcon.isEmpty ? 'back' : leftIcon, size: 18),
                label: Text(ll(lang, leftText ?? PartTexts.back)),
              ),
            ),
          if (onRightAction != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRightAction,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(ll(lang, rightText ?? const LangText.from(''))),
                    if (rightIcon.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: PexIcon.uni(rightIcon, size: 18),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
