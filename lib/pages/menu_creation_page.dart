/// 探索创作品（创作域首页），对应源项目 `pages/menuCreation.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_router.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/part_creation_all.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_window_layout.dart';

/// 右上角「前往」按钮文案（源项目 `pageSet['umyCollection'].i18nGotoTitle`）。
///
/// 注意与页面自身标题（`_kNavTitle`）不同：源项目里 goto 标题是「我的选集」，
/// 而列表标题是「选集」——三者在 `pages.json` 里是三个不同的字段。
const LangText _kGotoCollection = LangText(
  zhCN: '我的选集',
  enUS: 'My Collections',
  deDE: 'Meine Sammlungen',
  jaJP: 'マイコレクション',
);

class MenuCreationPage extends ConsumerWidget {
  const MenuCreationPage({super.key, this.tagNow = ''});

  /// 路由 `?tagnow=<uiClassDict 的键>`；非法值回落到第一个分类。
  final String tagNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStartupState startup = ref.watch(appStartupProvider);
    final DeviceInfo device = DeviceInfo.of(context);
    final String lang = ref.watch(languageProvider);
    final bool online = ref.watch(isOnlineProvider);

    // 分类标签取自本地预置层的 `Creation.uiClassDict`（服务端不下发）。
    final Object? dictRaw = ref.watch(envarProvider).raw['Creation'];
    final Map<String, dynamic> dict = ((dictRaw is Map ? dictRaw['uiClassDict'] : null)
                as Map?)
            ?.cast<String, dynamic>() ??
        <String, dynamic>{'POALL': <String, String>{'zhCN': '探索创作品', 'enUS': 'Explore Creations'}};
    final List<String> tabs = dict.keys.toList();
    // 源项目 `onLoad({tagnow})`：命中字典里存在的键才生效，否则用第一个。
    final int current = tabs.contains(tagNow) ? tabs.indexOf(tagNow) : 0;

    return PartWindowLayout(
      pageName: AppRoutes.menuCreation,
      showTabBar: true,
      child: Column(
        children: <Widget>[
          Container(
            color: PexColors.bg,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: <Widget>[
                            for (int i = 0; i < tabs.length; i++)
                              GestureDetector(
                                // 源项目：点分类是 `uni.reLaunch`（换 tagnow 重开本页）。
                                onTap: i == current
                                    ? null
                                    : () => context.go(
                                          '${AppRoutes.path(AppRoutes.menuCreation)}?tagnow=${tabs[i]}',
                                        ),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Text(
                                    ll(lang, LangText.fromMap(dict[tabs[i]])),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: i == current
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: i == current
                                          ? PexColors.blueMy
                                          : PexColors.grey6,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (startup.afterAutologging)
                      GestureDetector(
                        onTap: () => context.push(
                          online ? '/${AppRoutes.umyCollection}' : '/${AppRoutes.identBegin}',
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              ll(lang, _kGotoCollection),
                              style: const TextStyle(fontSize: 14, color: PexColors.grey6),
                            ),
                            PexIcon.uni('forward', size: 22, color: PexColors.grey6),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: device.inPc ? 50 : 40),
          Expanded(
            child: !startup.afterAutologging
                ? const PartShowLoading()
                : SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: const PartCreationAll(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
