/// 反馈文字行，对应源项目 `.wocFeedback`（`isBad` 红 / `isGood` 绿）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';

class PartFeedback extends ConsumerWidget {
  const PartFeedback({
    super.key,
    this.bad,
    this.good,
    this.atCenter = true,
  });

  final LangText? bad;
  final LangText? good;
  final bool atCenter;

  static const Color _red = Color(0xFFDD6161);
  static const Color _green = Color(0xFF19BE6B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final LangText? text = (bad != null && !bad!.isEmpty) ? bad : good;
    return SizedBox(
      height: 22,
      child: Align(
        alignment: atCenter ? Alignment.center : Alignment.centerLeft,
        child: Text(
          text == null ? '' : ll(lang, text),
          textAlign: atCenter ? TextAlign.center : TextAlign.left,
          maxLines: 2,
          style: TextStyle(
            fontSize: 12,
            height: 1.3,
            color: bad != null ? _red : _green,
          ),
        ),
      ),
    );
  }
}
