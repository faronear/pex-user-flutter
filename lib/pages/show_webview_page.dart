/// 内嵌网页，对应源项目 `pages/showWebview.vue`。
///
/// 源项目用法（`wo.tt.open_url({ inWebview: true })`）：PC 一律 `window.open` 新标签页，
/// **其余平台**把 url/title 写进 `wo.ss.webviewUrl` / `webviewTitle` 再进本页。
/// Flutter 侧改为**路由参数**传递（`?url=&title=`），envar 里的同名字段作为兜底。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_routes.dart';
import '../core/state/envar_provider.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_webview.dart';
import '../widgets/part_window_layout.dart';

class ShowWebviewPage extends ConsumerWidget {
  const ShowWebviewPage({super.key, this.url = '', this.title = ''});

  /// 路由 `?url=`；为空时回落到 `envar.webviewUrl`。
  final String url;

  /// 路由 `?title=`；为空时回落到 `envar.webviewTitle`。
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Envar envar = ref.watch(envarProvider);
    final String urlNow = url.isNotEmpty ? url : envar.webviewUrl;
    final String titleNow = title.isNotEmpty ? title : envar.webviewTitle;

    // 源项目 `onShow`：没有地址就回首页（避免留下一个空白页）。
    if (urlNow.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.path(AppRoutes.homePortal));
      });
      return PartWindowLayout(
        pageName: AppRoutes.showWebview,
        child: const SizedBox.expand(),
      );
    }

    return PartWindowLayout(
      pageName: AppRoutes.showWebview,
      child: Column(
        children: <Widget>[
          PartNavibarPcFixed(title: LangText.fromMap(titleNow)),
          Expanded(child: PartWebview(url: urlNow)),
        ],
      ),
    );
  }
}

/// 在**内嵌网页页**里打开链接，对应源项目 `wo.tt.open_url_in_webview({ url, title })`。
///
/// - PC：源项目是 `window.open(url, '_blank')`（新标签页）→ 这里用外部浏览器打开；
/// - 其余平台：进 [ShowWebviewPage] 内嵌。
///
/// [title] 在此处按当前语言解析后作为普通字符串传给路由（源项目是把 LangText 存进 `wo.ss`）。
Future<void> openUrlInWebview(
  BuildContext context,
  WidgetRef ref, {
  required String url,
  LangText? title,
}) async {
  if (url.isEmpty) return;
  if (DeviceInfo.of(context).inPc) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }
  if (!context.mounted) return;
  final String titleText = title?.resolve(ref.read(languageProvider)) ?? '';
  context.push(
    '${AppRoutes.path(AppRoutes.showWebview)}'
    '?url=${Uri.encodeComponent(url)}'
    '&title=${Uri.encodeComponent(titleText)}',
  );
}
