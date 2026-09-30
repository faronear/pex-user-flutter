/// 货币状态，对应源项目 `wo.ss.i18n.{bankcoinNow, cryptocoinNow, bankcoinSet, cryptocoinSet}`。
///
/// **与源项目的有意差异**：源项目在 `umyConfig` 里换币只改内存变量
/// （源码注释 `todo: 通知后台修改`），刷新即丢；本实现**写入本地存储**，
/// 由老板 2026-09-30 确认。默认值仍与源项目一致：
/// 法币按用户所在地区取（CN→CNY，其余→USD），加密币取 `TUC`。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/coins.dart';
import '../storage/local_store.dart';
import 'app_providers.dart';
import 'region_provider.dart';

class CoinState {
  const CoinState({required this.bankCoin, required this.cryptoCoin});

  /// 当前法币（源项目 `bankcoinNow`）。
  final Coin bankCoin;

  /// 当前加密币（源项目 `cryptocoinNow`）。
  final Coin cryptoCoin;

  CoinState copyWith({Coin? bankCoin, Coin? cryptoCoin}) => CoinState(
        bankCoin: bankCoin ?? this.bankCoin,
        cryptoCoin: cryptoCoin ?? this.cryptoCoin,
      );
}

class CoinNotifier extends Notifier<CoinState> {
  @override
  CoinState build() {
    final LocalStore store = ref.watch(localStoreProvider);
    final String land = ref.watch(userlandCodeProvider);
    return CoinState(
      // 本地已存的选择优先，否则按所在地区取默认（与源项目 App.vue 的逻辑一致）。
      bankCoin: bankCoinByCode(store.getString(LocalStore.keyBankcoinCode)) ??
          bankCoinForLand(land),
      cryptoCoin: cryptoCoinByCode(store.getString(LocalStore.keyCryptocoinCode)) ??
          kCryptocoinDefault,
    );
  }

  /// 选定法币（对应源项目 `to_change_bankcoin`）。
  Future<void> setBankCoin(Coin coin) async {
    await ref
        .read(localStoreProvider)
        .setString(LocalStore.keyBankcoinCode, coin.coinCode);
    state = state.copyWith(bankCoin: coin);
  }

  /// 选定加密币（对应源项目 `to_change_cryptocoin`）。
  Future<void> setCryptoCoin(Coin coin) async {
    await ref
        .read(localStoreProvider)
        .setString(LocalStore.keyCryptocoinCode, coin.coinCode);
    state = state.copyWith(cryptoCoin: coin);
  }
}

final NotifierProvider<CoinNotifier, CoinState> coinProvider =
    NotifierProvider<CoinNotifier, CoinState>(CoinNotifier.new);
