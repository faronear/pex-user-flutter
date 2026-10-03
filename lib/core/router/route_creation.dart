/// 创作 / NFT 域路由（Babelyx 启用）。
///
/// 迁移进行中：随页面落地逐个补充。当前为空，未迁移页面由兜底占位路由处理。
library;

import 'package:go_router/go_router.dart';

import '../../pages/menu_creation_page.dart';
import '../../pages/menu_creator_page.dart';
import '../../pages/mid_babely_page.dart';
import '../../pages/show_creation_update_page.dart';
import '../../pages/show_creation_page.dart';
import '../../pages/umy_collection_page.dart';
import '../../pages/user_resource_detail_page.dart';
import '../../pages/user_resource_page.dart';
import 'app_routes.dart';

/// 创作、创作者、市场、作品详情等。
List<RouteBase> creationRoutes() => <RouteBase>[
      GoRoute(
        path: AppRoutes.path(AppRoutes.menuCreation),
        name: AppRoutes.menuCreation,
        builder: (_, GoRouterState state) =>
            MenuCreationPage(tagNow: state.uri.queryParameters['tagnow'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.umyCollection),
        name: AppRoutes.umyCollection,
        builder: (_, _) => const UmyCollectionPage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.showCreation),
        name: AppRoutes.showCreation,
        builder: (_, GoRouterState state) =>
            ShowCreationPage(queryParameters: state.uri.queryParameters),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.menuCreator),
        name: AppRoutes.menuCreator,
        builder: (_, _) => const MenuCreatorPage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.midBabely),
        name: AppRoutes.midBabely,
        builder: (_, _) => const MidBabelyPage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.showCreationUpdate),
        name: AppRoutes.showCreationUpdate,
        builder: (_, GoRouterState state) =>
            ShowCreationUpdatePage(unid: state.uri.queryParameters['unid'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.userResource),
        name: AppRoutes.userResource,
        builder: (_, _) => const UserResourcePage(),
      ),
      GoRoute(
        path: AppRoutes.path(AppRoutes.userResourceDetail),
        name: AppRoutes.userResourceDetail,
        builder: (_, GoRouterState state) => UserResourceDetailPage(
          tagNow: state.uri.queryParameters['tagnow'] ?? '',
        ),
      ),
      // menuCreator / showCreator / menuMarket 待后续批次加入
    ];
