/// 申请提现，对应源项目 `pages/umyFundChannelWithdraw.vue`。
///
/// 流程：渠道卡片 → 金额（带下限与余额提示）→ 换算预览 → 提交。
/// 提交前有**实名闸门**：未通过实名（`kycStateL1 !== 'PASSED'`）会先弹窗引导去实名认证。
///
/// 注意：源项目这里写的是 `kycStatusL1`，**该字段并不存在**（用户对象上是 `kycStateL1`），
/// 于是恒为 `undefined !== 'PASSED'`，导致**任何人都被挡住、提现永远提交不出去**。
/// 这是源项目的一处笔误，2026-10-03 经老板确认后**两边一起修正**（源项目 commit `bbbfed64`）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/api/user_api.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/i18n/payto_coins.dart';
import '../core/router/app_routes.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../core/util/feedback.dart';
import '../core/util/pex_toolkit.dart';
import '../theme/app_theme.dart';
import '../widgets/part_button_submit.dart';
import '../widgets/part_fund_channel_card.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_window_layout.dart';

const LangText _kChannel = LangText(
  zhCN: '提现渠道',
  enUS: 'Cashout Channel',
  jaJP: '出金チャネル',
  deDE: 'Auszahlungskanal',
);

const LangText _kAmount = LangText(
  zhCN: '提现金额',
  enUS: 'Cashout Amount',
  jaJP: '出金額',
  deDE: 'Auszahlungsbetrag',
);

const LangText _kMinimum = LangText(
  zhCN: '最小金额 ',
  enUS: 'Minimum ',
  jaJP: '最小額 ',
  deDE: 'Minimum ',
);

const LangText _kBalanceLabel = LangText(
  zhCN: '当前余额 ',
  enUS: 'Balance ',
  jaJP: '現在の残高 ',
  deDE: 'Guthaben ',
);

const LangText _kAmountHint = LangText(
  zhCN: '您想要提现的金额',
  enUS: 'Your cashout amount',
  jaJP: '出金希望額',
  deDE: 'Ihr Auszahlungsbetrag',
);

const LangText _kEstimated = LangText(
  zhCN: '预计收款金额\n（以实际到账为准）',
  enUS: 'Estimated amount to receive\n(subject to actual receipt)',
  jaJP: '受取予定金額\n（実際の受取額に準じます）',
  deDE: 'Voraussichtlicher Empfangsbetrag\n(abhängig vom tatsächlichen Eingang)',
);

const LangText _kSubmit = LangText(
  zhCN: '提交',
  enUS: 'Submit',
  jaJP: '送信',
  deDE: 'Absenden',
);

const LangText _kAmountRequired = LangText(
  zhCN: '请输入取现的数额',
  enUS: 'Enter the amount of your cashout',
  jaJP: '出金額を入力してください',
  deDE: 'Geben Sie den Auszahlungsbetrag ein',
);

const LangText _kTooSmall = LangText(
  zhCN: '最小提现金额为 ',
  enUS: 'Minimum cashout amount is ',
  jaJP: '最小出金額は ',
  deDE: 'Mindestbetrag für die Auszahlung ist ',
);

const LangText _kTooLarge = LangText(
  zhCN: '取现金额不能大于您的当前余额',
  enUS: 'Cashout amount cannot exceed your current balance',
  jaJP: '出金額は現在の残高を超えることはできません',
  deDE: 'Auszahlungsbetrag darf nicht höher sein als Ihr aktuelles Guthaben',
);

const LangText _kKycTitle = LangText(
  zhCN: '请先完成实名认证',
  enUS: 'Please complete real-name authentication',
  jaJP: '本人認証を完了してください',
  deDE: 'Bitte schließen Sie die Identitätsverifizierung ab',
);

const LangText _kKycContent = LangText(
  zhCN: '为了保障您的资金安全，请先完成实名认证，然后申请提现。',
  enUS: 'To ensure your financial security, please complete real-name authentication and apply for cashout.',
  jaJP: '資金の安全を確保するため、本人認証を完了し、出金申請をしてください。',
  deDE: 'Um die Sicherheit Ihrer finanziellen Mittel zu gewährleisten, müssen Sie zuerst die Identitätsverifizierung abschließen, bevor Sie einen Auszahlungsantrag stellen.',
);

const LangText _kGoKyc = LangText(
  zhCN: '去实名认证',
  enUS: 'Verify Identity',
  jaJP: '本人認証へ',
  deDE: 'Zur Verifizierung',
);

const LangText _kSuccessTitle = LangText(
  zhCN: '提现申请成功',
  enUS: 'Cashout Application Success',
  jaJP: '出金申請が完了しました',
  deDE: 'Auszahlungsantrag erfolgreich',
);

const LangText _kSuccessContent = LangText(
  zhCN: '您的提现申请已提交，请等待审核结果',
  enUS: 'Your cashout application has been submitted, please wait for the audit result',
  jaJP: '出金申請が完了しました',
  deDE: 'Ihr Auszahlungsantrag wurde erfolgreich eingereicht. Bitte warten Sie auf die Überprüfung',
);

class UmyFundChannelWithdrawPage extends ConsumerStatefulWidget {
  const UmyFundChannelWithdrawPage({super.key, this.channelUuid = ''});

  /// 路由 `?channelUuid=`（源项目同时接受 `channeluuid` 拼写）。
  final String channelUuid;

  @override
  ConsumerState<UmyFundChannelWithdrawPage> createState() =>
      _UmyFundChannelWithdrawPageState();
}

class _UmyFundChannelWithdrawPageState
    extends ConsumerState<UmyFundChannelWithdrawPage> {
  final TextEditingController _amount = TextEditingController();
  bool _loading = false;
  bool _ready = false;
  LangText? _feedback;

  Map<String, dynamic> get _channels =>
      (ref.read(onlineUserProvider)['paytoChannels'] as Map?)
          ?.cast<String, dynamic>() ??
      <String, dynamic>{};

  Map<String, dynamic> get _channel =>
      (_channels[widget.channelUuid] as Map?)?.cast<String, dynamic>() ??
      <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 100), () async {
      await ref.read(appStartupProvider.notifier).waitAutologin();
      if (!mounted) return;
      // 源项目 `onLoad`：找不到该渠道就退回渠道列表；一个都没有则退回资金页。
      if (!_channels.containsKey(widget.channelUuid)) {
        final String target = _channels.isEmpty
            ? AppRoutes.path(AppRoutes.umyFund)
            : AppRoutes.path(AppRoutes.umyFundChannel);
        context.go(target);
        return;
      }
      setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// 换算后的收款金额：`金额 / coinToTUC[币种]`，加密币 6 位小数、法币 2 位。
  num get _convertedAmount {
    final num? amount = num.tryParse(_amount.text);
    final String coinType = _channel['coinType']?.toString() ?? '';
    if (amount == null || coinType.isEmpty) return 0;
    final num rate =
        num.tryParse(ref.read(envarProvider).coinToTUC[coinType]?.toString() ?? '') ??
            0;
    if (rate == 0) return 0;
    final PaytoCoin? payto = paytoCoinSet[coinType];
    return numberPrecision(amount / rate, (payto?.isCrypto ?? false) ? 6 : 2);
  }

  /// 提交（源项目 `to_request_withdrawal`）。
  Future<void> _submit() async {
    setState(() => _feedback = null);
    final Envar envar = ref.read(envarProvider);
    final num? amount = num.tryParse(_amount.text);

    if (amount == null) {
      setState(() => _feedback = _kAmountRequired);
      return;
    }
    if (amount < envar.withdrawAmountMin) {
      setState(() => _feedback = LangText.from(
        '${_kTooSmall.resolve(ref.read(languageProvider))}'
        '${envar.withdrawAmountMin}${envar.tucSymbol}',
      ));
      return;
    }
    if (amount >= _numOf(ref.read(onlineUserProvider)['balanceTUC'])) {
      // 源项目用的是「必须严格小于余额」，这里保持一致。
      setState(() => _feedback = _kTooLarge);
      return;
    }

    // 实名闸门（源项目此处字段名写错，2026-10-03 修正为 `kycStateL1`）。
    final String kycState =
        ref.read(onlineUserProvider)['kycStateL1']?.toString() ?? '';
    if (kycState != 'PASSED') {
      final bool goKyc = await showPexModal(
        context,
        ref,
        title: _kKycTitle,
        content: _kKycContent,
        confirmText: _kGoKyc,
        showCancel: true,
      );
      if (goKyc && mounted) context.push(AppRoutes.path(AppRoutes.umyKyc));
      return;
    }

    setState(() => _loading = true);
    final Map<String, dynamic> data =
        await ref.read(userApiProvider).requestWithdrawal(
              withdrawAmount: amount,
              channelUuid: widget.channelUuid,
            );
    if (!mounted) return;
    setState(() => _loading = false);

    if (!bok(data['_state']?.toString())) {
      final LangText message = LangText.fromMap(data['_msg']);
      setState(() =>
          _feedback = message.isEmpty ? PartTexts.systemDown : message);
      return;
    }

    // 源项目：本地先扣余额，再弹成功框，确认后返回上一页。
    final num balance = _numOf(ref.read(onlineUserProvider)['balanceTUC']);
    ref.read(appStartupProvider.notifier).mergeOnlineUser(<String, dynamic>{
      'balanceTUC': numberPrecision(balance - amount),
    });
    if (!mounted) return;
    await showPexModal(context, ref, title: _kSuccessTitle, content: _kSuccessContent);
    if (mounted) context.pop();
  }

  static num _numOf(Object? value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final Map<String, dynamic> user = ref.watch(onlineUserProvider);
    final String coinType = _channel['coinType']?.toString() ?? '';
    final PaytoCoin? payto = paytoCoinSet[coinType];

    return PartWindowLayout(
      pageName: AppRoutes.umyFundChannelWithdraw,
      child: Column(
        children: <Widget>[
          const PartNavibarPcFixed(),
          Expanded(
            child: !_ready
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 750),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              const SizedBox(height: 10),
                              _header(_kChannel, null),
                              PartFundChannelCard(
                                channel: _channel,
                                toWithdraw: true,
                              ),
                              _header(_kAmount, null),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      '${_kMinimum.resolve(lang)}${envar.withdrawAmountMin}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: PexColors.grey9,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_kBalanceLabel.resolve(lang)}${numberPrecision(user['balanceTUC'])}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: PexColors.grey9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextField(
                                controller: _amount,
                                keyboardType: TextInputType.number,
                                maxLength: 18,
                                style: const TextStyle(letterSpacing: 2),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: _kAmountHint.resolve(lang),
                                  suffixText: envar.tucSymbol,
                                  counterText: '',
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      _kEstimated.resolve(lang),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: PexColors.grey9,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${_amount.text.isEmpty ? 0 : _convertedAmount} '
                                      '${payto?.coin.coinCode ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: PexColors.grey9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PartButtonSubmit(
                                disabled: _loading || _amount.text.isEmpty,
                                loading: _loading,
                                onPressed: _submit,
                                children: <Widget>[
                                  Text(_kSubmit.resolve(lang)),
                                ],
                              ),
                              if (_feedback != null)
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    _feedback!.resolve(lang),
                                    textAlign: TextAlign.center,
                                    style:
                                        const TextStyle(color: PexColors.redMy),
                                  ),
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

  Widget _header(LangText title, LangText? info) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
        child: Text(
          title.resolve(ref.read(languageProvider)),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
}
