/// 发送验证码按钮，对应源项目 `parts/partButtonPasscode.vue`（橙色）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/icons/pex_icon.dart';
import 'part_texts.dart';

class PartButtonPasscode extends ConsumerWidget {
  const PartButtonPasscode({
    super.key,
    this.onPressed,
    this.disabled = false,
    this.loading = false,
    this.remainingSeconds = 0,
  });

  final VoidCallback? onPressed;
  final bool disabled;
  final bool loading;
  final int remainingSeconds;

  static const Color _orange = Color(0xFFF29100);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final bool inactive = disabled || loading;
    return Opacity(
      opacity: disabled ? 0.3 : 1,
      child: SizedBox(
        height: 50,
        child: FilledButton(
          onPressed: inactive ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (!loading)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PexIcon.uni('paperplane', size: 22, color: Colors.white),
                ),
              Text(
                '${ll(lang, PartTexts.sendPasscode)}'
                '${remainingSeconds > 0 ? ' $remainingSeconds' : ''}',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
