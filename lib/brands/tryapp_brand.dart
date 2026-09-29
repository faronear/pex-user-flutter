import 'package:flutter/material.dart';

import '../core/i18n/lang_text.dart';
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

  @override
  String get coinCode => '';

  @override
  LangText get coinIname => const LangText.from('TUC');

  @override
  String get androidAppId => 'cc.tic.tryapp';

  @override
  String get iosBundleId => 'cc.tic.tryapp';
}
