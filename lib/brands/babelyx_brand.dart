import 'package:flutter/material.dart';

import '../core/i18n/lang_text.dart';
import 'brand_config.dart';

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
  String get appLandPage => 'midBabely';

  @override
  String get midPage => 'midBabely';

  @override
  String get coinCode => 'BAB';

  @override
  LangText get coinIname => const LangText(zhCN: '巴贝币', enUS: 'Babelyx');

  @override
  String get androidAppId => 'cc.tic.babelyx';

  @override
  String get iosBundleId => 'cc.tic.babelyx';
}
