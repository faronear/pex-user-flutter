/// 遇见（创作者列表），对应源项目 `pages/menuCreator.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/appmeta/page_meta.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_router.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/part_creator_all.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_window_layout.dart';

class MenuCreatorPage extends ConsumerWidget {
  const MenuCreatorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStartupState startup = ref.watch(appStartupProvider);
    final DeviceInfo device = DeviceInfo.of(context);
    final String lang = ref.watch(languageProvider);
    final bool online = ref.watch(isOnlineProvider);

    // 分类标签取自本地预置层的 `Creator.uiClassDict`。
    final Object? creatorRaw = ref.watch(envarProvider).raw['Creator'];
    final Map<String, dynamic> dict =
        ((creatorRaw is Map ? creatorRaw['uiClassDict'] : null) as Map?)
                ?.cast<String, dynamic>() ??
            <String, dynamic>{
              'USALL': <String, String>{
                'zhCN': '遇见原创主',
                'enUS': 'Meet Creators',
              },
            };
    final List<String> tabs = dict.keys.toList();

    return PartWindowLayout(
      pageName: AppRoutes.menuCreator,
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
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Text(
                                  ll(lang, LangText.fromMap(dict[tabs[i]])),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: i == 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: i == 0
                                        ? PexColors.blueMy
                                        : PexColors.grey6,
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
                          online
                              ? '/${AppRoutes.umyCircle}'
                              : '/${AppRoutes.identBegin}',
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              ll(
                                lang,
                                pageMetaOf(AppRoutes.umyCircle)?.i18nGotoTitle ??
                                    const LangText(zhCN: '我的圈子', enUS: 'My Circles'),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: PexColors.grey3,
                              ),
                            ),
                            PexIcon.uni('forward', size: 22, color: PexColors.grey3),
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
                        child: const PartCreatorAll(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
