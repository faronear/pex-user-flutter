/// 主题：由品牌主色生成 Material3 主题，并保留源项目常用色。
library;

import 'package:flutter/material.dart';

import '../brands/brand_config.dart';

/// 源项目 `App.theme.scss` 中的常用色（三品牌通用部分）。
class PexColors {
  const PexColors._();

  static const Color bg = Color(0xFFF3F4F6);
  static const Color border = Color(0xFFE5E5E5);
  static const Color grey3 = Color(0xFF303133);
  static const Color grey6 = Color(0xFF606266);
  static const Color grey9 = Color(0xFF909399);
  static const Color greyA = Color(0xFFAAAAAA);
  static const Color greyC = Color(0xFFC8C9CC);
  static const Color colorFund = Color(0xFFFFB300);
  static const Color colorMia = Color(0xFF4CD964);
  static const Color redMy = Color(0xFFFA3534);
  static const Color greenMy = Color(0xFF19BE6B);
}

ThemeData buildAppTheme(BrandConfig brand) {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: brand.mainColor,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: PexColors.bg,
    fontFamily: null, // 使用平台默认；后续按源项目字体栈（PingFang/Microsoft YaHei）细化
  );
}
