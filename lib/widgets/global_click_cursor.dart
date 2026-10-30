/// 全局手型光标（桌面版与 Web 版共用）。
///
/// Flutter 桌面/Web 默认不给裸 `GestureDetector` 显示手型光标，而本项目大量
/// 可点击区域用裸 GestureDetector 包裹。此组件挂在 `MaterialApp.router` 的
/// `builder` 最外层，鼠标悬停时对当前位置对内容层做 hit-test：
/// - 命中带手势的组件（onTap / onLongPress 的 GestureDetector、InkWell、
///   Material 按钮等，特征是存在 `onPointerDown` 监听）→ 手型光标；
/// - 其他情况设为 defer，让位给下层 MouseRegion 自己声明的光标
///   （输入框 I 型、disabled 控件等），没有声明则显示默认箭头。
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 判定「可点击」的节流距离：鼠标移动小于此距离不重复 hit-test。
const double _kMinMoveDistance = 2.0;

class GlobalClickCursor extends StatefulWidget {
  const GlobalClickCursor({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalClickCursor> createState() => _GlobalClickCursorState();
}

class _GlobalClickCursorState extends State<GlobalClickCursor> {
  Offset? _lastChecked;

  /// 内容层的 key，hit-test 以它为根（它是顶层监听层的兄弟节点）。
  final GlobalKey _contentKey = GlobalKey();

  /// 顶层监听层的 key，通过改其 RenderMouseRegion.cursor 应用结果。
  final GlobalKey _cursorKey = GlobalKey();

  void _updateCursor(Offset position) {
    if (_lastChecked != null &&
        (_lastChecked! - position).distance < _kMinMoveDistance) {
      return;
    }
    _lastChecked = position;

    // 路由切换/弹窗等时机下内容层可能正被重建或不在树中，此时放弃本次
    // 判定（defer 由系统接管），避免对失活元素操作抛异常导致红屏。
    final BuildContext? contentContext = _contentKey.currentContext;
    if (contentContext == null || !contentContext.mounted) {
      _applyCursor(MouseCursor.defer);
      return;
    }
    final RenderObject? rootRender = contentContext.findRenderObject();
    if (rootRender is! RenderBox || !rootRender.attached) {
      _applyCursor(MouseCursor.defer);
      return;
    }
    try {
      _judgeAndApply(position, rootRender);
    } catch (_) {
      // 布局锁定期间（页面切换瞬间）hit-test 可能抛出，静默跳过本次。
      _applyCursor(MouseCursor.defer);
    }
  }

  void _judgeAndApply(Offset position, RenderBox rootRender) {
    final BoxHitTestResult result = BoxHitTestResult();
    if (!rootRender.hitTest(
      result,
      position: rootRender.globalToLocal(position),
    )) {
      _applyCursor(MouseCursor.defer);
      return;
    }

    bool clickable = false;
    for (final HitTestEntry entry in result.path) {
      final Object target = entry.target;
      // 统一规则：凡注册了 tap/longPress 语义动作的渲染对象即可点击
      // （GestureDetector、InkWell、TextButton、ListTile、菜单项、弹窗按钮
      // 等全部经 Semantics(onTap…) 走这条路）。滚动/拖拽/输入框不注册
      // tap 动作，自然排除。
      if (target is RenderSemanticsAnnotations &&
          (target.properties.onTap != null ||
              target.properties.onLongPress != null)) {
        clickable = true;
        break;
      }
      // GestureDetector 的语义由 RenderSemanticsGestureHandler 提供。
      if (target is RenderSemanticsGestureHandler &&
          (target.onTap != null || target.onLongPress != null)) {
        clickable = true;
        break;
      }
    }
    _applyCursor(clickable ? SystemMouseCursors.click : MouseCursor.defer);
  }

  /// 改 RenderMouseRegion.cursor 会触发 MouseTracker 重新计算，立即生效；
  /// 设为 defer 时由下层注解（输入框等）或系统默认接管。
  void _applyCursor(MouseCursor cursor) {
    final RenderObject? render = _cursorKey.currentContext?.findRenderObject();
    if (render is RenderMouseRegion && render.cursor != cursor) {
      render.cursor = cursor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        KeyedSubtree(key: _contentKey, child: widget.child),
        Positioned.fill(
          child: MouseRegion(
            key: _cursorKey,
            opaque: false,
            hitTestBehavior: HitTestBehavior.translucent,
            cursor: MouseCursor.defer,
            onHover: (PointerHoverEvent event) => _updateCursor(event.position),
            onEnter: (PointerEnterEvent event) => _updateCursor(event.position),
          ),
        ),
      ],
    );
  }
}
