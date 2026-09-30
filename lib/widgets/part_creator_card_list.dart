/// 创作者卡片列表，对应源项目 `parts/partCreatorCardList.vue`。
///
/// 卡片 = 头像 + 昵称 + 统计（选集数 / 圈子数）+ 该创作者的少量作品卡片；
/// 若该用户已被本人屏蔽，则作品区显示「该用户已被您屏蔽」。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../brands/brand_config.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/state/app_providers.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../theme/app_theme.dart';
import 'part_creation_card_list.dart';
import 'part_user_list.dart';

const LangText _kBlocked = LangText(
  zhCN: '该用户已被您屏蔽',
  enUS: 'You have blocked this user',
);

class PartCreatorCardList extends ConsumerWidget {
  const PartCreatorCardList({super.key, required this.creatorList});

  final List<Map<String, dynamic>> creatorList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double width = MediaQuery.sizeOf(context).width;
    final double cardWidth =
        width >= 900 ? 345 : (width >= 600 ? width / 3 : width);

    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      children: <Widget>[
        for (final Map<String, dynamic> creator in creatorList)
          SizedBox(
            width: cardWidth,
            child: _CreatorCard(creator: creator),
          ),
      ],
    );
  }
}

class _CreatorCard extends ConsumerWidget {
  const _CreatorCard({required this.creator});

  final Map<String, dynamic> creator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BrandConfig brand = ref.watch(brandProvider);
    final bool inPc = MediaQuery.sizeOf(context).width >= 900;
    final bool blocked = creator['blockState']?.toString() == 'BLOCKED';
    final List<Map<String, dynamic>> collect =
        (creator['collectList'] as List?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];
    final String portrait = creator['portrait']?.toString() ?? '';

    return InkWell(
      onTap: () => context.push('/showCreator?unid=${creator['usid'] ?? ''}'),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: inPc ? 10 : 5, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x33000000), blurRadius: 15),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(color: Color(0x4D000000), blurRadius: 10),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: portrait.isEmpty
                        ? const Center(
                            child: PexIcon(null, size: 28),
                          )
                        : ServerImage(portrait, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          creator['nickname']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            color: PexColors.grey3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            _stat(
                              icon: PexIcons.uni(kUmyCollectionIcon),
                              color: brand.colorCollect,
                              text: '${countCreationPublic(creator)}',
                            ),
                            _stat(
                              icon: PexIcons.uni(kUmyCircleIcon),
                              color: brand.colorCircle,
                              text: '${_followerCount(creator)}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (blocked)
              SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    ll(ref.watch(languageProvider), _kBlocked),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
            else if (collect.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: PartCreationCardList(
                  pexList: collect,
                  inCreatorCard: true,
                  hideAvatar: true,
                  hideInfobar: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat({
    required PexGlyph? icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: PexIcon(icon, size: 16, color: color),
          ),
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  static int _followerCount(Map<String, dynamic> creator) {
    int of(String key) {
      final Object? value = creator[key];
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return of('countFollower') + of('countFollowing');
  }
}
