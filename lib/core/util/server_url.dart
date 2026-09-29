/// 资源 URL 组装，对应源项目 `wo.tt.make_server_url`。
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/envar_provider.dart';

/// 规则（对齐源项目实现）：
/// - 完整 http(s) URL → 原样返回；
/// - `/static/...` → 打包资源路径（`assets/static/...`）；
/// - 纯字母数字（IPFS CID）→ `${envar.ipfsLens}/cid`；
/// - 其余相对路径 → `${envar.servUrl}/path`。
String makeServerUrl(String? path, Envar envar) {
  final String route = (path ?? '').replaceAll('\\', '/');
  if (route.isEmpty) return '';
  if (RegExp(r'^https?://').hasMatch(route)) return route;
  if (route.startsWith('/static/')) return 'assets$route';
  final String trimmed = route.replaceFirst(RegExp(r'^/'), '');
  if (RegExp(r'^[0-9a-zA-Z]+$').hasMatch(trimmed)) {
    final String ipfs = envar.raw['ipfsLens']?.toString() ?? '';
    if (ipfs.isNotEmpty) {
      return '${ipfs.replaceFirst(RegExp(r'/$'), '')}/$trimmed';
    }
  }
  final String servUrl = envar.servUrl;
  if (servUrl.isNotEmpty) {
    return '${servUrl.replaceFirst(RegExp(r'/$'), '')}/$trimmed';
  }
  return trimmed;
}

/// 按 [makeServerUrl] 渲染图片（网络图或打包资源）。
String imageUrlOf(String? path, Envar envar) => makeServerUrl(path, envar);

/// 按 [makeServerUrl] 渲染图片的组件（自动区分网络与打包资源）。
class ServerImage extends ConsumerWidget {
  const ServerImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder = const SizedBox.shrink(),
  });

  final String? path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String url = makeServerUrl(path, ref.watch(envarProvider));
    if (url.isEmpty) return placeholder;
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return placeholder;
  }
}
