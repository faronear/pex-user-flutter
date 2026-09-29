/// Aibot 市场，对应源项目 `pages/menuAipp.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/state/ai_provider.dart';
import '../core/state/app_providers.dart';
import '../core/state/app_startup_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/part_aipp_models.dart';
import '../widgets/part_aipp_picked.dart';
import '../widgets/part_aipp_shared.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_window_layout.dart';

const LangText _kCreateAibot = LangText(
  zhCN: '创建 Aibot',
  enUS: 'Create Aibot',
  deDE: 'Aibot erstellen',
  jaJP: 'Aibot 作成',
);

class MenuAippPage extends ConsumerStatefulWidget {
  const MenuAippPage({super.key, this.tagnow});

  /// 路由参数 `?tagnow=`（分类）。
  final String? tagnow;

  @override
  ConsumerState<MenuAippPage> createState() => _MenuAippPageState();
}

class _MenuAippPageState extends ConsumerState<MenuAippPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String tag = widget.tagnow ?? ref.read(aiProvider).aippTagNow;
      final String resolved =
          kAippDict.containsKey(tag) ? tag : kAippDict.keys.first;
      ref.read(aiProvider.notifier).setAippTagNow(resolved);
    });
  }

  void _openChat(String aicode) {
    ref.read(aiProvider.notifier).setAicodeNow(aicode);
    context.push('/menuAippAichat?aicode=$aicode');
  }

  @override
  Widget build(BuildContext context) {
    final AppStartupState startup = ref.watch(appStartupProvider);
    final DeviceInfo device = DeviceInfo.of(context);
    final String lang = ref.watch(languageProvider);
    final String tagNow = ref.watch(aiProvider).aippTagNow;

    return PartWindowLayout(
      pageName: 'menuAipp',
      child: Column(
        children: <Widget>[
          _buildTopBar(context, lang, tagNow, device),
          Expanded(
            child: !startup.afterAutologging
                ? const PartShowLoading()
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: switch (tagNow) {
                          'AIPPS' => PartAippShared(onPick: _openChat),
                          'AIPPMY' => PartAippPicked(onPick: _openChat),
                          _ => PartAippModels(onPick: _openChat),
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    String lang,
    String tagNow,
    DeviceInfo device,
  ) {
    return Container(
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
                  for (final MapEntry<String, Map<String, String>> entry
                      in kAippDict.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(aiProvider.notifier).setAippTagNow(entry.key),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              ll(lang, LangText.fromMap(entry.value)),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: entry.key == tagNow
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: entry.key == tagNow
                                    ? const Color(0xFF2979FF)
                                    : PexColors.grey6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 2,
                              width: 24,
                              color: entry.key == tagNow
                                  ? const Color(0xFF2979FF)
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/menuAippCreate'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ref.watch(brandProvider).mainColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  PexIcon.uni('plusempty', size: 14, color: Colors.white),
                  const SizedBox(width: 2),
                  Text(
                    ll(lang, _kCreateAibot),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
