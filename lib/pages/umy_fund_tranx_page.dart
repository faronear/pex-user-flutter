/// 我的收支明细，对应源项目 `pages/umyFundTranx.vue`。
///
/// 顶部一个「收支类型」下拉，切换即换 `?tagnow=`；下方是该类型的明细列表。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/router/app_routes.dart';
import '../core/state/envar_provider.dart';
import '../core/state/tx_provider.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_tx_list.dart';
import '../widgets/part_window_layout.dart';

const LangText _kSelectType = LangText(
  zhCN: '选择收支类型',
  enUS: 'Select transaction type',
);

class UmyFundTranxPage extends ConsumerStatefulWidget {
  const UmyFundTranxPage({super.key, this.tagNow = ''});

  /// 路由 `?tagnow=<myTxDict 的键>`。
  final String tagNow;

  @override
  ConsumerState<UmyFundTranxPage> createState() => _UmyFundTranxPageState();
}

class _UmyFundTranxPageState extends ConsumerState<UmyFundTranxPage> {
  String? _tag;

  /// 源项目 `onLoad`：命中字典才生效；否则用「上次选中的」，再否则用第一个。
  String _resolveTag(List<String> keys) {
    if (_tag != null && keys.contains(_tag)) return _tag!;
    if (keys.contains(widget.tagNow)) return widget.tagNow;
    final String remembered = ref.read(txProvider).tagNow;
    if (keys.contains(remembered)) return remembered;
    return keys.isEmpty ? '' : keys.first;
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final Map<String, dynamic> dict = ref.watch(envarProvider).myTxDict;
    final List<String> keys = dict.keys.toList();
    final String current = _resolveTag(keys);

    return PartWindowLayout(
      pageName: AppRoutes.umyFundTranx,
      child: Column(
        children: <Widget>[
          const PartNavibarPcFixed(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    _kSelectType.resolve(lang),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: keys.contains(current) ? current : null,
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
                          '${(dict[key] as Map?)?['paydir'] ?? ''} '
                          '${ll(lang, LangText.fromMap(dict[key]))}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                  onChanged: (String? value) {
                    if (value == null) return;
                    // 源项目：切换是 `uni.redirectTo`（换 tagnow 重开本页）。
                    setState(() => _tag = value);
                    ref.read(txProvider.notifier).setTagNow(value);
                    context.go(
                      '${AppRoutes.path(AppRoutes.umyFundTranx)}?tagnow=$value',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: current.isEmpty
                        ? const SizedBox.shrink()
                        : PartTxList(
                            key: ValueKey<String>(current),
                            txTag: current,
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
}
