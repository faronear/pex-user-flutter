/// 6 位验证码输入框（盒子样式），替代源项目的第三方组件 `myp-one`（mode="box"）。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PartPasscodeInput extends StatefulWidget {
  const PartPasscodeInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.onFinish,
    this.enabled = true,
    this.length = 6,
    this.autoFocus = false,
  });

  /// 父级持有的当前值（受控）。
  final String value;
  final ValueChanged<String> onChanged;

  /// 输满时回调（源项目 `@finish`）。
  final VoidCallback? onFinish;

  final bool enabled;
  final int length;
  final bool autoFocus;

  @override
  State<PartPasscodeInput> createState() => _PartPasscodeInputState();
}

class _PartPasscodeInputState extends State<PartPasscodeInput> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);
  late final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void didUpdateWidget(covariant PartPasscodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String text) {
    widget.onChanged(text);
    if (text.length >= widget.length) widget.onFinish?.call();
  }

  @override
  Widget build(BuildContext context) {
    final String value = widget.value;
    return Stack(
      children: <Widget>[
        Row(
          children: <Widget>[
            for (int i = 0; i < widget.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildBox(
                    context,
                    char: i < value.length ? value[i] : '',
                    active: _focused && i == value.length.clamp(0, widget.length - 1),
                  ),
                ),
              ),
          ],
        ),
        // 透明输入层：负责接收键盘输入
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              autofocus: widget.autoFocus,
              showCursor: false,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: _handleChanged,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBox(BuildContext context, {required String char, required bool active}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active ? Theme.of(context).colorScheme.primary : const Color(0xFFE5E5E5),
          width: active ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      ),
    );
  }
}
