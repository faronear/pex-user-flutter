/// Agidin（爱奇点）入口：公共域 + AI 域。
///
/// 构建：`flutter build web -t lib/main_agidin.dart`
/// 本入口**不 import** 创作/NFT 页面，因此那些代码不会进入 Agidin 产物（入口级裁剪）。
library;

import 'package:go_router/go_router.dart';

import 'app.dart';
import 'brands/agidin_brand.dart';
import 'core/router/route_ai.dart';
import 'core/router/route_common.dart';

void main() => runPexApp(
      brand: const AgidinBrand(),
      routes: <RouteBase>[...commonRoutes(), ...aiRoutes()],
    );
