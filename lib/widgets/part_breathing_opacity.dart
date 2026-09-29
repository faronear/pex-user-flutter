/// 呼吸闪烁（透明度动画），对应源项目 `parts/partBreathingOpacity.vue`。
library;

import 'package:flutter/material.dart';

class PartBreathingOpacity extends StatefulWidget {
  const PartBreathingOpacity({
    super.key,
    required this.child,
    this.isBreathing = true,
    this.minOpacity = 0.3,
    this.duration = const Duration(milliseconds: 1200),
  });

  final Widget child;
  final bool isBreathing;
  final double minOpacity;
  final Duration duration;

  @override
  State<PartBreathingOpacity> createState() => _PartBreathingOpacityState();
}

class _PartBreathingOpacityState extends State<PartBreathingOpacity>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant PartBreathingOpacity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBreathing != widget.isBreathing) _sync();
  }

  void _sync() {
    if (widget.isBreathing) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isBreathing) return widget.child;
    return FadeTransition(
      opacity: Tween<double>(begin: widget.minOpacity, end: 1).animate(_controller),
      child: widget.child,
    );
  }
}
