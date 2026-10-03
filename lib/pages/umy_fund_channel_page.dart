/// 提现渠道列表，对应源项目 `pages/umyFundChannel.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/appmeta/page_meta.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_routes.dart';
import '../core/state/envar_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/part_fund_channel_card.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_window_layout.dart';

const LangText _kSelectChannel = LangText(
  zhCN: '请选择提现渠道',
  enUS: 'Please select a cashout channel',
  jaJP: '引き出し先を選択してください',
);

class UmyFundChannelPage extends ConsumerWidget {
  const UmyFundChannelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final DeviceInfo device = DeviceInfo.of(context);
    final Map<String, dynamic> channels =
        (ref.watch(onlineUserProvider)['paytoChannels'] as Map?)
                ?.cast<String, dynamic>() ??
            <String, dynamic>{};

    return PartWindowLayout(
      pageName: AppRoutes.umyFundChannel,
      child: Column(
        children: <Widget>[
          const PartNavibarPcFixed(),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(_kSelectChannel.resolve(lang)),
                                ),
                              ),
                              InkWell(
                                onTap: () => context.push(
                                  AppRoutes.path(AppRoutes.umyFundChannelCreate),
                                ),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: PexColors.blueMy),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Icon(Icons.add,
                                          size: 16, color: PexColors.blueMy),
                                      const SizedBox(width: 5),
                                      Text(
                                        (pageMetaOf('umyFundChannelCreate')
                                                    ?.i18nGotoTitle ??
                                                const LangText(
                                                    zhCN: '新建渠道',
                                                    enUS: 'New Channel'))
                                            .resolve(lang),
                                        style: const TextStyle(
                                          color: PexColors.blueMy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          children: <Widget>[
                            for (final MapEntry<String, dynamic> entry
                                in channels.entries)
                              SizedBox(
                                width: device.inPc ? 440 : null,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: device.inPhone ? 10 : 10,
                                      horizontal: device.inPhone ? 0 : 10),
                                  child: PartFundChannelCard(
                                    channel: (entry.value as Map)
                                        .cast<String, dynamic>(),
                                    onTap: () => context.push(
                                      '${AppRoutes.path(AppRoutes.umyFundChannelWithdraw)}'
                                      '?channelUuid=${entry.key}',
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
