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
import '../../pages/umy_kyc_page.dart';
import '../../pages/umy_account_commid_new_page.dart';
import '../../pages/umy_account_commid_page.dart';
import '../../pages/umy_account_page.dart';
import '../../pages/umy_account_password_page.dart';
import '../../pages/umy_account_terminate_page.dart';
import '../../pages/umy_circle_page.dart';
import '../../pages/umy_config_page.dart';
import '../../pages/umy_invite_list_page.dart';
import '../../pages/umy_invite_page.dart';
import '../../pages/umy_mia_detail_page.dart';
import '../../pages/umy_mia_page.dart';
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
      // 账号安全闭环（三品牌共用）：账号 / 改密码 / 验证当前账号 / 设置新账号 / 销毁账号。
      GoRoute(
        path: AppRoutes.path(AppRoutes.umyAccount),
        name: AppRoutes.umyAccount,
        builder: (_, _) => const UmyAccountPage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.umyAccountPassword),
        name: AppRoutes.umyAccountPassword,
        builder: (_, _) => const UmyAccountPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.umyAccountCommid),
        name: AppRoutes.umyAccountCommid,
        builder: (_, _) => const UmyAccountCommidPage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.umyAccountCommidNew),
        name: AppRoutes.umyAccountCommidNew,
        builder: (_, _) => const UmyAccountCommidNewPage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.umyAccountTerminate),
        name: AppRoutes.umyAccountTerminate,
        builder: (_, _) => const UmyAccountTerminatePage(),
      ),
      // 「邀请朋友」及其名单页（三品牌共用的账户域页面）。
      GoRoute(
        path: AppRoutes.path(AppRoutes.umyInvite),
        name: AppRoutes.umyInvite,
        builder: (_, _) => const UmyInvitePage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.umyInviteList),
        name: AppRoutes.umyInviteList,
        builder: (_, _) => const UmyInviteListPage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.umyCircle),
        name: AppRoutes.umyCircle,
        builder: (_, GoRouterState state) =>
            UmyCirclePage(tagNow: state.uri.queryParameters['tagnow'] ?? ''),
      ),
      // 实名认证（三品牌共用）。
      GoRoute(
        path: AppRoutes.path(AppRoutes.umyKyc),
        name: AppRoutes.umyKyc,
        builder: (_, _) => const UmyKycPage(),
      ),
      // 消息域（三品牌共用）：消息列表 + 消息详情（含回复）。
      GoRoute(
        path: AppRoutes.path(AppRoutes.umyMia),
        name: AppRoutes.umyMia,
        builder: (_, _) => const UmyMiaPage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.umyMiaDetail),
        name: AppRoutes.umyMiaDetail,
        builder: (_, GoRouterState state) => UmyMiaDetailPage(
          miaUuid: state.uri.queryParameters['miaUuid'] ?? '',
        ),
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
