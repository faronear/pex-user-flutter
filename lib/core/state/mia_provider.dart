/// 消息域会话状态，对应源项目 `wo.ss.Mia`。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

class MiaState {
  const MiaState({
    this.myMiaList = const <Map<String, dynamic>>[],
    this.onceLoaded = false,
    this.miaNow = const <String, dynamic>{},
  });

  /// 我的消息列表（源项目 `Mia.myMiaList`）。
  final List<Map<String, dynamic>> myMiaList;

  /// 是否已首次加载过（源项目 `Mia.myMiaList.onceLoaded`）。
  final bool onceLoaded;

  /// 当前查看的消息（源项目 `Mia.miaNow`）：
  /// 从列表进详情页时先带过来，详情接口返回后再合并。
  final Map<String, dynamic> miaNow;

  MiaState copyWith({
    List<Map<String, dynamic>>? myMiaList,
    bool? onceLoaded,
    Map<String, dynamic>? miaNow,
  }) =>
      MiaState(
        myMiaList: myMiaList ?? this.myMiaList,
        onceLoaded: onceLoaded ?? this.onceLoaded,
        miaNow: miaNow ?? this.miaNow,
      );
}

final NotifierProvider<MiaNotifier, MiaState> miaProvider =
    NotifierProvider<MiaNotifier, MiaState>(MiaNotifier.new);

class MiaNotifier extends Notifier<MiaState> {
  @override
  MiaState build() => const MiaState();

  void setList(List<Map<String, dynamic>> list) =>
      state = state.copyWith(myMiaList: list, onceLoaded: true);

  /// 在尾部追加一页并去重（源项目是整表替换，会丢掉已加载的页）。
  void appendList(List<Map<String, dynamic>> more) {
    final Set<String> seen = state.myMiaList
        .map((Map<String, dynamic> mia) => mia['miaUuid']?.toString() ?? '')
        .toSet();
    setList(<Map<String, dynamic>>[
      ...state.myMiaList,
      ...more.where((Map<String, dynamic> mia) =>
          seen.add(mia['miaUuid']?.toString() ?? '')),
    ]);
  }

  /// 把列表里的某条消息就地合并（详情页标记已读后，列表上的红点要跟着消失）。
  void mergeInList(Map<String, dynamic> mia) {
    final String uuid = mia['miaUuid']?.toString() ?? '';
    if (uuid.isEmpty) return;
    setList(<Map<String, dynamic>>[
      for (final Map<String, dynamic> item in state.myMiaList)
        item['miaUuid']?.toString() == uuid
            ? <String, dynamic>{...item, ...mia}
            : item,
    ]);
  }

  void setMiaNow(Map<String, dynamic> mia) =>
      state = state.copyWith(miaNow: mia);

  void mergeMiaNow(Map<String, dynamic> mia) =>
      state = state.copyWith(miaNow: <String, dynamic>{...state.miaNow, ...mia});

  void reset() => state = const MiaState();
}
