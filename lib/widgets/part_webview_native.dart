/// 原生端（iOS / Android / macOS / Windows）的内嵌网页：[PartWebview]。
///
/// 对应源项目 `pages/showWebview.vue` 的 `<web-view>`；由 `part_webview.dart`
/// 条件导入到 Web/原生两套实现之一，业务侧只 `import 'part_webview.dart'`。
library;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PartWebview extends StatefulWidget {
  const PartWebview({super.key, required this.url});

  final String url;

  @override
  State<PartWebview> createState() => _PartWebviewState();
}

class _PartWebviewState extends State<PartWebview> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(widget.url));

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
