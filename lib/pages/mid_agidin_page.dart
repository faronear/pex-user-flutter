/// AI 对话落地页，对应源项目 `pages/midAgidin.vue`（品牌落地中间页）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/appmeta/tab_bar.dart';
import '../core/i18n/i18n.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/state/ai_provider.dart';
import '../core/state/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/part_aichat.dart';
import '../widgets/part_window_layout.dart';

class MidAgidinPage extends ConsumerWidget {
  const MidAgidinPage({super.key, this.aicode});

  /// 路由参数 `?aicode=`。
  final String? aicode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DeviceInfo device = DeviceInfo.of(context);
    final String lang = ref.watch(languageProvider);
    final String aiName = ref.watch(aiProvider).modelNow?.ainame.resolve(lang) ?? '';

    // PC 由顶栏承担导航；手机端使用自绘顶栏（返回首个标签 / 前往最后一个标签）。
    return PartWindowLayout(
      pageName: 'midAgidin',
      child: Column(
        children: <Widget>[
          if (!device.inPc)
            _buildPhoneHeader(context, lang, aiName, ref.watch(brandProvider).tabItems),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: device.inPc ? 10 : 0,
                bottom: device.inPc ? 30 : 0,
              ),
              child: PartAichat(aicode: aicode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneHeader(
    BuildContext context,
    String lang,
    String aiName,
    List<TabItem> tabs,
  ) {
    final TabItem first = tabs.first;
    final TabItem last = tabs.last;
    return Container(
      height: 44,
      color: PexColors.grey3,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () => context.go('/${first.pageName}'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                PexIcon.uni('back', size: 22, color: PexColors.greyA),
                Text(
                  ll(lang, first.i18nText),
                  style: const TextStyle(fontSize: 14, color: PexColors.greyA),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              aiName,
              textAlign: TextAlign.center,
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
                  style: const TextStyle(fontSize: 14, color: PexColors.greyA),
                ),
                PexIcon.uni('forward', size: 22, color: PexColors.greyA),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
