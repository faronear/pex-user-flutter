/// 更多资源，对应源项目 `pages/userResource.vue`。
///
/// 按 `linkTree` 的分组（webs / apps / comms / recos）展示图标入口，点击进详情页。
/// 分组与子项的可见性规则与源项目一致：`hiddenGroup` 隐藏整组；
/// apps 组内按当前平台过滤；recos 组内排除本品牌自身。
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
import '../core/router/app_router.dart';
import '../core/state/app_providers.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../core/util/server_url.dart';
import '../theme/app_theme.dart';
import '../widgets/part_lang_table.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_window_layout.dart';

class UserResourcePage extends ConsumerWidget {
  const UserResourcePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStartupState startup = ref.watch(appStartupProvider);
    final DeviceInfo device = DeviceInfo.of(context);
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final String appkey = ref.watch(brandProvider).appkey;

    return PartWindowLayout(
      pageName: AppRoutes.userResource,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 10),
                if (device.inPc)
                  PartNavibarPcFixed(pageName: AppRoutes.userResource),
                if (!startup.afterAutologging)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: PartShowLoading(),
                  )
                else
                  for (final String group in envar.linkTree.keys)
                    if (!envar.isLinkGroupHidden(group))
                      _GroupSection(
                        group: group,
                        subtags: envar.subtags(group),
                        groupName: ll(lang, LangText.fromMap(envar.linkGroup(group)['iName'])),
                        lang: lang,
                        appkey: appkey,
                        device: device,
                      ),
                if (startup.afterAutologging) ...<Widget>[
                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 5, 0, 20),
                    height: 1,
                    color: PexColors.border,
                  ),
                  _ContactButton(lang: lang),
                  if (!device.inPc)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: PartLangTable(color: PexColors.grey9),
                    ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 一个分组：分组标题条 + 图标入口网格。
class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.group,
    required this.subtags,
    required this.groupName,
    required this.lang,
    required this.appkey,
    required this.device,
  });

  final String group;
  final Map<String, dynamic> subtags;
  final String groupName;
  final String lang;
  final String appkey;
  final DeviceInfo device;

  @override
  Widget build(BuildContext context) {
    final List<String> keys = <String>[
      for (final String key in subtags.keys)
        if (_visible(key)) key,
    ];
    if (keys.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          color: PexColors.greyE,
          child: Text(groupName, style: const TextStyle(fontSize: 14)),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Wrap(
            alignment: WrapAlignment.start,
            children: <Widget>[
              for (final String key in keys)
                _ResourceItem(
                  tagNow: key,
                  subtag: (subtags[key] as Map?)?.cast<String, dynamic>() ??
                      <String, dynamic>{},
                  lang: lang,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 与源项目一致：`apps` 按平台过滤，`recos` 排除本品牌。
  bool _visible(String key) {
    if (group == 'apps') {
      return key == 'webapp' ||
          (key == 'android' && !device.inAppIos) ||
          (key == 'ios' && !device.inAppAndroid);
    }
    if (group == 'recos') return key != appkey;
    return true;
  }
}

class _ResourceItem extends ConsumerWidget {
  const _ResourceItem({
    required this.tagNow,
    required this.subtag,
    required this.lang,
  });

  final String tagNow;
  final Map<String, dynamic> subtag;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String iconType = subtag['iconType']?.toString() ?? '';
    final String iconPrefix = subtag['iconPrefix']?.toString() ?? '';
    final String image = subtag['img']?.toString() ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.push('/${AppRoutes.userResourceDetail}?tagnow=$tagNow'),
      child: Container(
        width: 90,
        margin: const EdgeInsets.fromLTRB(0, 0, 15, 15),
        padding: const EdgeInsets.all(5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 44,
              height: 44,
              child: ClipOval(
                child: iconType.isNotEmpty
                    ? Center(
                        child: PexIcon(
                          PexIcons.byPrefix(iconPrefix.isEmpty ? null : iconPrefix, iconType),
                          size: 30,
                          color: PexColors.blueMy,
                        ),
                      )
                    : image.isNotEmpty
                        ? ServerImage(image, fit: BoxFit.contain)
                        : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ll(lang, LangText.fromMap(subtag['i18nName'])),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: PexColors.blueMy),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    final PageMeta? meta = pageMetaOf(AppRoutes.umyContact);
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(AppRoutes.path(AppRoutes.umyContact)),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if ((meta?.gotoIconType ?? '').isNotEmpty)
                PexIcon(
                  PexIcons.byPrefix(meta?.gotoIconPrefix, meta?.gotoIconType),
                  size: 22,
                  color: PexColors.blueMy,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  ll(lang, meta?.i18nPageTitle ?? const LangText.from('')),
                  style: const TextStyle(fontSize: 14, color: PexColors.blueMy),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
