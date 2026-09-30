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
  ///
  /// 注意：TRYAPP 入口目前**只注册了 AI 域 + 公共域**（`main_tryapp.dart`），
  /// `menuCreation` / `menuCreator` 尚未注册，故此处只列已存在的两项；
  /// TRYAPP 的整体定位（是否要创作域、`midTryapp` 是否迁移）待后续确认。
  @override
  List<TabItem> get tabItems => <TabItem>[
        TabItem(
          pageName: 'menuAipp',
          i18nText: const LangText(zhCN: 'Aibot', enUS: 'Aibot', jaJP: 'Aibot'),
          iconType: 'shop',
          iconTypeOn: 'shop-filled',
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
          iconTypeOn: 'person-filled',
        ),
      ];

  @override
  String get coinCode => '';

  @override
  LangText get coinIname => const LangText.from('TUC');

  @override
  String get androidAppId => 'cc.tic.tryapp';

  @override
  String get iosBundleId => 'cc.tic.tryapp';
}
