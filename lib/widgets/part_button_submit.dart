/// 主色提交按钮，对应源项目 `parts/partButtonSubmit.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/state/app_providers.dart';

class PartButtonSubmit extends ConsumerWidget {
  const PartButtonSubmit({
    super.key,
    required this.children,
    this.onPressed,
    this.disabled = false,
    this.loading = false,
    this.inShadow = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 50),
    this.height = 50,
    this.fullWidth = true,
  });

  final List<Widget> children;
  final VoidCallback? onPressed;
  final bool disabled;
  final bool loading;
  final bool inShadow;
  final EdgeInsets padding;
  final double height;

  /// 是否占满可用宽度（独立使用时为 true；放在 Row 内时应为 false）。
  final bool fullWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color mainColor = ref.watch(brandProvider).mainColor;
    final bool inactive = disabled || loading;
    return Opacity(
      opacity: inactive ? 0.3 : 1,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        height: height,
        child: FilledButton(
          onPressed: inactive ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            padding: padding,
            shape: const StadiumBorder(),
            elevation: inShadow ? 3 : 0,
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
