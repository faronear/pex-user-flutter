/// 我的资金，对应源项目 `pages/umyFund.vue`。
///
/// 结构：钱包地址行 + 「当前余额」卡片 + 各收支分类行（点进收支明细）+ 充值 / 提现按钮。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../brands/brand_config.dart';
import '../core/appmeta/page_meta.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_routes.dart';
import '../core/state/app_providers.dart';
import '../core/state/envar_provider.dart';
import '../core/util/pex_toolkit.dart';
import '../theme/app_theme.dart';
import '../widgets/part_icontext_copy.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_pop_link.dart';
import '../widgets/part_window_layout.dart';

const LangText _kWalletTitle = LangText(
  zhCN: '我的加密钱包',
  enUS: 'My Crypto Wallet',
  jaJP: '私のウォレット',
  deDE: 'Meine Crypto Wallet',
);

const LangText _kBalance = LangText(
  zhCN: '当前余额',
  enUS: 'Balance',
  jaJP: '残高',
  deDE: 'Kontostand',
);

const LangText _kDeposit = LangText(
  zhCN: '充 值',
  enUS: 'Deposit',
  jaJP: 'チャージ',
  deDE: 'Einzahlen',
);

const LangText _kCashout = LangText(
  zhCN: '提 现',
  enUS: 'Cashout',
  jaJP: '出 金',
  deDE: 'Auszahlen',
);

/// Agidin 专属的两行文案（源项目内联写死）。
const LangText _kAiIncome = LangText(
  zhCN: '+ 创作品收入',
  enUS: '+ Creation Income',
  jaJP: '+ 创作品収入',
  deDE: '+ Artefakteinkommen',
);

const LangText _kAiCosts = LangText(
  zhCN: '- AI 支出',
  enUS: '- AI Costs',
  jaJP: '- AI コスト',
  deDE: '- KI-Kosten',
);

class UmyFundPage extends ConsumerWidget {
  const UmyFundPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final BrandConfig brand = ref.watch(brandProvider);
    final Map<String, dynamic> user = ref.watch(onlineUserProvider);
    final DeviceInfo device = DeviceInfo.of(context);

    final String caddTUC = user['caddTUC']?.toString() ?? '';
    final String urlWallet = '${envar.tucLens}/address/$caddTUC#nfttransfers';
    final Map<String, dynamic> txDict = envar.myTxDict;

    return PartWindowLayout(
      pageName: AppRoutes.umyFund,
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (!envar.hideWalletAddress && caddTUC.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(
                                  width: 60,
                                  child: PexIcon(
                                    PexIcons.byPrefix(
                                      pageMetaOf('umyFund')?.gotoIconPrefix,
                                      pageMetaOf('umyFund')?.gotoIconType,
                                    ),
                                    size: 44,
                                    color: PexColors.colorFund,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Flexible(
                                          child: InkWell(
                                            onTap: () async {
                                              final Uri? uri =
                                                  Uri.tryParse(urlWallet);
                                              if (uri == null) return;
                                              await launchUrl(uri,
                                                  mode: LaunchMode
                                                      .externalApplication);
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(5),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  PexIcon.icont('hyperlink',
                                                      size: 16,
                                                      color: PexColors.blueMy),
                                                  const SizedBox(width: 2),
                                                  Flexible(
                                                    child: Text(
                                                      caddTUC,
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        color:
                                                            PexColors.blueMy,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        PartIcontextCopy(
                                          onCopy: () => Clipboard.setData(
                                            ClipboardData(text: caddTUC),
                                          ),
                                        ),
                                        PartIcontextPop(
                                          onPop: () => showPopLinkSheet(
                                            context,
                                            ref,
                                            shareTitle: _kWalletTitle,
                                            shareUrl: urlWallet,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Card(
                          margin: EdgeInsets.zero,
                          color: Colors.white,
                          child: Column(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      _kBalance.resolve(lang),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${numberPrecision(user['balanceTUC'])}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(envar.tucSymbol),
                                  ],
                                ),
                              ),
                              ..._rows(
                                context,
                                lang,
                                brand,
                                user,
                                txDict,
                                pact: _pactDict(ref),
                                groupFlag: envar.showTxGroup,
                              ),
                              if (!envar.hideDepositButton ||
                                  !envar.hideCashoutButton)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 20),
                                  child: _buttons(context, ref, envar, device),
                                ),
                            ],
                          ),
                        ),
                        if (!envar.hideCashoutButton && envar.cashoutAlone)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: InkWell(
                                onTap: () => _requestWithdraw(context, ref, user),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Icon(Icons.file_upload_outlined,
                                          size: 22, color: PexColors.blueMy),
                                      const SizedBox(width: 5),
                                      Text(
                                        _kCashout.resolve(lang),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: PexColors.blueMy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
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

  /// 收支分类行：`+ 充值` / `+ 奖励` 恒有；创作品两组仅 Babelyx；AI 两行仅 Agidin。
  List<Widget> _rows(
    BuildContext context,
    String lang,
    BrandConfig brand,
    Map<String, dynamic> user,
    Map<String, dynamic> txDict, {
    required Map<String, dynamic> pact,
    required bool groupFlag,
  }) {
    final List<Widget> rows = <Widget>[
      _row(
        context: context,
        lang: lang,
        tag: 'TXG_RECHARGE',
        label: txDict['TXG_RECHARGE'],
        footer: '+${numberPrecision(user['sumInRecharges'])}',
        body: <Widget>[],
      ),
      _row(
        context: context,
        lang: lang,
        tag: 'TXG_IN_REWARD',
        label: txDict['TXG_IN_REWARD'],
        footer: '+${numberPrecision(user['sumInRewards'])}',
        body: <Widget>[],
      ),
    ];

    if (brand.showCreationIncome) {
      final bool group = groupFlag;
      rows.add(
        _row(
          context: context,
          lang: lang,
          tag: 'TXG_IN_PEX',
          label: txDict['TXG_IN_PEX'],
          footer:
              '+${numberPrecision(_num(user['sumInPexCreator']) + _num(user['sumInPexOwner']))}',
          body: group
              ? <Widget>[
                  if (pact['TOWN'] != null)
                    _sub(
                      context: context,
                      lang: lang,
                      sign: '+',
                      amount: user['sumInPexOwner'],
                      tag: 'TXG_IN_PEX_OWNER',
                      label: LangText.fromMap(
                          (pact['TOWN'] as Map?)?['OWNER']),
                    ),
                  _sub(
                    context: context,
                    lang: lang,
                    sign: '+',
                    amount: user['sumInPexCreator'],
                    tag: 'TXG_IN_PEX_CREATOR',
                    label: LangText.fromMap(
                        (pact['TCREATE'] as Map?)?['CREATOR']),
                  ),
                ]
              : <Widget>[],
        ),
      );
      rows.add(
        _row(
          context: context,
          lang: lang,
          tag: 'TXG_OUT_PEX',
          label: txDict['TXG_OUT_PEX'],
          footer:
              '-${numberPrecision(_num(user['sumOutPexOwn']) + _num(user['sumOutPexHold']) + _num(user['sumOutPexView']))}',
          body: group
              ? <Widget>[
                  _sub(
                    context: context,
                    lang: lang,
                    sign: '-',
                    amount: user['sumOutPexView'],
                    tag: 'TXG_OUT_PEX_VIEW',
                    label: LangText.fromMap(
                        (pact['TVIEW'] as Map?)?['pact_tag']),
                  ),
                  _sub(
                    context: context,
                    lang: lang,
                    sign: '-',
                    amount: user['sumOutPexHold'],
                    tag: 'TXG_OUT_PEX_HOLD',
                    label: LangText.fromMap(
                        (pact['THOLD'] as Map?)?['pact_tag']),
                  ),
                  if (pact['TOWN'] != null)
                    _sub(
                      context: context,
                      lang: lang,
                      sign: '-',
                      amount: user['sumOutPexOwn'],
                      tag: 'TXG_OUT_PEX_OWN',
                      label: LangText.fromMap(
                          (pact['TOWN'] as Map?)?['pact_tag']),
                    ),
                ]
              : <Widget>[],
        ),
      );
    }

    if (brand.showAiCosts) {
      rows.add(
        _row(
          context: context,
          lang: lang,
          tag: '',
          label: _kAiIncome,
          footer: '+${numberPrecision(user['sumInAippOwner'])}',
          body: <Widget>[],
        ),
      );
      rows.add(
        _row(
          context: context,
          lang: lang,
          tag: '',
          label: _kAiCosts,
          footer: '-${numberPrecision(user['sumOutAiChat'])}',
          body: <Widget>[],
        ),
      );
    }
    return rows;
  }

  Map<String, dynamic> _pactDict(WidgetRef ref) {
    final Object? pact = ref.read(envarProvider).raw['pactDict'];
    return pact is Map ? pact.cast<String, dynamic>() : <String, dynamic>{};
  }

  static num _num(Object? value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;

  /// 一行：左侧「+ 分类名」（有 tag 时可点进明细）+ 可选二级分类 + 右侧汇总。
  Widget _row({
    required BuildContext context,
    required String lang,
    required String tag,
    required Object? label,
    required String footer,
    required List<Widget> body,
  }) {
    return InkWell(
      onTap: tag.isEmpty ? null : () => _openTranx(context, tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: PexColors.greyE, width: 0.5)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${tag.startsWith('TXG_OUT') ? '' : '+'} ${ll(lang, LangText.fromMap(label))}',
                style: const TextStyle(fontSize: 15),
              ),
            ),
            if (body.isNotEmpty) ...<Widget>[
              Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.end, children: body)),
              const SizedBox(width: 10),
            ],
            Text(
              footer,
              style: const TextStyle(fontSize: 15, color: PexColors.grey6),
            ),
          ],
        ),
      ),
    );
  }

  /// 二级分类小方块（源项目在 `showTxGroup` 打开时显示）。
  Widget _sub({
    required BuildContext context,
    required String lang,
    required String sign,
    required Object? amount,
    required String tag,
    required LangText label,
  }) {
    return InkWell(
      onTap: () => _openTranx(context, tag),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '$sign${numberPrecision(amount, 0)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              ll(lang, label),
              style: const TextStyle(fontSize: 11, color: PexColors.grey6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buttons(
    BuildContext context,
    WidgetRef ref,
    Envar envar,
    DeviceInfo device,
  ) {
    final String lang = ref.watch(languageProvider);
    final Map<String, dynamic> user = ref.watch(onlineUserProvider);
    return Row(
      children: <Widget>[
        if (!envar.hideDepositButton)
          Expanded(
            child: InkWell(
              onTap: () {
                // partDeposit（充值弹层，源项目 1066 行）尚未迁移 → 跳占位页。
                context.push(AppRoutes.path(AppRoutes.umyFundDeposit));
              },
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFFCBD71), Color(0xFFFEA600)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _kDeposit.resolve(lang),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 20),
        if (!envar.hideCashoutButton && !envar.cashoutAlone)
          Expanded(
            child: InkWell(
              onTap: () => _requestWithdraw(context, ref, user),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[PexColors.redMy, Color(0xFFFAB6B6)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _kCashout.resolve(lang),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 提现入口（源项目 `request_withdraw`）：已有收款渠道进渠道页，否则先进「新建渠道」。
  void _requestWithdraw(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
  ) {
    final Object? channels = user['paytoChannels'];
    final bool hasChannel =
        channels is Map && channels.isNotEmpty;
    context.push(
      AppRoutes.path(hasChannel
          ? AppRoutes.umyFundChannel
          : AppRoutes.umyFundChannelCreate),
    );
  }

  static void _openTranx(BuildContext context, String tag) => context.push(
        '${AppRoutes.path(AppRoutes.umyFundTranx)}?tagnow=$tag',
      );
}
