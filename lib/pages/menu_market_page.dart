/// 交易市场，对应源项目 `pages/menuMarket.vue`。
///
/// **注意：源项目这一页本身就是个空壳**——分类字典 `Market.uiClassDict` 只有 `MKALL`，
/// 且该分支只渲染 `partEmptyList`（「当前没有创作品在售」）。交易功能从未实装，
/// 迁移版照此保持一致：分类条 + 右上「我的资金」+ 空态。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/router/app_routes.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/part_empty_list.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_window_layout.dart';

/// 右上角链接（源项目这里直接用字面文案，而非 `pageSet['umyFund'].i18nGotoTitle`）。
const LangText _kMyCoins = LangText(zhCN: '我的资金', enUS: 'My Coins');

/// 兜底分类字典（正常情况下由预置层 `Market.uiClassDict` 提供）。
const Map<String, LangText> _kDefaultDict = <String, LangText>{
  'MKALL': LangText(
    zhCN: '交易市场',
    enUS: 'Exchange Market',
    deDE: 'Tauschmarkt',
    jaJP: '取引市場',
  ),
};

class MenuMarketPage extends ConsumerWidget {
  const MenuMarketPage({super.key, this.tagNow = ''});

  /// 路由 `?tagnow=<uiClassDict 的键>`；非法值回落到第一个分类。
  final String tagNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final AppStartupState startup = ref.watch(appStartupProvider);

    final Object? market = ref.watch(envarProvider).raw['Market'];
    final Object? dictRaw = market is Map ? market['uiClassDict'] : null;
    final List<String> tabs = <String>[
      if (dictRaw is Map)
        for (final Object key in dictRaw.keys) key.toString()
      else
        ..._kDefaultDict.keys,
    ];
    final String current = tabs.contains(tagNow)
        ? tagNow
        : (tabs.isEmpty ? 'MKALL' : tabs.first);

    return PartWindowLayout(
      pageName: AppRoutes.menuMarket,
      child: Column(
        children: <Widget>[
          Container(
            color: PexColors.bg,
            padding: const EdgeInsets.only(top: 15),
            child: Column(
              children: <Widget>[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      for (final String key in tabs)
                        GestureDetector(
                          // 源项目：点分类是 `uni.reLaunch`（换 tagnow 重开本页）。
                          onTap: key == current
                              ? null
                              : () => context.go(
                                    '${AppRoutes.path(AppRoutes.menuMarket)}?tagnow=$key',
                                  ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              ll(lang, _label(dictRaw, key)),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: key == current
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: key == current
                                    ? PexColors.blueMy
                                    : PexColors.grey6,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (startup.afterAutologging)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10, bottom: 6),
                      child: InkWell(
                        onTap: () => context.push(
                          ref.watch(isOnlineProvider)
                              ? AppRoutes.path(AppRoutes.umyFund)
                              : AppRoutes.path(AppRoutes.identBegin),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              _kMyCoins.resolve(lang),
                              style: const TextStyle(fontSize: 12),
                            ),
                            PexIcon.uni('forward',
                                size: 16, color: PexColors.grey3),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 65),
          Expanded(
            child: !startup.afterAutologging
                ? const PartShowLoading()
                : SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: current == 'MKALL'
                            ? Padding(
                                padding: const EdgeInsets.all(20),
                                child: PartEmptyList(
                                  prompt: ref.watch(envarProvider).tMarketEmpty,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 取某分类的显示文案（预置字典 / 兜底字典）。
  static LangText _label(Object? dictRaw, String key) {
    if (dictRaw is Map && dictRaw[key] != null) {
      return LangText.fromMap(dictRaw[key]);
    }
    return _kDefaultDict[key] ??
        LangText(zhCN: key, enUS: key);
  }
}
