/// 创造新可能（新建作品），对应源项目 `pages/midBabely.vue`。
///
/// 这是 Babelyx 的「中间按钮落地页」（源项目 `pages.json` 的 `tabBar.midButton.midPage`），
/// 主体就是 [PartCreate]（新建模式）；手机端另有一条固定顶栏（返回 / 标题 / 跳最后一个标签页）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/appmeta/tab_bar.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_router.dart';
import '../core/state/app_providers.dart';
import '../core/state/creation_draft_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/part_create.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_window_layout.dart';

class MidBabelyPage extends ConsumerStatefulWidget {
  const MidBabelyPage({super.key});

  @override
  ConsumerState<MidBabelyPage> createState() => _MidBabelyPageState();
}

class _MidBabelyPageState extends ConsumerState<MidBabelyPage> {
  @override
  void initState() {
    super.initState();
    // 每次进入本页都重置为空白草稿（源项目通过 `creation_reset_pexNew` 达到同样效果）。
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (mounted) ref.read(creationDraftProvider.notifier).initCreate();
    });
  }

  /// 手机端返回：没有上一页时回到第一个标签页（源项目 `navi_back`）。
  void _back(List<TabItem> tabs) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/${tabs.first.pageName}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final DeviceInfo device = DeviceInfo.of(context);
    final String lang = ref.watch(languageProvider);
    final List<TabItem> tabs = ref.watch(brandProvider).tabItems;

    return PartWindowLayout(
      pageName: AppRoutes.midBabely,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: device.inPc ? 900 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (device.inPc)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: PartNavibarPcFixed(
                      title: ref.watch(brandProvider).midPageTitle,
                      pageName: AppRoutes.midBabely,
                    ),
                  )
                else
                  _phoneHeader(context, lang, tabs),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    5,
                    device.inPc ? 0 : 10,
                    5,
                    device.inPc ? 30 : 20,
                  ),
                  child: const PartCreate(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 手机端固定顶栏：返回 + 标题 + 前往最后一个标签页。
  Widget _phoneHeader(BuildContext context, String lang, List<TabItem> tabs) {
    final TabItem last = tabs.last;
    return Container(
      height: 44,
      color: PexColors.grey3,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () => _back(tabs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.arrow_back, size: 22, color: PexColors.greyE),
                Text(
                  ll(lang, PartTexts.back),
                  style: const TextStyle(fontSize: 14, color: PexColors.greyE),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              ll(lang, ref.watch(brandProvider).midPageTitle ?? const LangText.from('')),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/${last.pageName}'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  ll(lang, last.i18nText),
                  style: const TextStyle(fontSize: 14, color: PexColors.greyE),
                ),
                const Icon(Icons.arrow_forward, size: 22, color: PexColors.greyE),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
