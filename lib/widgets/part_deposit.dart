/// 充值 / 支付面板，对应源项目 `parts/partDeposit.vue`（1066 行）。
///
/// 两种模式：
/// - **PAY**：用余额支付（[submitAction] 由调用方提供，例如创作、铸造页）。余额不足自动切到 DEPOSIT。
/// - **DEPOSIT**：充值。CNY 走支付门户二维码/链接，USDT 走链上转账地址；
///   两者都靠 `get_current_balance` 或实时通道的 `RECHARGE_SUCCESS` 推送确认到账。
///
/// 与源项目的差异（均为平台差异，已在 worklog 记录）：
/// - **不做 iOS 内购（IAP）**：源项目用 `uni.requestPayment(appleiap)` + `uni-pay` 插件，
///   属 uni-app 原生能力；`inAppIos` 未配置时源项目本就不显示该分支，故此处同样不显示。
/// - **不接 uniCloud `unipay-co` 云函数**：只用源项目自带的支付门户链接（`cnyPayPortalUrl`）。
/// - **不做「连接钱包」按钮**：源项目仅在「PC 且检测到 `window.ethereum`」时显示，需要 MetaMask 探测。
library;


import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/api_client.dart';
import '../core/api/user_api.dart';
import '../core/i18n/coins.dart';
import '../core/i18n/deposit_coins.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/router/app_routes.dart';
import '../core/state/app_providers.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../core/state/socket_provider.dart';
import '../core/storage/local_store.dart';
import '../core/util/feedback.dart';
import '../core/util/pex_toolkit.dart';
import '../theme/app_theme.dart';
import 'part_breathing_opacity.dart';
import 'part_button_submit.dart';
import 'part_close_button.dart';
import 'part_coin_table.dart';
import 'part_icontext_copy.dart';
import 'part_linkhelp.dart';
import 'part_pop_link.dart';
import 'part_texts.dart';

/// 源项目里写死的「管理员」名单（决定充值步进是 0.01 还是 1，以及下限）。
const List<String> kDepositAdminUsidList = <String>[
  '10eea744-f248-4301-8156-418590204220',
  '02217dcc-54d0-45f5-bee2-27d19df37ab1',
  '64858ed5-0dc1-4775-b68b-8be836fea4a7',
];

const LangText _kDeposit = LangText(
  zhCN: '充值',
  enUS: 'Deposit',
  jaJP: '入金',
  deDE: 'Einzahlung',
);

const LangText _kPay = LangText(
  zhCN: '支付',
  enUS: 'Pay',
  jaJP: '支払う',
  deDE: 'Bezahlen',
);

const LangText _kCurrentBalance = LangText(
  zhCN: '当前余额',
  enUS: 'Current Balance',
);

const LangText _kCheckBalance = LangText(
  zhCN: '刷新余额',
  enUS: 'Check Balance',
  jaJP: '残高を更新',
  deDE: 'Kontostand aktualisieren',
);

const LangText _kDepositCredited = LangText(
  zhCN: '您的充值已入账！',
  enUS: 'Your deposit is credited!',
);

const LangText _kDepositPending = LangText(
  zhCN: '您的充值尚未到账，请稍后再试。\n如超过一分钟仍未到账，请联系客服。',
  enUS: 'Your deposit is still on the way, please try again later.\nIf it is not credited after one minute, please contact customer service.',
  jaJP: '入金はまだ反映されていません。しばらくしてからもう一度お試しください。\n1分以上経過しても反映されない場合は、カスタマーサービスまでご連絡ください。',
  deDE: 'Ihre Einzahlung ist noch nicht eingegangen, bitte versuchen Sie es später erneut.\nWenn die Gutschrift nach einer Minute noch nicht erfolgt ist, wenden Sie sich bitte an den Kundenservice.',
);

const LangText _kBonus = LangText(zhCN: '赠送', enUS: 'Bonus');

const LangText _kCustomerService = LangText(zhCN: '客服', enUS: 'Customer\nService');

const LangText _kThanksSupport = LangText(
  zhCN: '衷心感谢您的支持！\n有任何问题，敬请联系',
  enUS: 'Sincerely thank you for support!\nFor any questions, please contact',
);

class PartDeposit extends ConsumerStatefulWidget {
  const PartDeposit({
    super.key,
    this.depositTitle,
    this.depositAmountMax = 10000000,
    this.depositOnly = false,
    this.payTitle,
    this.payAmountInit = 100,
    this.payAmountPrompt,
    this.payNotes,
    this.payHelpLink = '',
    this.submitText,
    this.submitAction,
    this.isPaying = false,
    this.onClose,
  });

  /// 充值区标题（源项目 `depositTitle`）。
  final LangText? depositTitle;
  final num depositAmountMax;

  /// 只做充值（不显示 PAY 模式）。
  final bool depositOnly;

  /// 支付区标题 / 初始金额 / 金额输入提示（为空则只显示金额）。
  final LangText? payTitle;
  final num payAmountInit;
  final LangText? payAmountPrompt;
  final LangText? payNotes;
  final String payHelpLink;


  /// 提交按钮文案与动作（[submitAction] 收本次支付金额）。
  final LangText? submitText;
  final Future<void> Function(num payAmount)? submitAction;
  final bool isPaying;

  /// 关闭面板（源项目 `$emit('closeMe')`）。
  final VoidCallback? onClose;

  @override
  ConsumerState<PartDeposit> createState() => _PartDepositState();
}

class _PartDepositState extends ConsumerState<PartDeposit> {
  late String _payOrDeposit = widget.depositOnly ? 'DEPOSIT' : 'PAY';

  late num _payAmount = widget.payAmountInit;
  num _depositAmount = 0;

  late DepositCoin _coinNow = depositCoinSet['USDT']!;
  late String _usdtChainNow = _coinNow.chains.keys.first;
  late String _cnyChannelNow = depositCoinSet['CNY']!.providers.keys.first;

  bool _refreshing = false;
  LangText? _depositFeedback;
  String _cnyPayUrl = '';

  @override
  void initState() {
    super.initState();
    _depositAmount = _initAmount();
    _updateCnyPayUrl();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listenRecharge());
  }

  /// 源项目 watch（`depositCoinNow.coinCode` immediate）：取「下限 / 差额 / 默认值」的最大值。
  /// 差额用于**余额不足时自动补到刚好够**（用 `Math.ceil` 向上取整，避免四舍五入后仍不够）。
  num _initAmount() {
    final Envar envar = ref.read(envarProvider);
    final bool admin = kDepositAdminUsidList
        .contains(ref.read(onlineUserProvider)['usid']?.toString() ?? '');
    final num minAmount = admin ? 0.01 : envar.depositAmountMin;

    num gap = 0;
    final num balance = _numOf(ref.read(onlineUserProvider)['balanceTUC']);
    if (balance < _payAmount) {
      final num rate = _numOf(envar.coinToTUC[_coinNow.coin.coinCode]);
      if (rate > 0) {
        gap = (((_payAmount - balance) / rate) * 100).ceil() / 100;
      }
    }
    return <num>[minAmount, gap, envar.depositAmountDefault]
        .reduce((num a, num b) => a > b ? a : b);
  }

  static num _numOf(Object? value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;

  bool get _isAdmin => kDepositAdminUsidList
      .contains(ref.read(onlineUserProvider)['usid']?.toString() ?? '');

  num get _step => _isAdmin ? 0.01 : 1;

  num get _amountMin {
    final Envar envar = ref.read(envarProvider);
    final num minAmount = _isAdmin ? 0.01 : envar.depositAmountMin;
    num gap = 0;
    final num balance = _numOf(ref.read(onlineUserProvider)['balanceTUC']);
    if (balance < _payAmount) {
      final num rate = _numOf(envar.coinToTUC[_coinNow.coin.coinCode]);
      if (rate > 0) {
        gap = (((_payAmount - balance) / rate) * 100).ceil() / 100;
      }
    }
    return <num>[minAmount, gap].reduce((num a, num b) => a > b ? a : b);
  }

  bool get _isValidAmount =>
      _depositAmount > 0 &&
      _depositAmount >= _amountMin &&
      _depositAmount <= widget.depositAmountMax;

  num get _tucPaid =>
      numberPrecision(_depositAmount * _numOf(ref.read(envarProvider).coinToTUC[_coinNow.coin.coinCode]));

  num get _tucBonus =>
      numberPrecision(_tucPaid * ref.read(envarProvider).depositBonusRate);

  num get _tucToAdd => numberPrecision(_tucPaid + _tucBonus);

  String get _usdtAddress =>
      ref.read(onlineUserProvider)['caddTUC']?.toString() ?? '';

  /// USDT 支付门户链接（源项目 `usdtPayPortalUrl`）。
  String get _usdtPayPortalUrl {
    final Map<String, dynamic> user = ref.read(onlineUserProvider);
    return '${depositUsdt.payPortalRoot}'
        'appkey=${ref.read(brandProvider).appkey}'
        '&amount=$_depositAmount'
        '&dpamount=$_depositAmount'
        '&toadd=$_usdtAddress'
        '&chain=$_usdtChainNow'
        '&coin=${_coinNow.coin.coinCode}'
        '&usid=${user['usid'] ?? ''}'
        '&clid=${ref.read(localStoreProvider).getString(LocalStore.keyClid)}';
  }

  /// CNY 支付门户链接（源项目 `cnyPayPortalUrl`，含订单号）。
  String get _cnyPayPortalUrl {
    final Map<String, dynamic> user = ref.read(onlineUserProvider);
    final String orderCode = _makeOrderNo();
    final Map<String, String> qso = <String, String>{
      'provider': _cnyChannelNow,
      'appkey': ref.read(brandProvider).appkey,
      'usid': user['usid']?.toString() ?? '',
      'clid': ref.read(localStoreProvider).getString(LocalStore.keyClid),
      'm': '${(_depositAmount * 100).toInt()}',
      'dpamount': '$_depositAmount',
      'orderCode': orderCode,
      'title':
          '${ll(ref.read(languageProvider), ref.read(envarProvider).callnames)}_$_tucToAdd${ref.read(envarProvider).tucSymbol}',
      'note': '(haid_${user['haid'] ?? ''})',
    };
    final String query =
        qso.entries.map((MapEntry<String, String> e) => '${e.key}=${e.value}').join('&');
    return '${depositCoinSet['CNY']!.payPortalRoot}$query';
  }

  /// 业务订单号（源项目 `make_order_no`：20-28 位，`u` 表示来自客户端）。
  ///
  /// 注意：源项目用 `String(Math.random()).substring(2, 14)` 取 12 位随机数；
  /// Dart 的 `Random.nextInt` 上限是 2^32，**不能**直接 `nextInt(999999999999)`（会抛 RangeError，
  /// 我就是这么踩坑的），所以逐位生成 12 个数字。
  static String _makeOrderNo() {
    final Random random = Random();
    final String randomCode =
        List<String>.generate(12, (_) => '${random.nextInt(10)}').join();
    return 't${DateTime.now().millisecondsSinceEpoch}_u$randomCode';
  }

  /// 重算 CNY 支付门户链接（源项目 watch `depositAmount` / `cnyChannelNow`）。
  ///
  /// 只在「币种是 CNY + 金额有效」时才更新；否则保留上一次的值
  /// （源项目同样注释说明：对无效金额不要清空链接，否则二维码会变成等待状态）。
  void _updateCnyPayUrl() {
    if (_coinNow.coin.coinCode != 'CNY') return;
    if (!_isValidAmount) return;
    _cnyPayUrl = _cnyPayPortalUrl;
  }

  /// 二维码内容：CNY 用支付门户链接（含订单号），USDT 用收款地址。
  String get _qrValue => _coinNow.coin.coinCode == 'CNY' ? _cnyPayUrl : _usdtAddress;

  /// 监听实时通道的到账推送（源项目 `RECHARGE_SUCCESS`）。
  void _listenRecharge() {
    ref.read(socketProvider.notifier).events.listen((Map<String, dynamic> event) {
      if (!mounted) return;
      if (event['skevent']?.toString() != 'RECHARGE_SUCCESS') return;
      final String myUsid = ref.read(onlineUserProvider)['usid']?.toString() ?? '';
      final String target = event['usid']?.toString() ?? '';
      if (target.isNotEmpty && target != myUsid) return;

      final Map<String, dynamic> patch = <String, dynamic>{};
      final num balance = _numOf(event['balanceTUC']);
      final num sumInRecharges = _numOf(event['sumInRecharges']);
      if (balance > _numOf(ref.read(onlineUserProvider)['balanceTUC'])) {
        patch['balanceTUC'] = balance;
      }
      if (sumInRecharges >
          _numOf(ref.read(onlineUserProvider)['sumInRecharges'])) {
        patch['sumInRecharges'] = sumInRecharges;
      }
      if (patch.isNotEmpty) {
        ref.read(appStartupProvider.notifier).mergeOnlineUser(patch);
        setState(() {});
      }
      _confirmDepositDone(_numOf(event['txAmount']));
    });
  }

  /// 到账确认弹窗（源项目 `confirm_deposit_done`）。
  Future<void> _confirmDepositDone(num txAmount) async {
    setState(() => _depositFeedback = null);
    final Envar envar = ref.read(envarProvider);
    await showPexModal(
      context,
      ref,
      title: _kDepositCredited,
      content: txAmount > 0
          ? LangText.from('${numberPrecision(txAmount)}${envar.tucSymbol}')
          : null,
    );
    if (!mounted) return;
    if (widget.depositOnly) {
      widget.onClose?.call();
    } else {
      setState(() => _payOrDeposit = 'PAY');
    }
  }

  /// 「刷新余额」：查后端余额，比本地大就认为到账（源项目 `to_refresh_balance`）。
  Future<void> _refreshBalance() async {
    if (_refreshing) return;
    setState(() {
      _depositFeedback = null;
      _refreshing = true;
    });
    final Map<String, dynamic> data = await ref
        .read(userApiProvider)
        .getCurrentBalance(coin: ref.read(envarProvider).str('coinKey'));
    if (!mounted) return;
    setState(() => _refreshing = false);

    if (!bok(data['_state']?.toString())) {
      final LangText message = LangText.fromMap(data['_msg']);
      setState(() => _depositFeedback =
          message.isEmpty ? PartTexts.systemDown : message);
      return;
    }
    final num balance = _numOf(data['balanceTUC']);
    final num myBalance = _numOf(ref.read(onlineUserProvider)['balanceTUC']);
    if (balance > myBalance) {
      ref.read(appStartupProvider.notifier).mergeOnlineUser(<String, dynamic>{
        'balanceTUC': balance,
        'sumInRecharges': _numOf(data['sumInRecharges']),
      });
      await _confirmDepositDone(numberPrecision(balance - myBalance));
      return;
    }
    setState(() => _depositFeedback = _kDepositPending);
    Future<void>.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _depositFeedback = null);
    });
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final bool socketAlive = ref.watch(socketProvider).alive;
    final Map<String, dynamic> user = ref.watch(onlineUserProvider);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 640),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.onClose != null)
              PartCloseButton(onClose: widget.onClose!),
            if (_payOrDeposit == 'PAY')
              _payBlock(lang, envar)
            else
              _depositBlock(lang, envar, socketAlive, user),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- PAY 模式

  Widget _payBlock(String lang, Envar envar) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
            child: Text(
              ll(lang, widget.payTitle ?? const LangText(zhCN: '', enUS: '')),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          if (widget.payAmountPrompt != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: '$_payAmount'),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF29100),
                      ),
                      onChanged: (String value) {
                        final num? parsed = num.tryParse(value);
                        if (parsed != null) {
                          setState(() => _payAmount = parsed);
                        }
                      },
                      decoration: InputDecoration(
                        hintText:
                            ll(lang, widget.payAmountPrompt ?? _kPay),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    envar.tucSymbol,
                    style: const TextStyle(fontSize: 20, color: Color(0xFFF29100)),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: Text(
                '${_payAmount == 0 ? 0 : _payAmount}${envar.tucSymbol}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF29100),
                ),
              ),
            ),
          if (widget.payNotes != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                ll(lang, widget.payNotes!),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: PexColors.greyA, height: 1.5),
              ),
            ),
          if (widget.payHelpLink.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: PartLinkhelp(helpLink: widget.payHelpLink),
              ),
            ),
          _submitButton(lang, envar),
        ],
      ),
    );
  }

  Widget _submitButton(String lang, Envar envar) {
    return SizedBox(
      height: 60,
      child: FilledButton(
        onPressed: widget.isPaying
            ? null
            : () {
                final num balance =
                    _numOf(ref.read(onlineUserProvider)['balanceTUC']);
                if (_payAmount == 0 || _payAmount <= balance) {
                  widget.submitAction?.call(_payAmount);
                } else {
                  // 余额不够 → 切到充值（源项目同样处理）。
                  setState(() {
                    _payOrDeposit = 'DEPOSIT';
                    _depositAmount = _initAmount();
                  });
                }
              },
        style: FilledButton.styleFrom(
          backgroundColor: ref.watch(brandProvider).mainColor,
          shape: const RoundedRectangleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          ll(lang, widget.submitText ?? _kPay),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ DEPOSIT 模式

  Widget _depositBlock(
    String lang,
    Envar envar,
    bool socketAlive,
    Map<String, dynamic> user,
  ) {
    final bool isCny = _coinNow.coin.coinCode == 'CNY';
    return Container(
      color: PexColors.greyE,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            ll(lang, widget.depositTitle ?? _kDeposit),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          PartBreathingOpacity(
            isBreathing: !socketAlive,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(_kCurrentBalance.resolve(lang),
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      '${numberPrecision(user['balanceTUC'])} ${envar.tucSymbol}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _amountRow(lang, envar),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            child: Column(
              children: <Widget>[
                if (isCny) _cnySection(lang, envar) else _usdtSection(lang, envar),
              ],
            ),
          ),
          _refreshRow(lang),
        ],
      ),
    );
  }

  /// 金额步进 + 币种选择 + 换算结果。
  Widget _amountRow(String lang, Envar envar) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        children: <Widget>[
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: PexColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  onPressed: () => setState(() {
                    _depositAmount = numberPrecision(_depositAmount - _step);
                    if (!_isValidAmount) _depositAmount = _amountMin;
                    _updateCnyPayUrl();
                  }),
                  icon: const Icon(Icons.remove, size: 16, color: Color(0xFF007BFF)),
                  visualDensity: VisualDensity.compact,
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    '$_depositAmount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007BFF),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _depositAmount = numberPrecision(_depositAmount + _step);
                    if (_depositAmount > widget.depositAmountMax) {
                      _depositAmount = _amountMin;
                    }
                    _updateCnyPayUrl();
                  }),
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFF007BFF)),
                  visualDensity: VisualDensity.compact,
                ),
                InkWell(
                  onTap: _pickCoin,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.transparent,
                    child: Row(
                      children: <Widget>[
                        Text(
                          _coinNow.coin.coinCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF007BFF),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.keyboard_arrow_down, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '= $_tucPaid${envar.tucSymbol}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 18),
                ),
                if (_tucBonus > 0)
                  Text(
                    '+ ${ll(lang, _kBonus)} $_tucBonus',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 币种选择（复用 `PartCoinTable`）。
  Future<void> _pickCoin() async {
    final List<Coin> coins = depositCoinSet.values
        .map((DepositCoin item) => item.coin)
        .toList();
    final Coin? picked = await showCoinTableSheet(
      context,
      coins: coins,
      current: _coinNow.coin,
    );
    if (picked == null || !mounted) return;
    final DepositCoin next = depositCoinSet[picked.coinCode]!;
    setState(() {
      _coinNow = next;
      _usdtChainNow =
          next.chains.isEmpty ? '' : next.chains.keys.first;
      // 切换币种后金额要按新的换算比重新取（源项目 watch 的行为）。
      _depositAmount = _initAmount();
      _updateCnyPayUrl();
    });
  }

  /// CNY：渠道选择 + 二维码 + 链接 + 复制/分享。
  Widget _cnySection(String lang, Envar envar) {
    final Map<String, LangText> providers = depositCoinSet['CNY']!.providers;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: _cnyChannelNow,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<String>>[
                  for (final MapEntry<String, LangText> entry in providers.entries)
                    DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(
                        entry.value.resolve(lang),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: PexColors.blueMy,
                        ),
                      ),
                    ),
                ],
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() {
                    _cnyChannelNow = value;
                    _updateCnyPayUrl();
                  });
                },
              ),
              const SizedBox(height: 6),
              Text(
                _cnyHint(lang, _cnyChannelNow == 'wxpay'),
                style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 2),
          child: _qrValue.isEmpty
              ? const SizedBox(width: 160, height: 160)
              : QrImageView(data: _qrValue, size: 160),
        ),
      ],
    );
  }

  static String _cnyHint(String lang, bool wxpay) {
    if (wxpay) {
      return const LangText(
        zhCN: '请用微信扫码，或将链接转发到微信中打开',
        enUS: 'Scan the QR code or open the link in Wechat',
        jaJP: 'QRコードをスキャンするか、リンクをWechatで開いてください',
        deDE: 'Scannen Sie den QR-Code oder öffnen Sie den Link in Wechat',
      ).resolve(lang);
    }
    return const LangText(
      zhCN: '请用支付宝扫码，或在浏览器中打开下方链接',
      enUS: 'Scan the QR code with Alipay, or open the link in browser',
      jaJP: 'QRコードをスキャンするか、リンクをブラウザで開いてください',
      deDE: 'Scannen Sie den QR-Code mit Alipay oder öffnen Sie den Link im Browser',
    ).resolve(lang);
  }

  /// USDT：链选择 + 转账说明 + 二维码 + 地址（复制/分享）。
  Widget _usdtSection(String lang, Envar envar) {
    final DepositChain? chain = _coinNow.chains[_usdtChainNow];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: _usdtChainNow,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String>>[
                      for (final MapEntry<String, DepositChain> entry
                          in _coinNow.chains.entries)
                        DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(
                            entry.value.name.resolve(lang),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: PexColors.blueMy,
                            ),
                          ),
                        ),
                    ],
                    onChanged: (String? value) {
                      if (value == null) return;
                      setState(() => _usdtChainNow = value);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        height: 1.3,
                      ),
                      children: <InlineSpan>[
                        TextSpan(
                          text: const LangText(
                            zhCN: '请发送',
                            enUS: 'Please transfer',
                            jaJP: '送金してください',
                            deDE: 'Bitte überweisen',
                          ).resolve(lang),
                        ),
                        TextSpan(
                          text: ' ${chain?.name.resolve(lang) ?? ''} USDT ',
                          style: const TextStyle(
                            color: PexColors.blueMy,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _openUrl(chain?.contractScanner ?? ''),
                        ),
                        TextSpan(
                          text: const LangText(
                            zhCN: '到您的专属充值地址',
                            enUS: 'to your exclusive deposit address',
                            jaJP: 'あなたの専用入金アドレスに送金してください',
                            deDE: 'an Ihre exklusive Einzahlungsadresse',
                          ).resolve(lang),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 2),
              child: _usdtAddress.isEmpty
                  ? const SizedBox(width: 160, height: 160)
                  : QrImageView(data: _usdtAddress, size: 160),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _usdtAddress,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              PartIcontextCopy(
                onCopy: () => Clipboard.setData(
                  ClipboardData(text: _usdtAddress),
                ),
              ),
              PartIcontextPop(
                onPop: () => showPopLinkSheet(
                  context,
                  ref,
                  shareTitle: const LangText(
                    zhCN: '连接您的钱包',
                    enUS: 'Connect Your Wallet',
                  ),
                  shareUrl: _usdtPayPortalUrl,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 底部：刷新余额 + 客服入口。
  Widget _refreshRow(String lang) {
    return Column(
      children: <Widget>[
        if (_depositFeedback != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              _depositFeedback!.resolve(lang),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFFDD6161)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: <Widget>[
              PartButtonSubmit(
                fullWidth: false,
                height: 46,
                disabled: !_isValidAmount || _refreshing,
                loading: _refreshing,
                onPressed: _refreshBalance,
                children: <Widget>[
                  Text(
                    _kCheckBalance.resolve(lang),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const Spacer(),
              InkWell(
                onTap: () => context.push(AppRoutes.path(AppRoutes.umyContact)),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PexIcon.uni('chat', size: 22, color: PexColors.grey6),
                      Text(
                        _kCustomerService.resolve(lang),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: <Widget>[
              Flexible(
                child: InkWell(
                  onTap: () => _openUrl(
                    _coinNow.coin.coinCode == 'CNY' ? _cnyPayUrl : _usdtAddress,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PexIcon.icont('hyperlink', size: 14, color: PexColors.blueMy),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          _coinNow.coin.coinCode == 'CNY'
                              ? _cnyPayUrl
                              : _usdtAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: PexColors.blueMy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PartIcontextCopy(
                onCopy: () => Clipboard.setData(
                  ClipboardData(
                    text: _coinNow.coin.coinCode == 'CNY'
                        ? _cnyPayUrl
                        : _usdtAddress,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            _kThanksSupport.resolve(lang),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, color: PexColors.subtext),
          ),
        ),
      ],
    );
  }
}
