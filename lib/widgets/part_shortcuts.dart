/// 底部快捷入口条，对应源项目 `parts/partShortcuts.vue`。
///
/// 数据源为后端下发的 `envar.linkTree`：
/// - `apps.subtags.{ios,android,webapp}`（Web 显示 ios/android，App 显示 webapp）
/// - `webs.subtags.info`
/// 另附固定的 `umyContact`、`userResource` 入口。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/router/app_router.dart';
import '../core/state/app_startup_notifier.dart';

class PartShortcuts extends ConsumerWidget {
  const PartShortcuts({super.key, this.color, this.size = 28});

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStartupState startup = ref.watch(appStartupProvider);
    final Map<String, dynamic> linkTree =
        (startup.envar['linkTree'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

    final List<Widget> items = <Widget>[];
    if (startup.afterAutologging) {
      for (final String key
          in kIsWeb ? <String>['ios', 'android'] : <String>['webapp']) {
        final PexGlyph? glyph = _linkGlyph(linkTree, 'apps', key);
        if (glyph != null) {
          items.add(_icon(glyph, onTap: () => _toResource(context, key)));
        }
      }
      final PexGlyph? info = _linkGlyph(linkTree, 'webs', 'info');
      if (info != null) {
        items.add(_icon(info, onTap: () => _toResource(context, 'info')));
      }
    }
    // 固定入口：联系我们（源项目 umyContact 的 gotoIcon 为耳机）。
    items.add(_icon(
      PexIcons.icont('icont-headphone-fill'),
      onTap: () => context.push(AppRoutes.path(AppRoutes.umyContact)),
    ));
    // 固定入口：更多（uni-icons more-filled → userResource）。
    items.add(_icon(
      PexIcons.uni('more-filled'),
      onTap: () => context.push(AppRoutes.path(AppRoutes.userResource)),
    ));

    return Row(mainAxisSize: MainAxisSize.min, children: items);
  }

  /// 源项目 `wo.tt.show_resource`：进资源详情页（已在详情页且目标相同则不动）。
  void _toResource(BuildContext context, String tagNow) {
    context.push('/${AppRoutes.userResourceDetail}?tagnow=$tagNow');
  }

  PexGlyph? _linkGlyph(Map<String, dynamic> linkTree, String group, String key) {
    final Map<String, dynamic>? subtags =
        ((linkTree[group] as Map?)?['subtags'] as Map?)?.cast<String, dynamic>();
    final Map<String, dynamic>? subtag =
        (subtags?[key] as Map?)?.cast<String, dynamic>();
    if (subtag == null) return null;
    return PexIcons.byPrefix(
      subtag['iconPrefix']?.toString(),
      subtag['iconType']?.toString(),
    );
  }

  Widget _icon(PexGlyph? glyph, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: onTap,
        child: PexIcon(glyph, size: size, color: color ?? Colors.grey),
      ),
    );
  }
}
