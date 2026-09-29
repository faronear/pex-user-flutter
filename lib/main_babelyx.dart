/// Babelyx（巴贝历）入口：公共域 + 创作/NFT 域。
///
/// 构建：`flutter build web -t lib/main_babelyx.dart`
/// 本入口**不 import** AI 域页面，因此 Aibot/AI 对话相关代码不会进入 Babelyx 产物。
library;

import 'package:go_router/go_router.dart';

import 'app.dart';
import 'brands/babelyx_brand.dart';
import 'core/router/route_common.dart';
import 'core/router/route_creation.dart';

void main() => runPexApp(
      brand: const BabelyxBrand(),
      routes: <RouteBase>[...commonRoutes(), ...creationRoutes()],
    );
