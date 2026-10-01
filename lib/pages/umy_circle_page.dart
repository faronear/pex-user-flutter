/// 我的圈子（关注 / 粉丝 / 邀请），对应源项目 `pages/umyCircle.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/router/app_routes.dart';
import '../core/state/creator_provider.dart';
import '../core/state/envar_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/part_circle_list.dart';
import '../widgets/part_window_layout.dart';

class UmyCirclePage extends ConsumerStatefulWidget {
  const UmyCirclePage({super.key, this.tagNow = ''});

  /// 路由 `?tagnow=FOLLOWING|FOLLOWER|INVITEE`；非法值回落到第一个分类。
  final String tagNow;

  @override
  ConsumerState<UmyCirclePage> createState() => _UmyCirclePageState();
}

class _UmyCirclePageState extends ConsumerState<UmyCirclePage> {
  late CircleTag _tag = _tagOf(widget.tagNow);

  static CircleTag _tagOf(String key) => CircleTag.values.firstWhere(
        (CircleTag tag) => tag.key == key,
        orElse: () => CircleTag.following,
      );

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final Map<String, dynamic> dict = ref.watch(envarProvider).myCircleDict;
    final Map<String, dynamic> user = ref.watch(onlineUserProvider);

    // 源项目用 `Object.keys(myCircleDict)` 的顺序与键名；空则回落到枚举本身。
    final List<CircleTag> tags = <CircleTag>[
      for (final String key in dict.keys) _tagOf(key),
    ];
    final List<CircleTag> shown = tags.isEmpty ? CircleTag.values : tags;

    return PartWindowLayout(
      pageName: AppRoutes.umyCircle,
      child: Column(
        children: <Widget>[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: _SegmentBar(
              tags: shown,
              dict: dict,
              user: user,
              lang: lang,
              current: _tag,
              onPick: (CircleTag tag) => setState(() => _tag = tag),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: _tag == CircleTag.invitee
                    ? ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: PartCircleList(
                          key: ValueKey<CircleTag>(_tag),
                          tag: _tag,
                        ),
                      )
                    : PartCircleList(
                        key: ValueKey<CircleTag>(_tag),
                        tag: _tag,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 分类切换条，对应源项目 `uni-segmented-control`（`styleType="button"`）。
///
/// 源项目只在 `appkey === 'AKBABELY'` 时渲染它，这是当年 `myCircleDict` 仅 Babelyx 有值
/// 留下的判断；现在三个品牌的配置里都有该字典，故这里**一律渲染**（否则另外两个品牌
/// 会永远停在「关注」且无法切换）。
class _SegmentBar extends StatelessWidget {
  const _SegmentBar({
    required this.tags,
    required this.dict,
    required this.user,
    required this.lang,
    required this.current,
    required this.onPick,
  });

  final List<CircleTag> tags;
  final Map<String, dynamic> dict;
  final Map<String, dynamic> user;
  final String lang;
  final CircleTag current;
  final ValueChanged<CircleTag> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          for (final CircleTag tag in tags)
            Expanded(
              child: GestureDetector(
                onTap: () => onPick(tag),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: tag == current ? PexColors.blueMy : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        '${user[(dict[tag.key] as Map?)?['counter']] ?? 0}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: tag == current ? Colors.white : PexColors.grey3,
                        ),
                      ),
                      Text(
                        ll(lang, LangText.fromMap(dict[tag.key])),
                        style: TextStyle(
                          fontSize: 12,
                          color: tag == current ? Colors.white : PexColors.grey6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
