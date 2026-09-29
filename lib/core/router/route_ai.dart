/// AI 域路由（Agidin 启用）。
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../pages/menu_aipp_aichat_page.dart';
import '../../pages/menu_aipp_page.dart';
import '../../pages/mid_agidin_page.dart';
import 'app_routes.dart';

/// AI 对话 + Aibot 市场。
///
/// 注意：Aibot 的「创建 / 编辑」（`menuAippCreate` / `menuAippModify`）已决定不再迁移
/// （Aibot 概念已被 agent 超越，Agidin 待重新构思）。
List<RouteBase> aiRoutes() => <RouteBase>[
      GoRoute(
        path: AppRoutes.path(AppRoutes.midAgidin),
        name: AppRoutes.midAgidin,
        builder: (BuildContext context, GoRouterState state) => MidAgidinPage(
          aicode: state.uri.queryParameters['aicode'],
        ),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.menuAipp),
        name: AppRoutes.menuAipp,
        builder: (BuildContext context, GoRouterState state) => MenuAippPage(
          tagnow: state.uri.queryParameters['tagnow'],
        ),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.menuAippAichat),
        name: AppRoutes.menuAippAichat,
        builder: (BuildContext context, GoRouterState state) => MenuAippAichatPage(
          aicode: state.uri.queryParameters['aicode'],
        ),
      ),
    ];
