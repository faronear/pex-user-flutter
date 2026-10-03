/// 提现渠道卡片，对应源项目 `parts/partFundChannelCard.vue`。
///
/// 卡片内容由配置驱动（[paytoCoinSet]）：先显示币种，再按字段配置逐行显示（标了 `inCard` 的）。
/// [toWithdraw] 为 true 时不显示底部的「删除 / 提现」操作行（提现页里的卡片就是这样）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/user_api.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/i18n/payto_coins.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../core/util/feedback.dart';
import '../theme/app_theme.dart';

const LangText _kCurrency = LangText(
  zhCN: '货币',
  enUS: 'Currency',
  jaJP: '通貨',
  deDE: 'Währung',
);

const LangText _kDelete = LangText(
  zhCN: '删除',
  enUS: 'Delete',
  jaJP: '削除',
  deDE: 'Löschen',
);

const LangText _kCashout = LangText(
  zhCN: '提现',
  enUS: 'Cashout',
  jaJP: '出金',
  deDE: 'Auszahlen',
);

const LangText _kDeleteTitle = LangText(
  zhCN: '删除提现渠道',
  enUS: 'Delete Cashout Channel',
  jaJP: '出金チャネルを削除',
  deDE: 'Auszahlungskanal löschen',
);

const LangText _kDeleteContent = LangText(
  zhCN: '确定要删除这个提现渠道吗？',
  enUS: 'Are you sure you want to delete this cashout channel?',
  jaJP: 'この出金チャネルを削除してもよろしいですか？',
  deDE: 'Sind Sie sicher, dass Sie diesen Auszahlungskanal löschen möchten?',
);

class PartFundChannelCard extends ConsumerStatefulWidget {
  const PartFundChannelCard({
    super.key,
    required this.channel,
    this.toWithdraw = false,
    this.onTap,
    this.onCashout,
  });

  final Map<String, dynamic> channel;
  final bool toWithdraw;

  /// 整卡点击（列表页用它进提现页）。
  final VoidCallback? onTap;

  /// 底部「提现」按钮。源项目这个按钮**没有绑定事件**（靠父层包一层点击），
  /// 迁移版让它与 [onTap] 同源，避免出现点了没反应的按钮。
  final VoidCallback? onCashout;

  @override
  ConsumerState<PartFundChannelCard> createState() =>
      _PartFundChannelCardState();
}

class _PartFundChannelCardState extends ConsumerState<PartFundChannelCard> {
  bool _deleting = false;

  String get _coinType => widget.channel['coinType']?.toString() ?? '';

  /// 该渠道要展示的「标签 → 值」明细（源项目 `getChannelDetails`）。
  List<({LangText label, String value})> _details(String lang) {
    final PaytoCoin? payto = paytoCoinSet[_coinType];
    if (payto == null) return const <({LangText label, String value})>[];
    return <({LangText label, String value})>[
      for (final PaytoField field in payto.fields)
        if (field.inCard)
          (
            label: field.title,
            value: field.chainTypeSet.isNotEmpty
                ? (field.chainTypeSet[widget.channel[field.key]?.toString()] ??
                          const LangText(zhCN: '', enUS: ''))
                      .resolve(lang)
                : widget.channel[field.key]?.toString() ?? '',
          ),
    ];
  }

  /// 删除渠道（源项目 `to_delete_channel`）：确认 → 调接口 → 从本地在线用户里移除。
  Future<void> _deleteChannel() async {
    final bool confirmed = await showPexModal(
      context,
      ref,
      title: _kDeleteTitle,
      content: _kDeleteContent,
      showCancel: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    final Map<String, dynamic> data = await ref
        .read(userApiProvider)
        .deletePaytoChannel(widget.channel['channelUuid']?.toString() ?? '');
    if (!mounted) return;
    setState(() => _deleting = false);

    if (!bok(data['_state']?.toString())) {
      final LangText message = LangText.fromMap(data['_msg']);
      if (mounted) {
        showPexToast(context, ref, message.isEmpty ? _kDelete : message);
      }
      return;
    }
    // 源项目：从 `onlineUser.paytoChannels` 里删掉这个 uuid（后端同时把 lifeState 置为 DELETED）。
    final Map<String, dynamic> user = ref.read(onlineUserProvider);
    final Map<String, dynamic> channels =
        (user['paytoChannels'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    ref.read(appStartupProvider.notifier).mergeOnlineUser(<String, dynamic>{
      'paytoChannels': <String, dynamic>{
        for (final MapEntry<String, dynamic> entry in channels.entries)
          if (entry.key != widget.channel['channelUuid']?.toString())
            entry.key: entry.value,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final PaytoCoin? payto = paytoCoinSet[_coinType];

    // 源项目是把卡片外包一层可点击容器（列表页点击进提现页）；
    // 这里让卡片自己承接该点击，`onCashout` 只是「提现」按钮的显式入口。
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: PexColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _row(
              label: _kCurrency.resolve(lang),
              value: payto?.coin.coinCode ?? _coinType,
            ),
            for (final ({LangText label, String value}) detail in _details(
              lang,
            ))
              _row(label: detail.label.resolve(lang), value: detail.value),
            if (!widget.toWithdraw)
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: PexColors.blueMatt)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    _actionButton(
                      text: _kDelete.resolve(lang),
                      icon: Icons.delete_outline,
                      onTap: _deleting ? null : _deleteChannel,
                    ),
                    _actionButton(
                      text: _kCashout.resolve(lang),
                      icon: Icons.map_outlined,
                      onTap: widget.onCashout ?? widget.onTap,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: PexColors.grey9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18, color: PexColors.grey9),
              const SizedBox(width: 4),
              Text(
                text,
                style: const TextStyle(fontSize: 14, color: PexColors.grey9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
