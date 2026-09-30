// 生成 `lib/core/i18n/coins.dart`（法定货币 / 加密货币常量）。
//
// 数据源：源项目 `pex-user-uniapp` 的依赖包 `wo-core-i18n`（客户端常量，后端不下发）。
// 用法：`node tool/genCoins.js [wo-core-i18n 所在目录]`
// 默认路径：`../pex-user-uniapp/node_modules/wo-core-i18n`
//
// 只保留页面用得到的字段（coinCode / coinSymbol / coinPrecision / coinIname / coinSupply），
// 去掉 `usedIn`、`coinNumber` 等仅后端对账用的字段，以控制体积。
const fs = require('fs');
const path = require('path');

const pkg = process.argv[2] ||
  path.resolve(__dirname, '../../pex-user-uniapp/node_modules/wo-core-i18n');
const { bankcoinSet, cryptocoinSet } = require(pkg);

const out = path.resolve(__dirname, '../lib/core/i18n/coins.dart');

/// Dart 单引号字符串转义（注意 `$` 在 Dart 里是插值符）。
const dartStr = (s) => `'${String(s).replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\$/g, '\\$')}'`;

const precision = (v) => {
  const n = Number(v);
  return Number.isFinite(n) ? n : 2;
};

function coinLines(set, { withSupply = false } = {}) {
  return Object.keys(set)
    .sort()
    .map((key) => {
      const c = set[key];
      const name = c.coinIname || {};
      const parts = [
        `coinCode: ${dartStr(c.coinCode || key)}`,
        `coinSymbol: ${dartStr(c.coinSymbol || '')}`,
        `coinPrecision: ${precision(c.coinPrecision)}`,
        `nameEn: ${dartStr(name.enUS || c.coinCode || key)}`,
        `nameZh: ${dartStr(name.zhCN || name.enUS || c.coinCode || key)}`,
      ];
      if (withSupply && c.coinSupply != null) {
        parts.push(`coinSupply: ${Number(c.coinSupply)}`);
      }
      return `  Coin(${parts.join(', ')}),`;
    })
    .join('\n');
}

const body = `// 由 \`wo-core-i18n\` 自动生成，请勿手工编辑。
// 生成方式：\`node tool/genCoins.js\`（数据源 = 源项目 pex-user-uniapp 的依赖包 wo-core-i18n）。
// ignore_for_file: constant_identifier_names

import 'lang_text.dart';

/// 一种货币，对应源项目 \`wo.ss.i18n.bankcoinSet\` / \`cryptocoinSet\` 的条目。
class Coin {
  const Coin({
    required this.coinCode,
    required this.coinSymbol,
    required this.coinPrecision,
    required this.nameEn,
    required this.nameZh,
    this.coinSupply,
  });

  /// 币种代码，如 \`USD\` / \`BTC\`。
  final String coinCode;

  /// 货币符号，如 \`$\` / \`₿\`。
  final String coinSymbol;

  /// 小数位数。
  final int coinPrecision;

  final String nameEn;
  final String nameZh;

  /// 发行总量（仅加密货币有）。
  final int? coinSupply;

  /// 多语言名称（源项目 \`coinIname\`）。
  LangText get name => LangText(zhCN: nameZh, enUS: nameEn);

  /// 列表行的主显示：\`$ (USD)\` 之类的写法由调用方拼装。
  String get label => nameEn;
}

/// 法定货币（源项目 \`bankcoinSet\`，联合国登记的全部币种）。
const List<Coin> kBankCoins = <Coin>[
${coinLines(bankcoinSet)}
];

/// 加密货币（源项目 \`cryptocoinSet\`）。
const List<Coin> kCryptoCoins = <Coin>[
${coinLines(cryptocoinSet, { withSupply: true })}
];

/// 加密货币选择器里可选的几种（源项目 \`App.data.js\` 的 \`cryptocoinSet\` 子集）。
const List<String> kCryptocoinPickerCodes = <String>['TUC', 'BTC', 'ETH', 'USDT'];

/// 币种代码 → 货币。
final Map<String, Coin> kBankCoinByCode = <String, Coin>{
  for (final Coin coin in kBankCoins) coin.coinCode: coin,
};

final Map<String, Coin> kCryptoCoinByCode = <String, Coin>{
  for (final Coin coin in kCryptoCoins) coin.coinCode: coin,
};

/// 查法定货币；找不到返回 null。
Coin? bankCoinByCode(String? code) =>
    (code == null || code.isEmpty) ? null : kBankCoinByCode[code];

/// 查加密货币；找不到返回 null。
Coin? cryptoCoinByCode(String? code) =>
    (code == null || code.isEmpty) ? null : kCryptoCoinByCode[code];

/// 用户所在地区 → 默认法定货币（源项目 \`App.data.js\` 的 \`land2bankcoin\`：CN→CNY，其余→USD）。
Coin bankCoinForLand(String landCode) =>
    bankCoinByCode(landCode == 'CN' ? 'CNY' : 'USD') ?? kBankCoins.first;

/// 应用内默认加密货币（源项目 \`cryptocoinNow = cryptocoinSet.TUC\`）。
Coin get kCryptocoinDefault =>
    cryptoCoinByCode('TUC') ?? kCryptoCoins.first;

/// 加密货币选择器的候选列表（按 [kCryptocoinPickerCodes] 顺序）。
List<Coin> get kCryptocoinPicker => <Coin>[
      for (final String code in kCryptocoinPickerCodes)
        if (cryptoCoinByCode(code) != null) cryptoCoinByCode(code)!,
    ];
`;

fs.writeFileSync(out, body);
const bankCount = Object.keys(bankcoinSet).length;
const cryptoCount = Object.keys(cryptocoinSet).length;
console.log(`已生成 ${out}`);
console.log(`  法定货币 ${bankCount} 种 / 加密货币 ${cryptoCount} 种 / ${body.length} 字节`);
