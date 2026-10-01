/// 「我的圈子」三个分类的名单，对应源项目 `parts/partCreatorMyFollowings.vue` /
/// `partCreatorMyFollowers.vue` / `partCreatorMyInvitees.vue`。
///
/// 三个源组件逻辑几乎一致（只有接口、时间字段、空态文案与「前往」按钮不同），
/// 因此这里合并成一个组件、由 [CircleTag] 区分，避免三份几乎重复的代码。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/api/user_api.dart';
import '../core/icons/pex_icon.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/router/app_routes.dart';
import '../core/state/app_providers.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/creator_provider.dart';
import '../core/state/envar_provider.dart';
import 'part_creator_card_list.dart';
import 'part_empty_list.dart';
import 'part_load_more.dart';
import 'part_show_loading.dart';
import 'part_texts.dart';
import 'part_user_list.dart';

const LangText _kEmptyFollowings = LangText(
  zhCN: '您还没有关注任何人\n请加油哦',
  enUS: 'You are not following anyone',
);

const LangText _kEmptyFollowers = LangText(
  zhCN: '您还没有被任何人关注\n请加油哦',
  enUS: 'You have not followed by anyone',
);

const LangText _kEmptyInvitees = LangText(
  zhCN: '您还没有邀请到小伙伴\n请加油哦',
  enUS: 'You have not invited anyone',
);

/// 源项目 `wo.pageSet['menuCreator'].i18nPageTitle`；
/// 该页名未进生成式 `core/appmeta/page_meta.dart`，故就近声明。
const LangText _kMenuCreator = LangText(
  zhCN: '遇见',
  enUS: 'Creators',
  deDE: 'Kreation',
  jaJP: '探索',
);

const LangText _kInviteNow = LangText(zhCN: '去邀请', enUS: 'Invite Now');

const LangText _kInviteMore = LangText(zhCN: '继续邀请', enUS: 'Invite More');

const LangText _kInvitedCount = LangText(
  zhCN: '我已成功邀请了 ',
  enUS: 'I have invited ',
);

const LangText _kInvitedCountUnit = LangText(zhCN: ' 人', enUS: ' users');

class PartCircleList extends ConsumerStatefulWidget {
  const PartCircleList({super.key, required this.tag});

  final CircleTag tag;

  @override
  ConsumerState<PartCircleList> createState() => _PartCircleListState();
}

class _PartCircleListState extends ConsumerState<PartCircleList> {
  LoadState _fresh = LoadState.loadFresh;
  LoadState _down = LoadState.loadUp;
  bool _ready = false;

  /// 源项目：关注/粉丝 12 条一页，邀请 10 条一页。
  int get _takeLimit => widget.tag == CircleTag.invitee ? 10 : 12;

  List<Map<String, dynamic>> get _list =>
      ref.read(creatorProvider).circleList(widget.tag);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 100), () async {
      await ref.read(appStartupProvider.notifier).waitAutologin();
      if (!mounted) return;
      // 源项目各自维护 `onceLoaded`：首次进页面才自动拉第一页，之后靠缓存。
      if (!ref.read(creatorProvider).circleLoaded.contains(widget.tag)) {
        await _getOlder();
      }
      if (mounted) setState(() => _ready = true);
    });
  }

  /// 拉列表（[beforeTime] 为空 = 最新一页；否则 = 向下翻页）。
  Future<Map<String, dynamic>> _call() {
    final UserApi api = ref.read(userApiProvider);
    final List<Map<String, dynamic>> list = _list;
    switch (widget.tag) {
      case CircleTag.following:
        return api.getMyFollowings(
          takeLimit: _takeLimit,
          beforeTime: list.isEmpty ? null : _intOf(list.last['followTimeUnix']),
        );
      case CircleTag.follower:
        return api.getMyFollowers(
          takeLimit: _takeLimit,
          beforeTime:
              list.isEmpty ? null : _intOf(list.last['followme_followTimeUnix']),
        );
      case CircleTag.invitee:
        // 该接口不支持 beforeTime 游标，用 skip 翻页（见 `user_api.getInviteeList`）。
        return api.getInviteeList(takeLimit: _takeLimit, skip: list.length);
    }
  }

  static int _intOf(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  String get _listKey => switch (widget.tag) {
        CircleTag.following => 'followingList',
        CircleTag.follower => 'followerList',
        CircleTag.invitee => 'inviteeList',
      };

  /// 「刷新」：重新拉最新一页并**覆盖**当前列表（源项目 `to_get_newest`）。
  Future<void> _getNewest() async {
    if (_fresh == LoadState.loading) return;
    setState(() => _fresh = LoadState.loading);
    final Map<String, dynamic> data = await _call();
    if (!mounted) return;
    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> list = _asList(data[_listKey]);
      ref.read(creatorProvider.notifier).setCircle(widget.tag, list);
      setState(() => _down =
          list.length < _takeLimit ? LoadState.noMore : LoadState.loadUp);
    } else {
      _toast(data['_msg']);
    }
    if (mounted) setState(() => _fresh = LoadState.loadFresh);
  }

  /// 「加载更多」：向下翻页并**追加**（源项目是整表替换，会丢掉已加载的页）。
  Future<void> _getOlder() async {
    if (_down == LoadState.loading) return;
    setState(() => _down = LoadState.loading);
    final Map<String, dynamic> data = await _call();
    if (!mounted) return;
    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> list = _asList(data[_listKey]);
      if (list.isNotEmpty) {
        ref.read(creatorProvider.notifier).appendCircle(widget.tag, list);
      }
      setState(() =>
          _down = list.length < _takeLimit ? LoadState.noMore : LoadState.loadUp);
      return;
    }
    _toast(data['_msg']);
    if (mounted) setState(() => _down = LoadState.loadUp);
  }

  static List<Map<String, dynamic>> _asList(Object? value) => value is List
      ? value
          .whereType<Map>()
          .map((Map item) => item.cast<String, dynamic>())
          .toList()
      : <Map<String, dynamic>>[];

  void _toast(Object? message) {
    final LangText text = LangText.fromMap(message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ll(ref.read(languageProvider), text.isEmpty ? PartTexts.systemDown : text),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final List<Map<String, dynamic>> list =
        ref.watch(creatorProvider.select((CreatorState state) => state.circleList(widget.tag)));

    if (!_ready) return const PartShowLoading();

    if (list.isEmpty) {
      return PartEmptyList(
        prompt: switch (widget.tag) {
          CircleTag.following => _kEmptyFollowings,
          CircleTag.follower => _kEmptyFollowers,
          CircleTag.invitee => _kEmptyInvitees,
        },
        aboveIcon: 'refresh',
        aboveAction: _getOlder,
        belowText: widget.tag == CircleTag.invitee ? _kInviteNow : _kMenuCreator,
        belowIcon: widget.tag == CircleTag.invitee ? 'gift' : 'staff',
        belowAction: () => widget.tag == CircleTag.invitee
            ? context.push(AppRoutes.path(AppRoutes.umyInvite))
            : context.go(AppRoutes.path(AppRoutes.menuCreator)),
      );
    }

    return Column(
      children: <Widget>[
        PartLoadMore(loadState: _fresh, onLoad: _getNewest),
        if (widget.tag == CircleTag.invitee)
          _inviteeSummary(lang)
        else
          PartCreatorCardList(creatorList: list),
        if (widget.tag == CircleTag.invitee)
          PartUserList(
            userList: list,
            timeKey: 'registerTimeUnix',
            timeIcon: 'auth',
            userType: 'INVITEE',
          ),
        PartLoadMore(loadState: _down, onLoad: _getOlder),
      ],
    );
  }

  /// 邀请名单的小结行：「我已成功邀请了 N 人」+「继续邀请」按钮。
  Widget _inviteeSummary(String lang) {
    final int count = _intOf(ref.watch(onlineUserProvider)['countInvitee']);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${_kInvitedCount.resolve(lang)}$count${_kInvitedCountUnit.resolve(lang)}',
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push(AppRoutes.path(AppRoutes.umyInvite)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ref.watch(brandProvider).mainColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: PexIcon.uni('gift', size: 16, color: Colors.white),
                  ),
                  Text(
                    _kInviteMore.resolve(lang),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
