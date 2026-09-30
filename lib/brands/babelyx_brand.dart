import 'package:flutter/material.dart';

import '../core/i18n/lang_text.dart';
import '../core/appmeta/tab_bar.dart';
import 'brand_config.dart';
import 'brand_features.dart';

/// Babelyx（巴贝历）：内容创作与 NFT 市场，主色红橙 `#fc592b`。
class BabelyxBrand extends BrandConfig {
  const BabelyxBrand();

  @override
  String get appkey => 'AKBABELY';

  @override
  String get filekey => 'babely';

  @override
  String get webDomain => 'babelyx.com';

  @override
  String get cfpWebapp => 'user-babelyx-com';

  @override
  String get cfpWebstore => 'store-babelyx-com';

  @override
  String get cacheWebapp => 'https://babelyx.com';

  @override
  String get cacheWebstore => 'https://store.babelyx.com';

  @override
  LangText get displayName => const LangText(
        zhCN: '巴贝历',
        enUS: 'Babelyx',
        jaJP: 'バベリクス',
        deDE: 'Babelyx',
      );

  @override
  Color get mainColor => const Color(0xFFFC592B);

  @override
  String get logoAsset => 'assets/static/logoBabely.png';

  @override
  String get portalImageAsset => 'assets/static/bgBabelyx.jpg';

  @override
  BrandFeatures get features => BrandFeatures.babelyx;

  @override
  String get appLandPage => 'midBabely';

  @override
  String get midPage => 'midBabely';

  @override
  LangText get midPageTitle => const LangText(
        zhCN: '创造新可能',
        enUS: 'Create New Possibility',
        deDE: 'Neue Möglichkeiten Erstellen',
        jaJP: '新しい可能性を創造',
      );

  @override
  String get midPageIcon => 'fire-filled';

  // 源项目 `tabBar.midButton`：Babelyx 用火苗图标（创造=创作+铸造），文案「创造」。
  @override
  String get midButtonIcon => 'fire';

  @override
  String get midButtonIconOn => 'fire-filled';

  @override
  LangText get midButtonText => const LangText(
        zhCN: '创造',
        enUS: 'Create',
        deDE: 'Erstellen',
        jaJP: '創造',
      );


  /// 标签栏（源项目 `pages.json` 的 `tabBar.list`）：探索 / 遇见 / AIGC / 我的。
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
          i18nText: const LangText(zhCN: 'AIGC', enUS: 'AIGC', deDE: 'AIGC', jaJP: 'AIGC'),
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

  @override
  String get coinCode => 'BAB';

  @override
  LangText get coinIname => const LangText(zhCN: '巴贝币', enUS: 'Babelyx');

  @override
  String get androidAppId => 'cc.tic.babelyx';

  @override
  String get iosBundleId => 'cc.tic.babelyx';
}
