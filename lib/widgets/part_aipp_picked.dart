/// 我的 Aibot 列表，对应源项目 `parts/partAippPicked.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/aimodel_api.dart';
import '../core/api/api_client.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/state/ai_provider.dart';
import '../core/util/feedback.dart';
import '../data/ai_model.dart';
import 'ai_model_tile.dart';
import 'part_load_more.dart';
import 'part_show_loading.dart';
import 'part_texts.dart';

const LangText _kIntro = LangText(
  zhCN: '我创建的、以及我收藏的应用。',
  enUS: 'Aibot created or collected by myself.',
);

class PartAippPicked extends ConsumerStatefulWidget {
  const PartAippPicked({super.key, this.onPick});

  final ValueChanged<String>? onPick;

  @override
  ConsumerState<PartAippPicked> createState() => _PartAippPickedState();
}

class _PartAippPickedState extends ConsumerState<PartAippPicked> {
  static const int _takeLimit = 10;

  LoadState _loadState = LoadState.loadUp;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 100), _load);
  }

  Future<void> _load() async {
    if (_loadState == LoadState.loading) return;
    setState(() => _loadState = LoadState.loading);

    final List<Map<String, dynamic>> current = ref.read(aiProvider).aippListPicked;
    final Map<String, dynamic> data =
        await ref.read(aimodelApiProvider).getMyAippList(
              skip: current.length,
              takeLimit: _takeLimit,
            );
    if (!mounted) return;

    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> fetched =
          (data['aippList'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];
      ref.read(aiProvider.notifier).setAippListPicked(
            <Map<String, dynamic>>[...current, ...fetched],
          );
      setState(() {
        _ready = true;
        _loadState = fetched.length < _takeLimit ? LoadState.noMore : LoadState.loadUp;
      });
    } else {
      setState(() {
        _ready = true;
        _loadState = LoadState.loadUp;
      });
      if (mounted) {
        showPexToast(
          context,
          ref,
          data['_msg'] == null ? PartTexts.systemDown : LangText.fromMap(data['_msg']),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final String aicodeNow = ref.watch(aiProvider).aicodeNow;
    final List<Map<String, dynamic>> list = ref.watch(aiProvider).aippListPicked;

    if (!_ready) return const PartShowLoading();

    return Column(
      children: <Widget>[
        AiListHeader(text: ll(lang, _kIntro)),
        for (final Map<String, dynamic> raw in list)
          Builder(
            builder: (BuildContext context) {
              final AiModel model = AiModel(raw);
              return AiModelTile(
                key: ValueKey<String>(aiModelKey(model)),
                model: model,
                selected: model.aicode == aicodeNow,
                onTap: widget.onPick == null ? null : () => widget.onPick!(model.aicode),
              );
            },
          ),
        PartLoadMore(loadState: _loadState, onLoad: _load),
      ],
    );
  }
}
