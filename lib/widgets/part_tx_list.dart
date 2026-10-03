/// 收支明细列表，对应源项目 `parts/partTxList.vue`。
///
/// 每行：类型名 + （作品链接 或 金额）+ 日期 + （对方昵称头像 或 支付渠道）+ 带符号的金额。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/api/user_api.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/router/app_routes.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../core/state/tx_provider.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../theme/app_theme.dart';
import 'part_empty_list.dart';
import 'part_load_more.dart';
import 'part_show_loading.dart';
import 'part_texts.dart';

const LangText _kEmpty = LangText(zhCN: '没有找到记录', enUS: 'Not found');

const LangText _kUntitled = LangText(zhCN: '无题', enUS: 'Untitled');

class PartTxList extends ConsumerStatefulWidget {
  const PartTxList({super.key, required this.txTag});

  final String txTag;

  @override
  ConsumerState<PartTxList> createState() => _PartTxListState();
}

class _PartTxListState extends ConsumerState<PartTxList> {
  static const int _takeLimit = 10;

  LoadState _fresh = LoadState.loadFresh;
  LoadState _down = LoadState.loadUp;
  bool _ready = false;

  List<Map<String, dynamic>> get _list =>
      ref.read(txProvider).listOf(widget.txTag);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 100), () async {
      await ref.read(appStartupProvider.notifier).waitAutologin();
      if (!mounted) return;
      // 源项目：该分类没内容且没加载过时才自动拉第一页。
      if (!ref.read(txProvider).loaded.contains(widget.txTag)) {
        await _getOlder();
      }
      if (mounted) setState(() => _ready = true);
    });
  }

  static int _intOf(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  static List<Map<String, dynamic>> _asList(Object? value) => value is List
      ? value
          .whereType<Map>()
          .map((Map item) => item.cast<String, dynamic>())
          .toList()
      : <Map<String, dynamic>>[];

  void _toast(Object? message) {
    final LangText text = LangText.fromMap(message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ll(ref.read(languageProvider),
                text.isEmpty ? PartTexts.systemDown : text),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// 刷新（源项目 `to_get_newest`）：重拉最新一页并覆盖。
  Future<void> _reload() async {
    if (_fresh == LoadState.loading) return;
    setState(() => _fresh = LoadState.loading);
    final Map<String, dynamic> data = await ref.read(userApiProvider).getTxList(
          txTag: widget.txTag,
          takeLimit: _takeLimit,
        );
    if (!mounted) return;
    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> list = _asList(data['txList']);
      ref.read(txProvider.notifier).setList(widget.txTag, list);
      setState(() => _down =
          list.length < _takeLimit ? LoadState.noMore : LoadState.loadUp);
    } else {
      _toast(data['_msg']);
    }
    if (mounted) setState(() => _fresh = LoadState.loadFresh);
  }

  /// 首次 / 加载更多（源项目 `to_get_tx_list`，整表替换 → 这里追加 + 去重）。
  Future<void> _getOlder() async {
    if (_down == LoadState.loading) return;
    setState(() => _down = LoadState.loading);
    final Map<String, dynamic> data = await ref.read(userApiProvider).getTxList(
          txTag: widget.txTag,
          takeLimit: _takeLimit,
          beforeTime:
              _list.isEmpty ? null : _intOf(_list.last['txTimeUnix']),
        );
    if (!mounted) return;
    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> list = _asList(data['txList']);
      if (list.isNotEmpty) {
        ref.read(txProvider.notifier).appendList(widget.txTag, list);
      }
      setState(() => _down =
          list.length < _takeLimit ? LoadState.noMore : LoadState.loadUp);
      return;
    }
    _toast(data['_msg']);
    if (mounted) setState(() => _down = LoadState.loadUp);
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> list = ref.watch(
      txProvider.select((TxState state) => state.listOf(widget.txTag)),
    );

    if (!_ready) return const PartShowLoading();

    if (list.isEmpty) {
      return PartEmptyList(
        prompt: _kEmpty,
        aboveIcon: 'refresh',
        aboveAction: _getOlder,
      );
    }

    return Column(
      children: <Widget>[
        PartLoadMore(loadState: _fresh, onLoad: _reload),
        for (final Map<String, dynamic> tx in list) _row(tx),
        PartLoadMore(loadState: _down, onLoad: _getOlder),
      ],
    );
  }

  Widget _row(Map<String, dynamic> tx) {
    final String lang = ref.watch(languageProvider);
    final String myUsid = ref.watch(onlineUserProvider)['usid']?.toString() ?? '';
    final bool outgoing = tx['fromUsid']?.toString() == myUsid;
    final String amount =
        '${numberPrecision(tx['sumAmount'] ?? tx['txAmount'])}${ref.watch(envarProvider).tucSymbol}';

    final String csid = tx['csid']?.toString() ?? '';
    final String openTitle = tx['openTitle']?.toString() ?? '';
    final String nickname = tx['nickname']?.toString() ?? '';
    final String portrait = tx['portrait']?.toString() ?? '';
    final String channel = tx['dpChannel']?.toString() ?? '';
    final String csidTail = csid.length <= 6 ? csid : csid.substring(csid.length - 6);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      ll(lang, LangText.fromMap(ref.watch(envarProvider).txTypeDict[tx['txType']])),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (openTitle.isNotEmpty || csid.isNotEmpty)
                      Expanded(
                        child: GestureDetector(
                          onTap: csid.isEmpty
                              ? null
                              : () => context.push(
                                    '/${AppRoutes.showCreation}?unid=$csid',
                                  ),
                          child: Text(
                            openTitle.isNotEmpty
                                ? openTitle
                                : '${_kUntitled.resolve(lang)}#$csidTail',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: PexColors.blueMy,
                            ),
                          ),
                        ),
                      )
                    else if (tx['dpAmount'] != null)
                      Text(
                        '${numberPrecision(_intOf(tx['dpAmount']) / 100, 2)} ${tx['dpCoinCode'] ?? ''}',
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: <Widget>[
                    Text(
                      formatDate(tx['txTimeUnix'], 'yyyy-mm-dd HH:MM'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: PexColors.grey6,
                      ),
                    ),
                    const Spacer(),
                    if (nickname.isNotEmpty)
                      GestureDetector(
                        onTap: () => context.push(
                          '/${AppRoutes.showCreator}?unid=${tx['usid'] ?? ''}',
                        ),
                        child: Container(
                          padding: const EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: PexColors.bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                nickname,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: PexColors.blueMy,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.all(1),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                        color: Color(0x4D000000), blurRadius: 5),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: portrait.isEmpty
                                    ? const Icon(Icons.person,
                                        size: 18, color: Color(0xFFD3D3D3))
                                    : ServerImage(portrait, fit: BoxFit.cover),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (channel.isNotEmpty)
                      Text(
                        ll(lang, _channelLabel(channel)),
                        style: const TextStyle(
                          fontSize: 13,
                          color: PexColors.grey6,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${outgoing ? '-' : '+'}$amount',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: outgoing ? PexColors.redMy : PexColors.greenMy,
            ),
          ),
        ],
      ),
    );
  }

  /// 支付渠道中文名（源项目按渠道串做正则匹配）。
  static LangText _channelLabel(String channel) {
    if (RegExp('IAP').hasMatch(channel)) {
      return const LangText(zhCN: '苹果应用内购', enUS: 'Apple IAP');
    }
    if (RegExp('WXPAY').hasMatch(channel)) {
      return const LangText(zhCN: '微信支付', enUS: 'Wechat');
    }
    if (RegExp('ALIPAY').hasMatch(channel)) {
      return const LangText(zhCN: '支付宝', enUS: 'AliPay');
    }
    if (RegExp('ETH_MAINNET').hasMatch(channel)) {
      return const LangText(zhCN: '以太坊', enUS: 'Ethereum');
    }
    if (RegExp('MATIC_MAINNET').hasMatch(channel)) {
      return const LangText(zhCN: 'Polygon Amoy', enUS: 'Polygon');
    }
    if (RegExp('ETH_SEPOLIA').hasMatch(channel)) {
      return const LangText(zhCN: '以太坊 Sepolia', enUS: 'Ethereum Sepolia');
    }
    if (RegExp('MATIC_AMOY').hasMatch(channel)) {
      return const LangText(zhCN: 'Polygon Amoy', enUS: 'Polygon Amoy');
    }
    return const LangText(zhCN: '', enUS: '');
  }
}
