import 'package:flutter/material.dart';

import '../core/i18n/lang_text.dart';
import '../core/appmeta/tab_bar.dart';
import 'brand_config.dart';
import 'brand_features.dart';

/// TRYAPP（远近星空）：基础品牌 / 框架验证，主色 `#66bbee`。
class TryappBrand extends BrandConfig {
  const TryappBrand();

  @override
  String get appkey => 'AKTRYAPP';

  @override
  String get filekey => 'tryapp';

  @override
  String get webDomain => 'tic.cc';

  @override
  String get cfpWebapp => 'tryapp-user';

  @override
  String get cfpWebstore => 'tryapp-store';

  @override
  String get cacheWebapp => 'https://tryapp-user.pages.dev';

  @override
  String get cacheWebstore => 'https://tryapp-store.pages.dev';

  @override
  LangText get displayName => const LangText(
        zhCN: '远近星空',
        enUS: 'TRYAPP',
        jaJP: 'TRYAPP',
        deDE: 'TRYAPP',
      );

  @override
  Color get mainColor => const Color(0xFF66BBEE);

  @override
  String get logoAsset => 'assets/static/logoTryapp.png';

  @override
  String get portalImageAsset => 'assets/static/bgStars.jpg';

  @override
  BrandFeatures get features => BrandFeatures.tryapp;

  @override
  String get appLandPage => 'midTryapp';

  @override
  String get midPage => 'midTryapp';
  /// 标签栏（源项目 `pages.json` 的 `tabBar.list`）：探索 / 遇见 / Aibot / 我的。
  @override
  List<TabItem> get tabItems => <TabItem>[
        TabItem(
          pageName: 'menuCreation',
          i18nText: const LangText(
            zhCN: '探索',
            enUS: 'Creations',
            deDE: 'Kreation',
            jaJP: '探索',
          ),
          iconType: 'navigate',
        ),
        TabItem(
          pageName: 'menuCreator',
          i18nText: const LangText(
            zhCN: '遇见',
            enUS: 'Creators',
            deDE: 'Ersteller',
            jaJP: '出会い',
          ),
          iconType: 'staff',
        ),
        TabItem(
          pageName: 'menuAipp',
          i18nText: const LangText(zhCN: 'Aibot', enUS: 'Aibot', deDE: 'Aibot', jaJP: 'Aibot'),
          iconType: '',
        ),
        TabItem(
          pageName: 'menuUzone',
          i18nText: const LangText(
            zhCN: '我的',
            enUS: 'My',
            deDE: 'Mein',
            jaJP: 'マイ',
          ),
          iconType: 'person',
        ),
      ];


  // 源项目 `tabBar.midButton`：TRYAPP 同为火苗图标，文案「行动」。
  @override
  String get midButtonIcon => 'fire';

  @override
  String get midButtonIconOn => 'fire-filled';

  @override
  LangText get midButtonText => const LangText(
        zhCN: '行动',
        enUS: 'Act',
        deDE: 'Handeln',
        jaJP: '行動',
      );

  @override
  String get coinCode => '';

  @override
  LangText get coinIname => const LangText.from('TUC');

  @override
  String get androidAppId => 'cc.tic.tryapp';

  @override
  String get iosBundleId => 'cc.tic.tryapp';
}
