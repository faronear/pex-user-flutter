/// 创作者列表，对应源项目 `parts/partCreatorAll.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/creator_api.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/creator_provider.dart';
import '../widgets/part_creator_card_list.dart';
import '../widgets/part_empty_list.dart';
import '../widgets/part_load_more.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_texts.dart';

const LangText _kEmpty = LangText(
  zhCN: '暂时没有找到，请稍后再试',
  enUS: 'Found nothing. Try again later please.',
);

class PartCreatorAll extends ConsumerStatefulWidget {
  const PartCreatorAll({super.key});

  @override
  ConsumerState<PartCreatorAll> createState() => _PartCreatorAllState();
}

class _PartCreatorAllState extends ConsumerState<PartCreatorAll> {
  static const int _takeLimit = 12;

  LoadState _loadState = LoadState.loadUp;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 100), () async {
      await ref.read(appStartupProvider.notifier).waitAutologin();
      if (!mounted) return;
      if (ref.read(creatorProvider).listAll.isEmpty) await _load();
      if (mounted) setState(() => _ready = true);
    });
  }

  Future<void> _load() async {
    if (_loadState == LoadState.loading) return;
    setState(() => _loadState = LoadState.loading);

    final Map<String, dynamic> data =
        await ref.read(creatorApiProvider).getCreatorList(takeLimit: _takeLimit);
    if (!mounted) return;

    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> list =
          (data['creatorList'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];
      if (list.isNotEmpty) ref.read(creatorProvider.notifier).setListAll(list);
    } else {
      final LangText message = LangText.fromMap(data['_msg']);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              ll(
                ref.read(languageProvider),
                message.isEmpty ? PartTexts.systemDown : message,
              ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
    setState(() => _loadState = LoadState.loadUp);
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> list = ref.watch(creatorProvider).listAll;
    if (!_ready) return const PartShowLoading();

    if (list.isEmpty) {
      return PartEmptyList(
        prompt: _kEmpty,
        aboveAction: _load,
        aboveIcon: 'refresh',
      );
    }

    return Column(
      children: <Widget>[
        PartLoadMore(loadState: _loadState, onLoad: _load),
        PartCreatorCardList(creatorList: list),
        PartLoadMore(loadState: LoadState.noMore),
      ],
    );
  }
}
