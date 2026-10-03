/// TRYAPP（远近星空）入口：公共域 + 最小 AI 域（基础品牌 / 框架验证）。
///
/// 构建：`flutter build web -t lib/main_tryapp.dart`
library;

import 'package:go_router/go_router.dart';

import 'app.dart';
import 'brands/tryapp_brand.dart';
import 'core/router/app_routes.dart';
import 'core/router/route_ai.dart';
import 'core/router/route_common.dart';
import 'pages/mid_tryapp_page.dart';

void main() => runPexApp(
      brand: const TryappBrand(),
      routes: <RouteBase>[
        ...commonRoutes(),
        ...aiRoutes(),
        // TRYAPP 自己的中页（空白框架）；只在本入口注册，不进其它品牌产物。
        GoRoute(
          path: AppRoutes.path(AppRoutes.midTryapp),
          name: AppRoutes.midTryapp,
          builder: (_, _) => const MidTryappPage(),
        ),
      ],
    );
