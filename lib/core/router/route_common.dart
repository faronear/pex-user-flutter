/// 公共路由（所有品牌共用）。
///
/// 注意：各业务域的路由必须分文件，避免「引入公共路由时连带把其它域页面打进产物」，
/// 从而破坏品牌入口的 **入口级裁剪**（见 `brand_features.dart` 注释）。
library;

import 'package:go_router/go_router.dart';

import '../../pages/home_portal_page.dart';
import '../../pages/ident_begin_page.dart';
import '../../pages/ident_new_passcode_page.dart';
import '../../pages/ident_new_regcode_page.dart';
import '../../pages/ident_new_register_page.dart';
import '../../pages/ident_old_login_page.dart';
import '../../pages/ident_old_passcode_page.dart';
import '../../pages/ident_old_reset_page.dart';
import '../../pages/menu_uzone_page.dart';
import '../../pages/umy_config_page.dart';
import '../../pages/umy_contact_page.dart';
import 'app_routes.dart';

/// 首页门户 + 账户/登录注册闭环 + 我的空间。
List<RouteBase> commonRoutes() => <RouteBase>[
      GoRoute(
        path: AppRoutes.path(AppRoutes.homePortal),
        name: AppRoutes.homePortal,
        builder: (_, _) => const HomePortalPage(),
      ),
      // 「我的空间」是三个品牌共有的 tabBar 页（源项目 `pages.json` 的注册方式）。
      GoRoute(
        path: AppRoutes.path(AppRoutes.menuUzone),
        name: AppRoutes.menuUzone,
        builder: (_, _) => const MenuUzonePage(),
      ),
      // 「我的设置」「联系客服」也是三品牌共用的账户域页面。
      GoRoute(
        path: AppRoutes.path(AppRoutes.umyConfig),
        name: AppRoutes.umyConfig,
        builder: (_, _) => const UmyConfigPage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.umyContact),
        name: AppRoutes.umyContact,
        builder: (_, _) => const UmyContactPage(),
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
    ];
