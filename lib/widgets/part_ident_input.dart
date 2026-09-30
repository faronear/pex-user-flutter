/// 身份流程输入框，对应源项目 `uni-easyinput`（ident 风格：白底、大字号、宽字距）。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';

class PartIdentInput extends ConsumerWidget {
  const PartIdentInput({
    super.key,
    required this.controller,
    this.placeholder,
    this.obscure = false,
    this.enabled = true,
    this.focusNode,
    this.onSubmitted,
    this.textInputAction = TextInputAction.done,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.autofocus = false,
    this.hasError = false,
    this.textAlign = TextAlign.start,
    this.fontSize = 20,
  });

  final TextEditingController controller;
  final LangText? placeholder;
  final bool obscure;
  final bool enabled;
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  /// 进入页面即聚焦（对应源项目 `uni-easyinput` 的 `:focus` 属性）。
  final bool autofocus;
  /// 为 true 时边框变红（对应源项目 `:errorMessage` 控制输入框变红）。
  final bool hasError;
  final TextAlign textAlign;
  final double fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: hasError ? const Color(0xFFDD6161) : const Color(0xFFE5E5E5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        enabled: enabled,
        obscureText: obscure,
        textAlign: textAlign,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted?.call(),
        style: TextStyle(fontSize: fontSize, letterSpacing: 4),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: placeholder == null ? null : ll(lang, placeholder!),
          hintStyle: const TextStyle(
            fontSize: 18,
            color: Color(0xFFAAAAAA),
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
