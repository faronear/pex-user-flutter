/// 路由定义，对应源项目 `pages.json` + `uni.navigateTo / redirectTo / reLaunch`。
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../brands/brand_config.dart';
import '../../pages/home_portal_page.dart';
import '../../pages/menu_aipp_aichat_page.dart';
import '../../pages/menu_aipp_page.dart';
import '../../pages/mid_agidin_page.dart';
import '../../pages/ident_begin_page.dart';
import '../../pages/ident_new_passcode_page.dart';
import '../../pages/ident_new_regcode_page.dart';
import '../../pages/ident_new_register_page.dart';
import '../../pages/ident_old_login_page.dart';
import '../../pages/ident_old_passcode_page.dart';
import '../../pages/ident_old_reset_page.dart';
import '../../pages/placeholder_page.dart';

/// 路由名（与源项目页面文件名一致，便于逐页对照迁移）。
class AppRoutes {
  const AppRoutes._();

  static const String homePortal = 'homePortal';
  static const String midAgidin = 'midAgidin';
  static const String menuAipp = 'menuAipp';
  static const String menuAippAichat = 'menuAippAichat';
  static const String midBabely = 'midBabely';
  static const String midTryapp = 'midTryapp';
  static const String identBegin = 'identBegin';
  static const String identNewPasscode = 'identNewPasscode';
  static const String identNewRegcode = 'identNewRegcode';
  static const String identNewRegister = 'identNewRegister';
  static const String identOldLogin = 'identOldLogin';
  static const String identOldPasscode = 'identOldPasscode';
  static const String identOldReset = 'identOldReset';

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
        builder: (_, _) => const HomePortalPage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.identBegin),
        name: AppRoutes.identBegin,
        builder: (_, _) => const IdentBeginPage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.identNewPasscode),
        name: AppRoutes.identNewPasscode,
        builder: (_, _) => const IdentNewPasscodePage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.identNewRegcode),
        name: AppRoutes.identNewRegcode,
        builder: (_, _) => const IdentNewRegcodePage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.identNewRegister),
        name: AppRoutes.identNewRegister,
        builder: (_, _) => const IdentNewRegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.identOldLogin),
        name: AppRoutes.identOldLogin,
        builder: (_, _) => const IdentOldLoginPage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.identOldPasscode),
        name: AppRoutes.identOldPasscode,
        builder: (_, _) => const IdentOldPasscodePage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.identOldReset),
        name: AppRoutes.identOldReset,
        builder: (_, _) => const IdentOldResetPage(),
      ),
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
      // 兜底：尚未迁移的页面统一显示占位页，避免跳转报错。
      GoRoute(
        path: '/:pageName',
        builder: (BuildContext context, GoRouterState state) =>
            PlaceholderPage(title: state.pathParameters['pageName'] ?? ''),
      ),
    ],
  );
}
