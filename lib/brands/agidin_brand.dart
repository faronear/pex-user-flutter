import 'package:flutter/material.dart';

import '../core/i18n/lang_text.dart';
import 'brand_config.dart';
import 'brand_features.dart';

/// Agidin（爱奇点）：AI 应用市场，主色蓝 `#25bcf1`。
class AgidinBrand extends BrandConfig {
  const AgidinBrand();

  @override
  String get appkey => 'AKAGIDIN';

  @override
  String get filekey => 'agidin';

  @override
  String get webDomain => 'agidin.com';

  @override
  String get cfpWebapp => 'user-agidin-com';

  @override
  String get cfpWebstore => 'store-agidin-com';

  @override
  String get cacheWebapp => 'https://agidin.com';

  @override
  String get cacheWebstore => 'https://store.agidin.com';

  @override
  LangText get displayName => const LangText(
        zhCN: '爱奇点',
        enUS: 'Agidin',
        jaJP: '愛奇點',
        deDE: 'Agidin',
      );

  @override
  Color get mainColor => const Color(0xFF25BCF1);

  @override
  Color get portalBackgroundColor => mainColor;

  @override
  String get logoAsset => 'assets/static/logoAgidin.png';

  @override
  String get portalImageAsset => 'assets/static/bgAgidin.jpg';

  @override
  BrandFeatures get features => BrandFeatures.agidin;

  @override
  String get appLandPage => 'midAgidin';

  @override
  String get midPage => 'midAgidin';

  @override
  String get coinCode => 'AGI';

  @override
  LangText get coinIname => const LangText(zhCN: '奇点币', enUS: 'Agidin');

  @override
  String get androidAppId => 'cc.tic.agidin';

  @override
  String get iosBundleId => 'cc.tic.agidin';
}
