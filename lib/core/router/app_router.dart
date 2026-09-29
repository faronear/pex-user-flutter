/// 路由定义，对应源项目 `pages.json` + `uni.navigateTo / redirectTo / reLaunch`。
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../brands/brand_config.dart';
import '../../pages/home_portal_page.dart';
import '../../pages/placeholder_page.dart';

/// 路由名（与源项目页面文件名一致，便于逐页对照迁移）。
class AppRoutes {
  const AppRoutes._();

  static const String homePortal = 'homePortal';
  static const String midAgidin = 'midAgidin';
  static const String midBabely = 'midBabely';
  static const String midTryapp = 'midTryapp';
  static const String identBegin = 'identBegin';

  static String path(String name) => '/$name';
}

/// 构建路由表。[brand] 决定落地页（`midPage` / `appLandPage`）。
GoRouter createAppRouter(BrandConfig brand) {
  return GoRouter(
    initialLocation: AppRoutes.path(AppRoutes.homePortal),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.path(AppRoutes.homePortal),
        name: AppRoutes.homePortal,
        builder: (BuildContext context, GoRouterState state) =>
            const HomePortalPage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.identBegin),
        name: AppRoutes.identBegin,
        builder: (BuildContext context, GoRouterState state) =>
            const PlaceholderPage(title: 'identBegin'),
      ),
      // 品牌落地页（对应源项目 midXxx）。迁移完成后替换为真实页面。
      for (final String name in <String>[
        AppRoutes.midAgidin,
        AppRoutes.midBabely,
        AppRoutes.midTryapp,
      ])
        GoRoute(
          path: AppRoutes.path(name),
          name: name,
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderPage(title: name),
        ),
    ],
  );
}
