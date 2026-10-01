/// 加载更多 / 列表状态条，对应源项目 `parts/partLoadMore.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../theme/app_theme.dart';

/// 列表加载状态（与源项目取值一致）。
enum LoadState { loadUp, loadFresh, loading, noMore, frozen }

const LangText _kLoadMore = LangText(
  zhCN: '加载更多',
  enUS: 'Load more',
  jaJP: 'もっと読み込む',
);

const LangText _kNoMore = LangText(zhCN: '没有更多了', enUS: 'No more', jaJP: 'これ以上ありません');

/// 顶部「刷新」条（源项目 `loadFresh` 状态）。
const LangText _kReload = LangText(
  zhCN: '刷新',
  enUS: 'Reload',
  deDE: 'Neu laden',
  jaJP: '再読み込み',
);

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
      case LoadState.loadFresh:
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: TextButton.icon(
              onPressed: onLoad,
              icon: PexIcon.uni('refreshempty', size: 16, color: PexColors.blueMy),
              label: Text(
                ll(lang, _kReload),
                style: const TextStyle(color: PexColors.blueMy, fontSize: 13),
              ),
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
