/// 内嵌网页容器，对应源项目 `pages/showWebview.vue` 里的 `<web-view>`。
///
/// 两端实现不同，故用**条件导入**分流（Flutter Web 不支持 `webview_flutter`）：
/// - 原生（iOS/Android/macOS/Windows）：`webview_flutter`
/// - Web：`<iframe>`（`HtmlElementView`）
///
/// 对外统一暴露 [PartWebview]。
library;

export 'part_webview_native.dart'
    if (dart.library.js_interop) 'part_webview_web.dart';
