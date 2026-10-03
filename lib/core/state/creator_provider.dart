/// 创作者域状态，对应源项目 `wo.ss.Creator`。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 「我的圈子」的三个分类（源项目 `Creator.myCircleDict` 的键）。
enum CircleTag {
  following('FOLLOWING'),
  follower('FOLLOWER'),
  invitee('INVITEE');

  const CircleTag(this.key);

  final String key;
}

class CreatorState {
  const CreatorState({
    this.listAll = const <Map<String, dynamic>>[],
    this.onceLoaded = false,
    this.myFollowingList = const <Map<String, dynamic>>[],
    this.myFollowerList = const <Map<String, dynamic>>[],
    this.myInviteeList = const <Map<String, dynamic>>[],
    this.circleLoaded = const <CircleTag>{},
  });

  /// 探索页的创作者列表（源项目 `Creator.creatorListAll`）。
  final List<Map<String, dynamic>> listAll;

  final bool onceLoaded;

  /// 我关注的人（源项目 `Creator.myFollowingList`）。
  final List<Map<String, dynamic>> myFollowingList;

  /// 关注我的人（源项目 `Creator.myFollowerList`）。
  final List<Map<String, dynamic>> myFollowerList;

  /// 我邀请的人（源项目 `Creator.myInviteeList`）。
  final List<Map<String, dynamic>> myInviteeList;

  /// 哪些圈子分类已经首次加载过（源项目各自的 `onceLoaded`）。
  final Set<CircleTag> circleLoaded;

  List<Map<String, dynamic>> circleList(CircleTag tag) => switch (tag) {
        CircleTag.following => myFollowingList,
        CircleTag.follower => myFollowerList,
        CircleTag.invitee => myInviteeList,
      };

  CreatorState copyWith({
    List<Map<String, dynamic>>? listAll,
    bool? onceLoaded,
    List<Map<String, dynamic>>? myFollowingList,
    List<Map<String, dynamic>>? myFollowerList,
    List<Map<String, dynamic>>? myInviteeList,
    Set<CircleTag>? circleLoaded,
  }) =>
      CreatorState(
        listAll: listAll ?? this.listAll,
        onceLoaded: onceLoaded ?? this.onceLoaded,
        myFollowingList: myFollowingList ?? this.myFollowingList,
        myFollowerList: myFollowerList ?? this.myFollowerList,
        myInviteeList: myInviteeList ?? this.myInviteeList,
        circleLoaded: circleLoaded ?? this.circleLoaded,
      );
}

class CreatorNotifier extends Notifier<CreatorState> {
  @override
  CreatorState build() => const CreatorState();

  void setListAll(List<Map<String, dynamic>> list) =>
      state = state.copyWith(listAll: list, onceLoaded: true);

  /// 覆盖某个圈子分类的列表，并标记为已首次加载。
  ///
  /// `copyWith` 传 null 表示「保持原值」，因此这里只给命中的那个分类赋值。
  void setCircle(CircleTag tag, List<Map<String, dynamic>> list) {
    state = state.copyWith(
      myFollowingList: tag == CircleTag.following ? list : null,
      myFollowerList: tag == CircleTag.follower ? list : null,
      myInviteeList: tag == CircleTag.invitee ? list : null,
      circleLoaded: <CircleTag>{...state.circleLoaded, tag},
    );
  }

  void markCircleLoaded(CircleTag tag) =>
      state = state.copyWith(circleLoaded: <CircleTag>{...state.circleLoaded, tag});

  /// 在尾部追加一页（源项目是整表替换，这里改为追加 + 按 usid 去重，避免丢已加载页）。
  void appendCircle(CircleTag tag, List<Map<String, dynamic>> more) {
    final List<Map<String, dynamic>> current = state.circleList(tag);
    final Set<String> seen =
        current.map((Map<String, dynamic> item) => item['usid']?.toString() ?? '').toSet();
    final List<Map<String, dynamic>> merged = <Map<String, dynamic>>[
      ...current,
      ...more.where((Map<String, dynamic> item) => seen.add(item['usid']?.toString() ?? '')),
    ];
    setCircle(tag, merged);
  }

  /// 把某人的屏蔽状态同步到「关注 / 粉丝」两个名单（源项目 `to_block_user` 后的 forEach）。
  void setBlockStateInLists(String usid, String blockState) {
    List<Map<String, dynamic>> patch(List<Map<String, dynamic>> list) =>
        <Map<String, dynamic>>[
      for (final Map<String, dynamic> item in list)
        item['usid']?.toString() == usid
            ? <String, dynamic>{...item, 'blockState': blockState}
            : item,
    ];
    state = state.copyWith(
      myFollowingList: patch(state.myFollowingList),
      myFollowerList: patch(state.myFollowerList),
    );
  }

  /// 从探索页创作者名单里移除某人（源项目 `creatorListAll.splice`）。
  void removeFromListAll(String usid) => state = state.copyWith(
        listAll: <Map<String, dynamic>>[
          for (final Map<String, dynamic> item in state.listAll)
            if (item['usid']?.toString() != usid) item,
        ],
      );

  void reset() => state = const CreatorState();
}

final NotifierProvider<CreatorNotifier, CreatorState> creatorProvider =
    NotifierProvider<CreatorNotifier, CreatorState>(CreatorNotifier.new);
