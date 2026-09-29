/// 路由构造：由各品牌入口传入自己的路由组。
///
/// 分组文件：`route_common.dart`（公共）/ `route_ai.dart`（AI 域）/ `route_creation.dart`（创作 NFT 域）。
/// **必须分组分文件**，否则引入公共路由会连带把其它域的页面打进产物，破坏入口级裁剪。
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../pages/placeholder_page.dart';
import 'app_routes.dart';

export 'app_routes.dart';

/// 组装路由表；[routes] 为品牌入口提供的路由组。
GoRouter createAppRouter({required List<RouteBase> routes}) => GoRouter(
      initialLocation: AppRoutes.path(AppRoutes.homePortal),
      routes: <RouteBase>[
        ...routes,
        // 兜底：尚未迁移的页面统一显示占位页，避免跳转报错。
        GoRoute(
          path: '/:pageName',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderPage(title: state.pathParameters['pageName'] ?? ''),
        ),
      ],
    );
