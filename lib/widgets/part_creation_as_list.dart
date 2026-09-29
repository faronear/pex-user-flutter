/// 「我的收藏」按身份列表 —— 参数化替代源项目 5 个近乎相同的 `parts/partCreationAs*.vue`。
///
/// 5 个源组件只在「接口 apiTodo / 集合字段 / 空态文案 / 图标」上不同，逻辑完全一致，
/// 故合并为一个组件（行为等价，代码量大幅下降）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/api/creation_api.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/creation_provider.dart';
import '../core/state/envar_provider.dart';
import '../widgets/part_creation_all.dart' show kMidBabely;
import '../widgets/part_creation_card_list.dart';
import '../widgets/part_empty_list.dart';
import '../widgets/part_load_more.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_texts.dart';

class PartCreationAsList extends ConsumerStatefulWidget {
  const PartCreationAsList({super.key, required this.role});

  final CreationRole role;

  @override
  ConsumerState<PartCreationAsList> createState() => _PartCreationAsListState();
}

class _PartCreationAsListState extends ConsumerState<PartCreationAsList> {
  static const int _takeLimit = 12;

  LoadState _down = LoadState.loadUp;
  LoadState _fresh = LoadState.loadUp;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 100), () async {
      await ref.read(appStartupProvider.notifier).waitAutologin();
      if (!mounted) return;
      if (!ref.read(creationProvider).onceLoaded.contains(widget.role)) {
        await _getOlder();
      }
      if (mounted) setState(() => _ready = true);
    });
  }

  List<Map<String, dynamic>> get _list =>
      ref.read(creationProvider).collectionOf(widget.role);

  /// 向下翻页（更早的作品），游标为最后一条的 `createTimeUnix`。
  Future<void> _getOlder() async {
    if (_down == LoadState.loading) return;
    setState(() => _down = LoadState.loading);

    final int? beforeTime = _list.isEmpty ? null : _list.last['createTimeUnix'] as int?;
    final Map<String, dynamic> data = await ref
        .read(creationApiProvider)
        .getCreationsAs(widget.role, takeLimit: _takeLimit, beforeTime: beforeTime);
    if (!mounted) return;

    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> fetched =
          (data['creatorCollection'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];
      if (fetched.isNotEmpty) {
        ref
            .read(creationProvider.notifier)
            .setCollection(widget.role, <Map<String, dynamic>>[..._list, ...fetched]);
      } else {
        ref.read(creationProvider.notifier).setCollection(widget.role, _list);
      }
      setState(() =>
          _down = fetched.length < _takeLimit ? LoadState.noMore : LoadState.loadUp);
    } else {
      setState(() => _down = LoadState.loadUp);
      if (mounted) _toast(data);
    }
  }

  /// 向上刷新（最新一批）。
  Future<void> _getNewest() async {
    if (_fresh == LoadState.loading) return;
    setState(() => _fresh = LoadState.loading);

    final Map<String, dynamic> data = await ref
        .read(creationApiProvider)
        .getCreationsAs(widget.role, takeLimit: _takeLimit);
    if (!mounted) return;

    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> fetched =
          (data['creatorCollection'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];
      ref.read(creationProvider.notifier).setCollection(widget.role, fetched);
      setState(() =>
          _down = fetched.length < _takeLimit ? LoadState.noMore : LoadState.loadUp);
    } else {
      if (mounted) _toast(data);
    }
    setState(() => _fresh = LoadState.loadUp);
  }

  void _toast(Map<String, dynamic> data) {
    final String lang = ref.read(languageProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            data['_msg'] == null
                ? PartTexts.systemDown.resolve(lang)
                : LangText.fromMap(data['_msg']).resolve(lang),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// 空态提示语取自 `pactDict.<pactKey>.CREATED_EMPTY`。
  LangText get _emptyPrompt {
    final Object? pact = ref.read(envarProvider).raw['pactDict'];
    if (pact is Map) {
      final Object? item = (pact[widget.role.pactKey] as Map?)?['CREATED_EMPTY'];
      if (item is Map) return LangText.fromMap(item);
    }
    return const LangText(zhCN: '暂无内容。', enUS: 'Nothing here yet.');
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> list =
        ref.watch(creationProvider).collectionOf(widget.role);
    if (!_ready) return const PartShowLoading();

    if (list.isEmpty) {
      return PartEmptyList(
        prompt: _emptyPrompt,
        aboveAction: _getOlder,
        belowText: const LangText(zhCN: '去逛逛', enUS: 'Explore'),
        belowAction: () => context.push('/$kMidBabely'),
      );
    }

    return Column(
      children: <Widget>[
        PartLoadMore(loadState: _fresh, onLoad: _getNewest),
        PartCreationCardList(
          pexList: list,
          twoColumnOnPhone: true,
          hideAvatar: true,
        ),
        PartLoadMore(loadState: _down, onLoad: _getOlder),
      ],
    );
  }
}
