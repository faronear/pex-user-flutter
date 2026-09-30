/// PC 顶部导航栏，对应源项目 `parts/partWindowHeader.vue`（仅 PC 显示）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/appmeta/page_meta.dart';
import '../core/appmeta/tab_bar.dart';
import '../core/i18n/i18n.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_router.dart';
import '../core/state/app_providers.dart';
import '../core/state/envar_provider.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../theme/app_theme.dart';

class PartWindowHeader extends ConsumerWidget {
  const PartWindowHeader({super.key, this.pageName = ''});

  final String pageName;

  static const double _height = 80;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DeviceInfo device = DeviceInfo.of(context);
    if (!device.inPc) return const SizedBox.shrink();

    final brand = ref.watch(brandProvider);
    final String lang = ref.watch(languageProvider);
    final bool online = ref.watch(isOnlineProvider);
    final Map<String, dynamic> user = ref.watch(onlineUserProvider);
    final Envar envar = ref.watch(envarProvider);

    return Container(
      height: _height,
      color: PexColors.grey3,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Stack(
        children: <Widget>[
          Row(
            children: <Widget>[
              _buildLogo(context, brand.logoAsset),
              ..._buildTabs(context, lang, brand.tabItems),
              const Spacer(),
              if (online)
                ..._buildCreatorShortcuts(context, ref, brand.showCreatorShortcuts, user, lang, envar)
              else
                _buildGuestIcon(context),
              if (online) _buildAvatar(context, user),
            ],
          ),
          Align(
            alignment: Alignment.center,
            child: _buildMidButton(context, ref, lang),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context, String logoAsset) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.path(AppRoutes.homePortal)),
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(right: 20),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          logoAsset,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(Icons.apps, color: PexColors.grey3),
        ),
      ),
    );
  }

  /// 顶栏标签（源项目取 `tabBar.list` 去掉最后一项——最后一项由头像/登录图标代表）。
  List<Widget> _buildTabs(BuildContext context, String lang, List<TabItem> tabs) {
    return <Widget>[
      for (final TabItem tab in tabs.take(tabs.length > 1 ? tabs.length - 1 : tabs.length))
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: TextButton(
            onPressed: () => context.go('/${tab.pageName}'),
            style: TextButton.styleFrom(
              foregroundColor: pageName == tab.pageName ? PexColors.grey3 : Colors.white,
              backgroundColor: pageName == tab.pageName ? Colors.white : Colors.transparent,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
            ),
            child: Text(ll(lang, tab.i18nText)),
          ),
        ),
    ];
  }

  Widget _buildMidButton(BuildContext context, WidgetRef ref, String lang) {
    final brand = ref.watch(brandProvider);
    final bool active = pageName == brand.midPage;
    return GestureDetector(
      onTap: () => context.push('/${brand.midPage}'),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: active ? Colors.white : PexColors.grey3,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PexIcon.uni(
              active ? brand.midButtonIconOn : brand.midButtonIcon,
              size: 30,
              color: active ? PexColors.grey3 : Colors.white,
            ),
            if (!active)
              Text(
                ll(lang, brand.midButtonText),
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCreatorShortcuts(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
    Map<String, dynamic> user,
    String lang,
    Envar envar,
  ) {
    if (!enabled) return <Widget>[];
    return <Widget>[
      _counter(context, '/umyMia', 'umyMia',
          (user['countMiaUnread'] ?? 0).toString(),
          highlight: (num.tryParse('${user['countMiaUnread'] ?? 0}') ?? 0) > 0),
      _counter(context, '/umyFund', 'umyFund',
          '${numberPrecision(user['balanceTUC'], 0)}${envar.tucSymbol}'),
    ];
  }

  Widget _counter(
    BuildContext context,
    String path,
    String pageName,
    String text, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () => context.push(path),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PexIcon(
              PexIcons.byPrefix(
                pageMetaOf(pageName)?.gotoIconPrefix,
                pageMetaOf(pageName)?.gotoIconType,
              ),
              size: 22,
              color: Colors.white,
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: highlight ? const Color(0xFFFA3534) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestIcon(BuildContext context) {
    return IconButton(
      onPressed: () => context.push(AppRoutes.path(AppRoutes.identBegin)),
      icon: PexIcon.uni('person', size: 48, color: Colors.white),
      tooltip: '',
    );
  }

  Widget _buildAvatar(BuildContext context, Map<String, dynamic> user) {
    final String portrait = user['portrait']?.toString() ?? '';
    final String nickname = user['nickname']?.toString() ?? '';
    // 头像来自服务端（`/static` 或 http(s)），用 ServerImage 而不是 AssetImage：
    // AssetImage 无法加载网络地址，会直接抛错。
    return GestureDetector(
      onTap: () => context.go('/menuUzone'),
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: PexColors.grey6,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: portrait.isEmpty
            ? Text(
                nickname.isEmpty ? '' : nickname.substring(0, nickname.length >= 2 ? 2 : 1),
                style: const TextStyle(color: Colors.white, fontSize: 20),
              )
            : ServerImage(portrait, fit: BoxFit.cover),
      ),
    );
  }
}
