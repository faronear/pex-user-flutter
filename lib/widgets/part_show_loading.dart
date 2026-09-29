/// 加载中占位，对应源项目 `parts/partShowLoading.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import 'part_texts.dart';

class PartShowLoading extends ConsumerWidget {
  const PartShowLoading({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 12),
          Text(
            ll(lang, PartTexts.loading),
            style: const TextStyle(color: Color(0xFF909399)),
          ),
        ],
      ),
    );
  }
}
