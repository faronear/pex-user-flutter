/// 充值币种配置，对应源项目 `App.data.js` 里的 `wo.ss.i18n.depositCoinSet`。
///
/// 源项目按 `process.env.NODE_ENV` 在**开发门户**与**生产门户**之间切换；
/// Flutter 侧用 [kReleaseMode] 代替（`--release` 构建走生产门户）。
library;

import 'package:flutter/foundation.dart';

import 'coins.dart';
import 'lang_text.dart';

/// 一条可用链（USDT）。
class DepositChain {
  const DepositChain({
    required this.name,
    required this.contractScanner,
    required this.scannerRoot,
  });

  final LangText name;

  /// 合约在浏览器上的页面（用于「请发送 XX USDT」里的链接）。
  final String contractScanner;

  /// 浏览器根地址（用于 `/address/<地址>`）。
  final String scannerRoot;
}

/// 一种可充值的外部币（CNY / USDT）。
class DepositCoin {
  const DepositCoin({
    required this.coin,
    required this.payPortalRoot,
    this.chains = const <String, DepositChain>{},
    this.providers = const <String, LangText>{},
  });

  final Coin coin;

  /// 支付门户地址前缀（后面拼查询串）。
  final String payPortalRoot;

  /// USDT 支持的公链。
  final Map<String, DepositChain> chains;

  /// CNY 支持的支付渠道。
  final Map<String, LangText> providers;
}

const LangText _kPolygon = LangText(
  zhCN: 'Polygon',
  enUS: 'Polygon',
  jaJP: 'Polygon',
  deDE: 'Polygon',
);

const LangText _kEthereum = LangText(
  zhCN: '以太坊',
  enUS: 'Ethereum',
  jaJP: 'イーサリアム',
  deDE: 'Ethereum',
);

const LangText _kPolygonAmoy = LangText(
  zhCN: 'Polygon Amoy',
  enUS: 'Polygon Amoy',
  jaJP: 'Polygon Amoy',
  deDE: 'Polygon Amoy',
);

const LangText _kEthereumSepolia = LangText(
  zhCN: '以太坊 Sepolia',
  enUS: 'Ethereum Sepolia',
  jaJP: 'イーサリアム Sepolia',
  deDE: 'Ethereum Sepolia',
);

const LangText _kWxPay = LangText(
  zhCN: '微信支付',
  enUS: 'WxPay',
  jaJP: 'WeChat Pay',
  deDE: 'WeChat Pay',
);

const LangText _kAliPay = LangText(
  zhCN: '支付宝',
  enUS: 'Alipay',
  jaJP: 'Alipay',
  deDE: 'Alipay',
);

/// 充值的「USDT」配置。
DepositCoin get depositUsdt => DepositCoin(
      coin: cryptoCoinByCode('USDT')!,
      payPortalRoot: kReleaseMode
          ? 'https://usdt.pay.tic.cc/?coin=usdt&'
          : 'http://localhost:3000/?coin=usdt&',
      chains: kReleaseMode
          ? <String, DepositChain>{
              'MATIC_MAINNET': const DepositChain(
                name: _kPolygon,
                contractScanner:
                    'https://polygonscan.com/token/0xc2132d05d31c914a87c6611c10748aeb04b58e8f',
                scannerRoot: 'https://polygonscan.com',
              ),
              'ETH_MAINNET': const DepositChain(
                name: _kEthereum,
                contractScanner:
                    'https://etherscan.io/token/0xdAC17F958D2ee523a2206206994597C13D831ec7',
                scannerRoot: 'https://etherscan.io',
              ),
            }
          : <String, DepositChain>{
              'MATIC_AMOY': const DepositChain(
                name: _kPolygonAmoy,
                contractScanner:
                    'https://amoy.polygonscan.com/token/0xceC7b5e60d0C6875CBbCA9619cb11389d21d8051',
                scannerRoot: 'https://amoy.polygonscan.com',
              ),
              'ETH_SEPOLIA': const DepositChain(
                name: _kEthereumSepolia,
                contractScanner:
                    'https://sepolia.etherscan.io/token/0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0',
                scannerRoot: 'https://sepolia.etherscan.io',
              ),
            },
    );

/// 充值的「CNY」配置。
DepositCoin get depositCny => DepositCoin(
      coin: bankCoinByCode('CNY')!,
      payPortalRoot: kReleaseMode
          ? 'https://pay.yuanjinx.com/?coin=cny&'
          : 'https://pay.farinear.cn/?coin=cny&',
      providers: const <String, LangText>{
        'wxpay': _kWxPay,
        'alipay': _kAliPay,
      },
    );

/// 可充值的币种集合（源项目 `depositCoinSet`）。
Map<String, DepositCoin> get depositCoinSet => <String, DepositCoin>{
      'USDT': depositUsdt,
      'CNY': depositCny,
    };
