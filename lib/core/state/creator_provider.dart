/// 创作者域状态，对应源项目 `wo.ss.Creator`。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreatorState {
  const CreatorState({
    this.listAll = const <Map<String, dynamic>>[],
    this.onceLoaded = false,
  });

  /// 探索页的创作者列表（源项目 `Creator.creatorListAll`）。
  final List<Map<String, dynamic>> listAll;

  final bool onceLoaded;

  CreatorState copyWith({
    List<Map<String, dynamic>>? listAll,
    bool? onceLoaded,
  }) =>
      CreatorState(
        listAll: listAll ?? this.listAll,
        onceLoaded: onceLoaded ?? this.onceLoaded,
      );
}

class CreatorNotifier extends Notifier<CreatorState> {
  @override
  CreatorState build() => const CreatorState();

  void setListAll(List<Map<String, dynamic>> list) =>
      state = state.copyWith(listAll: list, onceLoaded: true);

  void reset() => state = const CreatorState();
}

final NotifierProvider<CreatorNotifier, CreatorState> creatorProvider =
    NotifierProvider<CreatorNotifier, CreatorState>(CreatorNotifier.new);
