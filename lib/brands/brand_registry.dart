/// 品牌注册表：按 appkey 或编译期 `--dart-define=BRAND=` 选择品牌。
library;

import 'agidin_brand.dart';
import 'babelyx_brand.dart';
import 'brand_config.dart';

const List<BrandConfig> kBrands = <BrandConfig>[
  AgidinBrand(),
  BabelyxBrand(),
];

/// 编译期品牌标识（`flutter run --dart-define=BRAND=AKBABELY`），默认 AKAGIDIN。
const String kBuildBrandAppkey = String.fromEnvironment(
  'BRAND',
  defaultValue: 'AKAGIDIN',
);

/// 按 appkey 取品牌；未知时回退 Agidin。
BrandConfig brandByAppkey(String appkey) {
  for (final BrandConfig brand in kBrands) {
    if (brand.appkey == appkey) return brand;
  }
  return kBrands.first;
}

/// 取编译期指定的品牌。
BrandConfig brandFromBuild() => brandByAppkey(kBuildBrandAppkey);
