/// 倒计时文字，对应源项目 `parts/partCountdown.vue`。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import 'part_texts.dart';

class PartCountdown extends ConsumerStatefulWidget {
  const PartCountdown({
    super.key,
    required this.expireAt,
    this.textPrefix,
    this.textSuffix = const LangText.from(''),
  });

  /// 失效时间（毫秒时间戳）。
  final int expireAt;
  final LangText? textPrefix;
  final LangText textSuffix;

  @override
  ConsumerState<PartCountdown> createState() => _PartCountdownState();
}

class _PartCountdownState extends ConsumerState<PartCountdown> {
  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant PartCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expireAt != widget.expireAt) _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    final int remain = ((widget.expireAt - DateTime.now().millisecondsSinceEpoch) / 1000).floor();
    setState(() => _remaining = remain > 0 ? remain : 0);
    if (_remaining <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) return;
      setState(() {
        if (_remaining > 0) {
          _remaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final LangText prefix = widget.textPrefix ?? PartTexts.clockRemaining;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 35, 10, 10),
      child: Center(
        child: Text(
          '${ll(lang, prefix)} $_remaining ${ll(lang, widget.textSuffix)}'.trim(),
          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
      ),
    );
  }
}
