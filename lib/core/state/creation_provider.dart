/// 创作域状态，对应源项目 `wo.ss.Creation`。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/creation_api.dart';

class CreationState {
  const CreationState({
    this.listAll = const <Map<String, dynamic>>[],
    this.collections = const <CreationRole, List<Map<String, dynamic>>>{},
    this.onceLoaded = const <CreationRole>{},
    this.listAllLoaded = false,
  });

  /// 探索页「全部创作品」。
  final List<Map<String, dynamic>> listAll;

  /// 各身份的「我的收藏」列表。
  final Map<CreationRole, List<Map<String, dynamic>>> collections;

  /// 已首次加载过的身份（对应源项目各 `myCollectionAs*.onceLoaded`）。
  final Set<CreationRole> onceLoaded;

  /// 探索页是否已加载过。
  final bool listAllLoaded;

  List<Map<String, dynamic>> collectionOf(CreationRole role) =>
      collections[role] ?? const <Map<String, dynamic>>[];

  CreationState copyWith({
    List<Map<String, dynamic>>? listAll,
    Map<CreationRole, List<Map<String, dynamic>>>? collections,
    Set<CreationRole>? onceLoaded,
    bool? listAllLoaded,
  }) =>
      CreationState(
        listAll: listAll ?? this.listAll,
        collections: collections ?? this.collections,
        onceLoaded: onceLoaded ?? this.onceLoaded,
        listAllLoaded: listAllLoaded ?? this.listAllLoaded,
      );
}

class CreationNotifier extends Notifier<CreationState> {
  @override
  CreationState build() => const CreationState();

  void setListAll(List<Map<String, dynamic>> list) =>
      state = state.copyWith(listAll: list, listAllLoaded: true);

  void setCollection(CreationRole role, List<Map<String, dynamic>> list) {
    state = state.copyWith(
      collections: <CreationRole, List<Map<String, dynamic>>>{
        ...state.collections,
        role: list,
      },
      onceLoaded: <CreationRole>{...state.onceLoaded, role},
    );
  }

  void reset() => state = const CreationState();
}

final NotifierProvider<CreationNotifier, CreationState> creationProvider =
    NotifierProvider<CreationNotifier, CreationState>(CreationNotifier.new);
