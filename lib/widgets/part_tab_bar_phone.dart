/// 手机端底部标签栏，对应源项目 `pages.json` 的 `tabBar`（uni-app 原生标签栏）。
///
/// 结构：两侧标签组 + 中间凸起的「创造/对话」按钮（源项目 `tabBar.midButton`）。
/// 源项目里标签栏由 uni-app 原生渲染、且**只在注册为 tabBar 的页面上出现**，
/// 因此这里由各 tab 页面通过 `PartWindowLayout(showTabBar: true)` 显式开启
/// （`midBabely`、`showCreation` 等普通页面不显示）。
///
/// 配色取自源项目：底色 `#303133`、未选中 `#c0c0c0`、选中 `#ffffff`、字号 12px、图标 26px。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../brands/brand_config.dart';
import '../core/appmeta/tab_bar.dart';
import '../core/i18n/i18n.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/state/app_providers.dart';
import '../theme/app_theme.dart';

const Color _kUnselected = Color(0xFFC0C0C0);

const double _kBarHeight = 50;

/// 中间按钮凸起所需的上方留白：让凸出的 logo 落在留白里，而不是压住上方可滚动的内容。
const double _kMidRise = 12;

class PartTabBarPhone extends ConsumerWidget {
  const PartTabBarPhone({super.key, required this.currentPage});

  /// 当前页名（用于高亮）。
  final String currentPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DeviceInfo device = DeviceInfo.of(context);
    if (device.inPc) return const SizedBox.shrink();

    final BrandConfig brand = ref.watch(brandProvider);
    final List<TabItem> tabs = brand.tabItems;
    if (tabs.isEmpty) return const SizedBox.shrink();

    // 中间按钮占第 `length ~/ 2` 个位置（uni-app 的 midButton 规则）：
    // 3 个标签 → 1 左 2 右；2 个标签 → 1 左 1 右；4 个标签 → 2 左 2 右。
    final int midIndex = tabs.length ~/ 2;
    final List<TabItem> left = tabs.take(midIndex).toList();
    final List<TabItem> right = tabs.skip(midIndex).toList();

    return Material(
      color: PexColors.grey3,
      child: SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: _kMidRise),
              child: Row(
                children: <Widget>[
                  Expanded(child: _group(context, left)),
                  const SizedBox(width: 80), // 给中间按钮留位
                  Expanded(child: _group(context, right)),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: _kBarHeight + _kMidRise,
                child: _MidButton(brand: brand),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(BuildContext context, List<TabItem> tabs) {
    return Row(
      children: <Widget>[
        for (final TabItem tab in tabs)
          Expanded(
            child: _TabView(tab: tab, active: tab.pageName == currentPage),
          ),
      ],
    );
  }
}

class _TabView extends ConsumerWidget {
  const _TabView({required this.tab, required this.active});

  final TabItem tab;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final String type =
        active && tab.iconTypeOn.isNotEmpty ? tab.iconTypeOn : tab.iconType;
    return InkWell(
      onTap: () => context.go('/${tab.pageName}'),
      child: SizedBox(
        height: _kBarHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PexIcon.uni(
              type.isEmpty ? null : type,
              size: 26,
              color: active ? Colors.white : _kUnselected,
            ),
            const SizedBox(height: 2),
            Text(
              ll(lang, tab.i18nText),
              style: TextStyle(
                fontSize: 12,
                color: active ? Colors.white : _kUnselected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 中间的凸起按钮：白底圆内放品牌 logo，下方是「创造 / 对话 / 行动」文案。
class _MidButton extends ConsumerWidget {
  const _MidButton({required this.brand});

  final BrandConfig brand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    return InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.push('/${brand.midPage}'),
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  brand.logoAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.apps, color: PexColors.grey9),
                ),
              ),
              Text(
                ll(lang, brand.midButtonText),
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            ],
          ),
        ),
      );
  }
}
