/// 新建提现渠道，对应源项目 `pages/umyFundChannelCreate.vue`。
///
/// 表单**由配置驱动**（[paytoCoinSet]）：源项目模板里写死了 TUC/USDT/CNY/USD/EWALLET
/// 五个分支，但配置里只有 TUC —— 迁移版按配置渲染，往配置里加币种即可自动多出对应输入项。
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
import '../theme/app_theme.dart';
import '../widgets/part_button_submit.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_window_layout.dart';

const LangText _kCurrency = LangText(
  zhCN: '货币',
  enUS: 'Currency',
  jaJP: '通貨',
  deDE: 'Währung',
);

const LangText _kCurrencyHint = LangText(
  zhCN: '将要提现的货币',
  enUS: 'The currency for withdrawal',
  jaJP: '通貨を選択してください',
  deDE: 'Die Währung für Ihre Abhebung aus',
);

const LangText _kChainWarning = LangText(
  zhCN: '您必须正确选择您的钱包所在的区块链网络，否则您的提现将会丢失，无法找回！',
  enUS: 'You must select the blockchain network that matches your private wallet; otherwise, your cashout will be lost and cannot be recovered!',
  jaJP: 'ブロックチェーンネットワークを選択する必要があります。そうしないと、お金を引き出すことができなくなり、取り戻すことができません！',
  deDE: 'Sie müssen die Blockchain-Netzwerk auswählen, das mit Ihrer Wallet übereinstimmt; andernfalls geht Ihr Geld verloren und kann nicht wiederhergestellt werden!',
);

const LangText _kMalformedAddress = LangText(
  zhCN: '地址格式错误',
  enUS: 'Malformed address',
  jaJP: 'アドレス形式が正しくありません',
  deDE: 'Ungültiges Adressformat',
);

const LangText _kMalformed = LangText(
  zhCN: '格式错误',
  enUS: 'Malformed',
  jaJP: '形式が正しくありません',
  deDE: 'Ungültiges Format',
);

const LangText _kSubmit = LangText(
  zhCN: '提交',
  enUS: 'Submit',
  jaJP: '送信',
  deDE: 'Absenden',
);

class UmyFundChannelCreatePage extends ConsumerStatefulWidget {
  const UmyFundChannelCreatePage({super.key});

  @override
  ConsumerState<UmyFundChannelCreatePage> createState() =>
      _UmyFundChannelCreatePageState();
}

class _UmyFundChannelCreatePageState
    extends ConsumerState<UmyFundChannelCreatePage> {
  late String _coinType = paytoCoinSet.keys.first;
  late Map<String, dynamic> _channel = defaultPaytoChannel(_coinType);

  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  bool _loading = false;
  LangText? _feedback;

  TextEditingController _controllerFor(String key) => _controllers.putIfAbsent(
        key,
        () => TextEditingController(
          text: _channel[key]?.toString() ?? '',
        ),
      );

  /// 切换币种：重建整份表单（源项目同样重置 `channelNow`）。
  void _pickCoinType(String coinType) {
    setState(() {
      _coinType = coinType;
      _channel = defaultPaytoChannel(coinType);
      _controllers.clear();
      _feedback = null;
    });
  }

  /// 单字段校验（源项目各分支的 `rules`）。
  LangText? _validateField(PaytoCoin payto, PaytoField field) {
    final String value = (_channel[field.key]?.toString() ?? '').trim();
    if (value.isEmpty) return null; // 必填由后端与提交条件把关，这里只做格式校验
    if (!field.key.endsWith('_accountId')) return null;

    if (payto.isChainAddress) {
      final bool ok =
          RegExp(r'^(0x|0X)?[0-9a-fA-F]{40}$').hasMatch(value);
      return ok ? null : _kMalformedAddress;
    }
    if (payto.coin.coinCode == 'EWALLET') {
      final bool ok = RegExp(r'^[^@\s,]+@[^@\s,]+\.[^@\s,]+$').hasMatch(value);
      return ok ? null : _kMalformedAddress;
    }
    final bool ok = num.tryParse(value) != null;
    return ok ? null : _kMalformed;
  }

  bool get _canSubmit => (_channel['coinType']?.toString() ?? '').isNotEmpty &&
      !_loading;

  /// 提交（源项目 `to_create_payto_channel`）。
  Future<void> _submit() async {
    final PaytoCoin payto = paytoCoinSet[_coinType]!;
    setState(() => _feedback = null);

    for (final PaytoField field in payto.fields) {
      final LangText? invalid = _validateField(payto, field);
      if (invalid != null) {
        setState(() => _feedback = invalid);
        return;
      }
    }

    // 只带上属于当前币种的字段（源项目用 `key.startsWith(coinType)` 过滤）。
    final Map<String, dynamic> newChannel = <String, dynamic>{
      'coinType': _coinType,
      for (final MapEntry<String, dynamic> entry in _channel.entries)
        if (entry.key.startsWith(_coinType)) entry.key: entry.value,
    };

    setState(() => _loading = true);
    final Map<String, dynamic> data =
        await ref.read(userApiProvider).addPaytoChannel(newChannel);
    if (!mounted) return;
    setState(() => _loading = false);

    if (!bok(data['_state']?.toString())) {
      final LangText message = LangText.fromMap(data['_msg']);
      setState(() =>
          _feedback = message.isEmpty ? PartTexts.systemDown : message);
      return;
    }

    // 源项目：把新渠道写进 `onlineUser.paytoChannels`（key = channelUuid）。
    final String channelUuid = data['channelUuid']?.toString() ?? '';
    final Map<String, dynamic> user = ref.read(onlineUserProvider);
    final Map<String, dynamic> channels =
        (user['paytoChannels'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final bool wasEmpty = channels.isEmpty;
    ref.read(appStartupProvider.notifier).mergeOnlineUser(<String, dynamic>{
      'paytoChannels': <String, dynamic>{
        ...channels,
        channelUuid: <String, dynamic>{
          ...newChannel,
          'channelUuid': channelUuid,
          for (final MapEntry<String, dynamic> entry in data.entries)
            if (entry.key != '_state' &&
                entry.key != '_msg' &&
                entry.key != '_passtoken' &&
                entry.key != 'channelUuid')
              entry.key: entry.value,
        },
      },
    });
    if (!mounted) return;
    // 源项目：这是第一个渠道时 `redirectTo` 列表页，否则 `navigateBack`（避免返回时又回到本页）。
    if (wasEmpty) {
      context.go(AppRoutes.path(AppRoutes.umyFundChannel));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final PaytoCoin payto = paytoCoinSet[_coinType]!;
    final List<String> coinTypes = paytoCoinSet.keys.toList();

    return PartWindowLayout(
      pageName: AppRoutes.umyFundChannelCreate,
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
                        const SizedBox(height: 10),
                        _header(_kCurrency, _kCurrencyHint),
                        DropdownButtonFormField<String>(
                          initialValue: _coinType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          items: <DropdownMenuItem<String>>[
                            for (final String key in coinTypes)
                              DropdownMenuItem<String>(
                                value: key,
                                child: Text(
                                  paytoCoinSet[key]!.coin.coinCode,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: PexColors.blueMy,
                                  ),
                                ),
                              ),
                          ],
                          onChanged: coinTypes.length <= 1
                              ? null
                              : (String? value) {
                                  if (value != null) _pickCoinType(value);
                                },
                        ),
                        for (final PaytoField field in payto.fields) ...<Widget>[
                          _header(field.title, null),
                          _fieldWidget(lang, payto, field),
                        ],
                        if (_feedback != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              _feedback!.resolve(lang),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: PexColors.redMy),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: PartButtonSubmit(
                            disabled: !_canSubmit,
                            loading: _loading,
                            onPressed: _submit,
                            children: <Widget>[
                              Text(_kSubmit.resolve(lang)),
                            ],
                          ),
                        ),
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

  Widget _header(LangText title, LangText? info) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title.resolve(ref.read(languageProvider)),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          if (info != null)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                info.resolve(ref.read(languageProvider)),
                style: const TextStyle(fontSize: 12, color: PexColors.grey9),
              ),
            ),
        ],
      ),
    );
  }

  /// 按字段类型渲染：链 → 下拉；服务商 → 下拉；其余 → 输入框。
  Widget _fieldWidget(String lang, PaytoCoin payto, PaytoField field) {
    if (field.chainTypeSet.isNotEmpty) {
      final List<String> keys = field.chainTypeSet.keys.toList();
      final String current = _channel[field.key]?.toString() ?? keys.first;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (payto.isChainAddress)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                _kChainWarning.resolve(lang),
                style: const TextStyle(fontSize: 12, color: PexColors.redMy),
              ),
            ),
          DropdownButtonFormField<String>(
            initialValue: keys.contains(current) ? current : keys.first,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<String>>[
              for (final String key in keys)
                DropdownMenuItem<String>(
                  value: key,
                  child: Text(
                    field.chainTypeSet[key]!.resolve(lang),
                    style: const TextStyle(fontSize: 18, color: PexColors.blueMy),
                  ),
                ),
            ],
            onChanged: keys.length <= 1
                ? null
                : (String? value) {
                    if (value != null) {
                      setState(() => _channel[field.key] = value);
                    }
                  },
          ),
        ],
      );
    }

    if (field.providerTypeSet.isNotEmpty) {
      final List<String> keys = field.providerTypeSet.keys.toList();
      final String current = _channel[field.key]?.toString() ?? keys.first;
      return DropdownButtonFormField<String>(
        initialValue: keys.contains(current) ? current : keys.first,
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: <DropdownMenuItem<String>>[
          for (final String key in keys)
            DropdownMenuItem<String>(
              value: key,
              child: Text(field.providerTypeSet[key]!.resolve(lang)),
            ),
        ],
        onChanged: keys.length <= 1
            ? null
            : (String? value) {
                if (value != null) setState(() => _channel[field.key] = value);
              },
      );
    }

    final TextEditingController controller = _controllerFor(field.key);
    return TextField(
      controller: controller,
      maxLength: payto.isChainAddress ? 42 : null,
      style: TextStyle(letterSpacing: payto.isChainAddress ? 2 : null),
      onChanged: (String value) {
        _channel[field.key] = value;
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: field.placeholder?.resolve(lang),
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
