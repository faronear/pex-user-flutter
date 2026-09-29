/// 页面基础画布，对应源项目 `parts/partWindow.vue`。
///
/// 提供全屏容器 + 可选背景（图片/颜色）+ 居中限宽内容区。
library;

import 'package:flutter/material.dart';

class PartWindow extends StatelessWidget {
  const PartWindow({
    super.key,
    required this.child,
    this.backgroundImage,
    this.backgroundColor,
    this.maxWidth = 900,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;

  /// 背景图资源路径（如品牌门户图）。
  final String? backgroundImage;

  final Color? backgroundColor;

  /// 内容区最大宽度（对应源项目 `wocWindowPage900 / 1024 / 1600` 等）。
  final double maxWidth;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (backgroundColor != null)
          Positioned.fill(child: ColoredBox(color: backgroundColor!)),
        if (backgroundImage != null)
          Positioned.fill(
            child: Image.asset(
              backgroundImage!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ],
    );
  }
}
