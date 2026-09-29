/// 默认入口：品牌由编译期 `--dart-define=BRAND=` 决定，默认 AKAGIDIN。
///
/// 各品牌的独立入口见 `main_agidin.dart` / `main_babelyx.dart` / `main_tryapp.dart`。
library;

import 'app.dart';
import 'brands/brand_registry.dart';

void main() => runPexApp(brandFromBuild());
