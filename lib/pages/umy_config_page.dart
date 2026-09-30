/// 我的设置，对应源项目 `pages/umyConfig.vue`：
/// 界面语言 / 银行货币 / 加密货币 三行。
///
/// 源项目里换币只改内存（`todo: 通知后台修改`），刷新即丢；
/// 本实现**存本地**（老板 2026-09-30 确认），见 `core/state/coin_provider.dart`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/appmeta/page_meta.dart';
import '../core/i18n/coins.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/router/app_router.dart';
import '../core/state/coin_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/part_coin_table.dart';
import '../widgets/part_lang_table.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_window_layout.dart';

const LangText _kLanguage = LangText(zhCN: '界面语言', enUS: 'Language');

const LangText _kBankCurrency = LangText(zhCN: '银行货币', enUS: 'Bank Currency');

const LangText _kCryptoCurrency =
    LangText(zhCN: '加密货币', enUS: 'Crypto Currency');

class UmyConfigPage extends ConsumerWidget {
  const UmyConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CoinState coins = ref.watch(coinProvider);

    return PartWindowLayout(
      pageName: AppRoutes.umyConfig,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: <Widget>[
                PartNavibarPcFixed(
                  title: pageMetaOf(AppRoutes.umyConfig)?.i18nPageTitle,
                  pageName: AppRoutes.umyConfig,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: PexColors.greyE),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(color: Color(0x1A000000), blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      _row(
                        ref,
                        icon: PexIcons.icont('icont-multilang'),
                        title: _kLanguage,
                        footer: PartLangTable(color: PexColors.blueMy),
                      ),
                      _row(
                        ref,
                        icon: PexIcons.icont('icont-bankcoins'),
                        title: _kBankCurrency,
                        footer: _picker(
                          text: '${coins.bankCoin.name.resolve(ref.watch(languageProvider))}'
                              ' (${coins.bankCoin.coinCode})',
                          onTap: () => _pickBankCoin(context, ref),
                        ),
                      ),
                      _row(
                        ref,
                        icon: PexIcons.icont('icont-cryptocoins'),
                        title: _kCryptoCurrency,
                        footer: _picker(
                          text:
                              '${coins.cryptoCoin.name.resolve(ref.watch(languageProvider))}'
                              ' (${coins.cryptoCoin.coinCode})',
                          onTap: () => _pickCryptoCoin(context, ref),
                        ),
                        last: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickBankCoin(BuildContext context, WidgetRef ref) async {
    final Coin current = ref.read(coinProvider).bankCoin;
    final Coin? picked = await showCoinTableSheet(
      context,
      coins: kBankCoins,
      current: current,
    );
    if (picked == null) return;
    await ref.read(coinProvider.notifier).setBankCoin(picked);
  }

  Future<void> _pickCryptoCoin(BuildContext context, WidgetRef ref) async {
    final Coin current = ref.read(coinProvider).cryptoCoin;
    final Coin? picked = await showCoinTableSheet(
      context,
      coins: kCryptocoinPicker,
      current: current,
    );
    if (picked == null) return;
    await ref.read(coinProvider.notifier).setCryptoCoin(picked);
  }

  Widget _row(
    WidgetRef ref, {
    required PexGlyph? icon,
    required LangText title,
    required Widget footer,
    bool last = false,
  }) {
    final String lang = ref.watch(languageProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: PexColors.bg)),
      ),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PexIcon(icon, size: 22, color: PexColors.grey3),
          ),
          Expanded(
            child: Text(
              ll(lang, title),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const SizedBox(width: 10),
          footer,
        ],
      ),
    );
  }

  /// 可点击的「名称 (代码) ⌄」胶囊（源项目 `.wocTextcolorBlueMy` 按钮）。
  Widget _picker({
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, color: PexColors.blueMy),
              ),
            ),
            PexIcon.uni('bottom', size: 18, color: PexColors.blueMy),
          ],
        ),
      ),
    );
  }
}
