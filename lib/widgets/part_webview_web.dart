/// Web 端的内嵌网页：[PartWebview]（`<iframe>`）。
///
/// 对应源项目 `pages/showWebview.vue` 的 `<web-view>`；由 `part_webview.dart`
/// 条件导入到 Web/原生两套实现之一，业务侧只 `import 'part_webview.dart'`。
library;

import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class PartWebview extends StatefulWidget {
  const PartWebview({super.key, required this.url});

  final String url;

  @override
  State<PartWebview> createState() => _PartWebviewState();
}

class _PartWebviewState extends State<PartWebview> {
  /// 每个实例一个 viewType，避免同页多实例互相覆盖。
  late final String _viewType = 'pex-webview-${identityHashCode(this)}';

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final web.HTMLIFrameElement iframe = web.HTMLIFrameElement()
        ..src = widget.url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
