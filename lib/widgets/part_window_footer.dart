/// PC 页脚，对应源项目 `parts/partWindowFooter.vue`（仅 PC 显示）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/appmeta/page_meta.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../theme/app_theme.dart';
import 'part_breathing_opacity.dart';
import 'part_lang_table.dart';

class PartWindowFooter extends ConsumerWidget {
  const PartWindowFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DeviceInfo device = DeviceInfo.of(context);
    if (!device.inPc) return const SizedBox.shrink();

    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final bool socketAlive = ref.watch(appStartupProvider).connected;

    return Container(
      color: PexColors.grey3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _contactButton(context, lang),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _linkGroup(context, lang, envar, 'webs'),
                    _linkGroup(context, lang, envar, 'apps'),
                    _linkGroup(context, lang, envar, 'comms'),
                  ],
                ),
                const SizedBox(width: 12),
                const PartLangTable(color: Colors.white),
              ],
            ),
          ),
          Container(
            height: 40,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF25BCF1), width: 4),
              ),
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => context.push('/userResource'),
              child: PartBreathingOpacity(
                isBreathing: !socketAlive,
                child: Text(
                  '© ${ll(lang, envar.callnames)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactButton(BuildContext context, String lang) {
    final PageMeta? meta = pageMetaOf('umyContact');
    return TextButton.icon(
      onPressed: () => context.push('/umyContact'),
      icon: PexIcon(
        PexIcons.byPrefix(meta?.gotoIconPrefix, meta?.gotoIconType),
        size: 22,
        color: Colors.white,
      ),
      label: Text(
        meta?.i18nPageTitle == null ? '' : ll(lang, meta!.i18nPageTitle!),
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _linkGroup(BuildContext context, String lang, Envar envar, String group) {
    final Map<String, dynamic> subtags = envar.subtags(group);
    final LangText groupName = LangText.fromMap(
      (envar.linkTree[group] as Map?)?['iName'],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!groupName.isEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                ll(lang, groupName),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          for (final dynamic raw in subtags.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: PexIcon(
                PexIcons.byPrefix(
                  (raw as Map)['iconPrefix']?.toString(),
                  raw['iconType']?.toString(),
                ),
                size: 22,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
