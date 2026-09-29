/// 加载更多 / 列表状态条，对应源项目 `parts/partLoadMore.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';

/// 列表加载状态（与源项目取值一致）。
enum LoadState { loadUp, loading, noMore, frozen }

const LangText _kLoadMore = LangText(
  zhCN: '加载更多',
  enUS: 'Load more',
  jaJP: 'もっと読み込む',
);

const LangText _kNoMore = LangText(zhCN: '没有更多了', enUS: 'No more', jaJP: 'これ以上ありません');

class PartLoadMore extends ConsumerWidget {
  const PartLoadMore({
    super.key,
    this.loadState = LoadState.noMore,
    this.onLoad,
  });

  final LoadState loadState;
  final VoidCallback? onLoad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    switch (loadState) {
      case LoadState.frozen:
        return const SizedBox.shrink();
      case LoadState.loading:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      case LoadState.loadUp:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: TextButton(
              onPressed: onLoad,
              child: Text(ll(lang, _kLoadMore)),
            ),
          ),
        );
      case LoadState.noMore:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Text(
              ll(lang, _kNoMore),
              style: const TextStyle(fontSize: 12, color: Color(0xFF909399)),
            ),
          ),
        );
    }
  }
}
