/// 我邀请的朋友，对应源项目 `pages/umyInviteList.vue`。
///
/// 与 `umyCircle?tagnow=INVITEE` 共用同一个名单组件；本页只是它的一层壳
/// （源项目在 Agidin 下用本页替代圈子页的邀请分类）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/router/app_routes.dart';
import '../core/state/creator_provider.dart';
import '../widgets/part_circle_list.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_window_layout.dart';

class UmyInviteListPage extends ConsumerWidget {
  const UmyInviteListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PartWindowLayout(
      pageName: AppRoutes.umyInviteList,
      child: Column(
        children: <Widget>[
          const PartNavibarPcFixed(),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: const PartCircleList(tag: CircleTag.invitee),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
