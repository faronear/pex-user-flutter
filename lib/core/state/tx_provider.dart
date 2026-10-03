/// 资金域会话状态，对应源项目 `wo.ss.Tx`。
///
/// 源项目把「当前选中的收支分类」`myTxTagNow` 与每个分类各自的 `myTxList`（含 `onceLoaded`）
/// 都挂在 `Tx.myTxDict[tag]` 上；这里等价地拆成「当前标签 + 标签 → 列表 + 已加载集合」。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

class TxState {
  const TxState({
    this.tagNow = '',
    this.lists = const <String, List<Map<String, dynamic>>>{},
    this.loaded = const <String>{},
  });

  /// 当前选中的收支分类（源项目 `Tx.myTxTagNow`）。
  final String tagNow;

  /// 各分类的已加载列表。
  final Map<String, List<Map<String, dynamic>>> lists;

  /// 哪些分类已首次加载过（源项目各 `myTxList.onceLoaded`）。
  final Set<String> loaded;

  List<Map<String, dynamic>> listOf(String tag) =>
      lists[tag] ?? const <Map<String, dynamic>>[];

  TxState copyWith({
    String? tagNow,
    Map<String, List<Map<String, dynamic>>>? lists,
    Set<String>? loaded,
  }) =>
      TxState(
        tagNow: tagNow ?? this.tagNow,
        lists: lists ?? this.lists,
        loaded: loaded ?? this.loaded,
      );
}

final NotifierProvider<TxNotifier, TxState> txProvider =
    NotifierProvider<TxNotifier, TxState>(TxNotifier.new);

class TxNotifier extends Notifier<TxState> {
  @override
  TxState build() => const TxState();

  void setTagNow(String tag) => state = state.copyWith(tagNow: tag);

  void setList(String tag, List<Map<String, dynamic>> list) => state =
      state.copyWith(
        lists: <String, List<Map<String, dynamic>>>{...state.lists, tag: list},
        loaded: <String>{...state.loaded, tag},
      );

  /// 在尾部追加一页并去重（源项目是整表替换，会丢掉已加载的页）。
  void appendList(String tag, List<Map<String, dynamic>> more) {
    final List<Map<String, dynamic>> current = state.listOf(tag);
    final Set<String> seen = current
        .map((Map<String, dynamic> tx) => tx['txUuid']?.toString() ?? '')
        .toSet();
    setList(tag, <Map<String, dynamic>>[
      ...current,
      ...more.where((Map<String, dynamic> tx) =>
          seen.add(tx['txUuid']?.toString() ?? '')),
    ]);
  }

  void reset() => state = const TxState();
}
