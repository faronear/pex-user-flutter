/// 身份流程页面布局，对应源项目 `parts/partWindowLayoutIdent.vue`。
///
/// 结构：PC 顶栏 + 内容区（限宽 900，居中）+ PC 页脚；手机端显示 logo 与底部快捷条。
/// 内含两个守卫（对齐源项目 `mounted`）：
/// 1. 已登录 → 跳落地页；2. 生产环境且无 commid 且非 identBegin → 跳回 identBegin。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/responsive/device_info.dart';
import '../core/appmeta/app_env.dart';
import '../core/i18n/lang_text.dart';
import '../core/router/app_router.dart';
import '../core/state/app_providers.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../core/state/ident_provider.dart';
import '../theme/app_theme.dart';
import 'part_lang_table.dart';
import 'part_navibar_pc_fixed.dart';
import 'part_shortcuts.dart';
import 'part_show_loading.dart';
import 'part_window_footer.dart';
import 'part_window_header.dart';

class PartWindowLayoutIdent extends ConsumerWidget {
  const PartWindowLayoutIdent({
    super.key,
    required this.child,
    this.pageName = '',
    this.navTitle,
  });

  final Widget child;
  final String pageName;

  /// PC 二级导航栏标题（源项目各页面 `data.i18nPageTitle`）。
  final LangText? navTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStartupState startup = ref.watch(appStartupProvider);
    final DeviceInfo device = DeviceInfo.of(context);
    final bool online = ref.watch(isOnlineProvider);
    final String commid = ref.watch(identProvider).commid;
    final String currentPath = GoRouterState.of(context).uri.path;
    final String appLandPage = ref.watch(brandProvider).appLandPage;

    if (startup.afterAutologging) {
      if (online) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go(AppRoutes.path(appLandPage));
        });
      } else if (kInProd &&
          commid.isEmpty &&
          currentPath != AppRoutes.path(AppRoutes.identBegin)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go(AppRoutes.path(AppRoutes.identBegin));
        });
      }
    }

    return Scaffold(
      backgroundColor: PexColors.bg,
      body: Column(
        children: <Widget>[
          PartWindowHeader(pageName: pageName),
          Expanded(
            child: !startup.afterAutologging
                ? const PartShowLoading()
                : SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: device.inPc ? 40 : 0),
                        if (device.inPc)
                          Container(
                            color: PexColors.bg,
                            child: PartNavibarPcFixed(
                              pageName: pageName,
                              title: navTitle,
                            ),
                          ),
                        if (!device.inPc) _buildLogo(ref),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 900),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: child,
                            ),
                          ),
                        ),
                        if (!device.inPc) _buildBottomBar(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
          PartWindowFooter(),
        ],
      ),
    );
  }

  Widget _buildLogo(WidgetRef ref) {
    final String logo = ref.watch(brandProvider).logoAsset;
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        logo,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(Icons.apps, color: Color(0xFF909399)),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          const PartShortcuts(color: Color(0xFF909399)),
          const SizedBox(width: 10),
          const PartLangTable(color: Color(0xFF909399)),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
