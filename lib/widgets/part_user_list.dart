/// 用户名单，对应源项目 `parts/partUserList.vue`。
///
/// 用于解密者 / 持有者 / 赞赏者 / 点赞者名单：头像 + 昵称 + 时间（可选）+ 统计（可关）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../brands/brand_config.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/state/app_providers.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../theme/app_theme.dart';

/// 源项目 `wo.pageSet['umyCollection']` / `['umyCircle']` 的 `gotoIconType`。
///
/// 这两页在 `pages.json` 里受 `!ifA` 控制（非 Agidin），故未进生成式
/// `core/appmeta/page_meta.dart`，此处就近声明。
const String kUmyCollectionIcon = 'images';

const String kUmyCircleIcon = 'staff';

class PartUserList extends ConsumerWidget {
  const PartUserList({
    super.key,
    required this.userList,
    this.timeKey = '',
    this.timeIcon = '',
    this.timePrefix = '',
    this.userType = '',
  });

  final List<Map<String, dynamic>> userList;

  /// 时间字段名（如 `txTimeUnix` / `likeTimeUnix`）。
  final String timeKey;
  final String timeIcon;
  final String timePrefix;

  /// `INVITEE` 时不显示统计行。
  final String userType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BrandConfig brand = ref.watch(brandProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final Map<String, dynamic> user in userList)
          InkWell(
            onTap: () =>
                context.push('/showCreator?unid=${user['usid']?.toString() ?? ''}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: PexColors.greyE, width: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: (user['portrait']?.toString() ?? '').isEmpty
                        ? Center(
                            child: PexIcon.uni(
                              'person',
                              size: 24,
                              color: const Color(0xFFD3D3D3),
                            ),
                          )
                        : ServerImage(user['portrait']?.toString(), fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                user['nickname']?.toString() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: PexColors.grey3,
                                ),
                              ),
                            ),
                            if (timeKey.isNotEmpty && user[timeKey] != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  if (timeIcon.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: PexIcon(
                                        PexIcons.byPrefix(
                                          timePrefix.isEmpty ? null : timePrefix,
                                          timeIcon,
                                        ),
                                        size: 16,
                                        color: PexColors.grey9,
                                      ),
                                    ),
                                  Text(
                                    formatDate(user[timeKey], 'yyyy-mm-dd'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: PexColors.grey9,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if (userType != 'INVITEE')
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: <Widget>[
                                _stat(
                                  icon: PexIcons.uni(kUmyCollectionIcon),
                                  color: brand.colorCollect,
                                  text: '${countCreationPublic(user)}',
                                ),
                                _stat(
                                  icon: PexIcons.uni(kUmyCircleIcon),
                                  color: brand.colorCircle,
                                  text: '${_followerCount(user)}',
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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

  static int _followerCount(Map<String, dynamic> user) {
    int of(String key) {
      final Object? value = user[key];
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return of('countFollower') + of('countFollowing');
  }
}
