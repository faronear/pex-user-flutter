/// 提现渠道的可选币种配置，对应源项目 `App.data.js` 里的 `wo.ss.i18n.paytoCoinSet`。
///
/// **如实说明**：源项目当前只配置了 `TUC`（链 + 钱包地址两个字段）；
/// 页面模板里还写有 USDT / CNY / USD / EWALLET 四个分支，但配置里并不存在，
/// 属于「没有启用的死分支」。迁移版按**配置驱动**实现：只要往这里加币种与字段，
/// 表单会自动多出对应输入项，无需改页面代码。
library;

import 'coins.dart';
import 'lang_text.dart';

/// 渠道表单里的一个字段。
class PaytoField {
  const PaytoField({
    required this.key,
    required this.title,
    this.placeholder,
    this.chainTypeSet = const <String, LangText>{},
    this.providerTypeSet = const <String, LangText>{},
    this.inCard = true,
  });

  /// 形如 `TUC_chainType` / `TUC_accountId`（前缀必须是所属币种代码）。
  final String key;
  final LangText title;
  final LangText? placeholder;

  /// 区块链选项（`*_chainType` 字段用）。
  final Map<String, LangText> chainTypeSet;

  /// 电子钱包服务商选项（`*_providerType` 字段用）。
  final Map<String, LangText> providerTypeSet;

  /// 是否在渠道卡片上展示。
  final bool inCard;
}

/// 一种可用于提现的币种。
class PaytoCoin {
  const PaytoCoin({required this.coin, required this.fields});

  final Coin coin;
  final List<PaytoField> fields;

  /// 该币种的钱包地址是否必须形如 `0x` + 40 位十六进制（TUC / USDT）。
  bool get isChainAddress =>
      coin.coinCode == 'TUC' || coin.coinCode == 'USDT';

  /// 该币种是否为加密币（换算金额时用 6 位小数，法币用 2 位）。
  bool get isCrypto => cryptoCoinByCode(coin.coinCode) != null;
}

const LangText _kBlockchain = LangText(
  zhCN: '区块链',
  enUS: 'Blockchain',
  jaJP: 'ブロックチェーン',
  deDE: 'Blockchain',
);

const LangText _kWalletAddress = LangText(
  zhCN: '钱包地址',
  enUS: 'Wallet Address',
  jaJP: 'ウォレットアドレス',
  deDE: 'Wallet-Adresse',
);

const LangText _kWalletAddressHint = LangText(
  zhCN: '请输入您的个人钱包地址',
  enUS: 'Your private wallet address on the blockchain selected above',
  jaJP: '選択したブロックチェーン上のプライベートウォレットアドレスを入力してください',
  deDE: 'Geben Sie Ihre privaten Wallet-Adresse auf der Blockchain oben ein',
);

const LangText _kPolygon = LangText(
  zhCN: 'Polygon',
  enUS: 'Polygon',
  jaJP: 'Polygon',
  deDE: 'Polygon',
);

/// 提现渠道可选币种（源项目 `paytoCoinSet`）。
Map<String, PaytoCoin> get paytoCoinSet => <String, PaytoCoin>{
      'TUC': PaytoCoin(
        coin: cryptoCoinByCode('TUC')!,
        fields: const <PaytoField>[
          PaytoField(
            key: 'TUC_chainType',
            title: _kBlockchain,
            chainTypeSet: <String, LangText>{'MATIC_MAINNET': _kPolygon},
          ),
          PaytoField(
            key: 'TUC_accountId',
            title: _kWalletAddress,
            placeholder: _kWalletAddressHint,
          ),
        ],
      ),
    };

/// 取某币种下第一个字段的默认值（链/服务商取第一项，其余为空）。
Map<String, dynamic> defaultPaytoChannel(String coinType) {
  final PaytoCoin? payto = paytoCoinSet[coinType];
  final Map<String, dynamic> channel = <String, dynamic>{
    'coinType': coinType,
  };
  if (payto == null) return channel;
  for (final PaytoField field in payto.fields) {
    if (field.chainTypeSet.isNotEmpty) {
      channel[field.key] = field.chainTypeSet.keys.first;
    } else if (field.providerTypeSet.isNotEmpty) {
      channel[field.key] = field.providerTypeSet.keys.first;
    } else {
      channel[field.key] = '';
    }
  }
  return channel;
}
