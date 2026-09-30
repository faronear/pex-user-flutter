/// 货币选择表，对应源项目 `parts/partCoinTable.vue`：
/// 表头（符号 / 名称 / 代号，后两列可排序）+ 可选中的货币列表。
///
/// 源项目把它放在 `uni-popup` 里（PC 居中、手机底部）；这里统一走 `showModalBottomSheet`
/// （与本项目其它弹窗一致）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/coins.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../theme/app_theme.dart';

const LangText _kSymbol = LangText(zhCN: '符号', enUS: 'Symbol');

const LangText _kName = LangText(zhCN: '名称', enUS: 'Name');

const LangText _kCode = LangText(zhCN: '代号', enUS: 'Code');

/// 打开货币选择弹窗；返回被选中的货币（用户取消则为 null）。
Future<Coin?> showCoinTableSheet(
  BuildContext context, {
  required List<Coin> coins,
  required Coin current,
}) {
  return showModalBottomSheet<Coin>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
    ),
    builder: (BuildContext context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        minWidth: 320,
      ),
      child: PartCoinTable(coins: coins, current: current),
    ),
  );
}

class PartCoinTable extends ConsumerStatefulWidget {
  const PartCoinTable({
    super.key,
    required this.coins,
    required this.current,
  });

  final List<Coin> coins;
  final Coin current;

  @override
  ConsumerState<PartCoinTable> createState() => _PartCoinTableState();
}

enum _SortBy { none, name, code }

class _PartCoinTableState extends ConsumerState<PartCoinTable> {
  late final List<Coin> _list = List<Coin>.of(widget.coins);
  _SortBy _sortBy = _SortBy.none;
  bool _ascending = true;

  void _sort(_SortBy by) {
    setState(() {
      if (_sortBy == by) {
        _ascending = !_ascending;
      } else {
        _sortBy = by;
        _ascending = true;
      }
      final String lang = ref.read(languageProvider);
      final int sign = _ascending ? 1 : -1;
      _list.sort((Coin x, Coin y) {
        final String a = _sortBy == _SortBy.name ? x.name.resolve(lang) : x.coinCode;
        final String b = _sortBy == _SortBy.name ? y.name.resolve(lang) : y.coinCode;
        return sign * a.toLowerCase().compareTo(b.toLowerCase());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // 表头（对应源项目 `uni-table` 的表头行）。
        Row(
          children: <Widget>[
            _headerCell(
              text: ll(lang, _kSymbol),
              flex: 3,
              align: TextAlign.left,
              padding: const EdgeInsets.only(left: 10),
            ),
            _headerCell(
              text: ll(lang, _kName),
              flex: 4,
              align: TextAlign.center,
              sortable: true,
              sorted: _sortBy == _SortBy.name,
              ascending: _ascending,
              onTap: () => _sort(_SortBy.name),
            ),
            _headerCell(
              text: ll(lang, _kCode),
              flex: 3,
              align: TextAlign.right,
              padding: const EdgeInsets.only(right: 10),
              sortable: true,
              sorted: _sortBy == _SortBy.code,
              ascending: _ascending,
              onTap: () => _sort(_SortBy.code),
            ),
          ],
        ),
        const Divider(height: 1, color: PexColors.bg),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _list.length,
            itemBuilder: (BuildContext context, int index) {
              final Coin coin = _list[index];
              final bool active = coin.coinCode == widget.current.coinCode;
              return InkWell(
                onTap: () => Navigator.of(context).pop(coin),
                child: Container(
                  color: active ? PexColors.bg : null,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: Text(
                          coin.coinSymbol,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          ll(lang, coin.name),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          coin.coinCode,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _headerCell({
    required String text,
    required int flex,
    required TextAlign align,
    EdgeInsets? padding,
    bool sortable = false,
    bool sorted = false,
    bool ascending = true,
    VoidCallback? onTap,
  }) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: sortable ? onTap : null,
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: align == TextAlign.right
                ? MainAxisAlignment.end
                : (align == TextAlign.center
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start),
            children: <Widget>[
              Text(
                text,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              if (sortable)
                Icon(
                  ascending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: sorted ? PexColors.blueMy : PexColors.greyC,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
