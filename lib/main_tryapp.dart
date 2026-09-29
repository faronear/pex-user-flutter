/// TRYAPP（远近星空）入口：公共域 + 最小 AI 域（基础品牌 / 框架验证）。
///
/// 构建：`flutter build web -t lib/main_tryapp.dart`
library;

import 'package:go_router/go_router.dart';

import 'app.dart';
import 'brands/tryapp_brand.dart';
import 'core/router/route_ai.dart';
import 'core/router/route_common.dart';

void main() => runPexApp(
      brand: const TryappBrand(),
      routes: <RouteBase>[...commonRoutes(), ...aiRoutes()],
    );
