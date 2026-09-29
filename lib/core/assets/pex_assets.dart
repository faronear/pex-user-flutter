/// 资源路径解析：把源项目的 `/static/xxx` 映射到 Flutter 打包资源 `assets/static/xxx`。
///
/// 源项目里 `/static/*` 在 Web 由站点托管、在 App 由包内资源提供；迁移后统一打包进 assets。
library;

import 'package:flutter/material.dart';

/// 源项目资源路径 → Flutter asset 路径（http(s) 原样返回）。
String pexAssetPath(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final String trimmed = path.startsWith('/') ? path.substring(1) : path;
  if (trimmed.startsWith('static/')) return 'assets/$trimmed';
  return trimmed;
}

/// 按源项目路径渲染图片（自动区分网络图与打包资源）。
class PexImage extends StatelessWidget {
  const PexImage(this.path, {super.key, this.fit = BoxFit.contain, this.width, this.height});

  final String? path;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final String resolved = pexAssetPath(path);
    if (resolved.isEmpty) return SizedBox(width: width, height: height);
    if (resolved.startsWith('http')) {
      return Image.network(
        resolved,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => SizedBox(width: width, height: height),
      );
    }
    return Image.asset(
      resolved,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, _, _) => SizedBox(width: width, height: height),
    );
  }
}
