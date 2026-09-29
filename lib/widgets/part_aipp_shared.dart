/// 共享 Aibot 列表，对应源项目 `parts/partAippShared.vue`。
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
import 'part_feedback.dart';
import 'part_load_more.dart';
import 'part_show_loading.dart';

const LangText _kIntro = LangText(
  zhCN: '各种 Aibot 为不同场景而优化。拥有长期记忆，服务更贴心。人人都能开发并分享！',
  enUS: 'Aibot optimized for specific purposes and with long memory. Everyone can create and share Aibot!',
);

class PartAippShared extends ConsumerStatefulWidget {
  const PartAippShared({super.key, this.onPick});

  final ValueChanged<String>? onPick;

  @override
  ConsumerState<PartAippShared> createState() => _PartAippSharedState();
}

class _PartAippSharedState extends ConsumerState<PartAippShared> {
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

    final List<Map<String, dynamic>> current = ref.read(aiProvider).aippListShared;
    final Map<String, dynamic> data =
        await ref.read(aimodelApiProvider).getAllAippList(
              skip: current.length,
              takeLimit: _takeLimit,
            );
    if (!mounted) return;

    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> fetched =
          (data['aippList'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];
      ref.read(aiProvider.notifier).setAippListShared(
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
          data['_msg'] == null
              ? const LangText(
                  zhCN: '系统出错了，请稍后再试，或请向客服投诉。',
                  enUS: 'Something went wrong. Please try again later or report to customer service.',
                )
              : LangText.fromMap(data['_msg']),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final String aicodeNow = ref.watch(aiProvider).aicodeNow;
    final List<Map<String, dynamic>> list = ref.watch(aiProvider).aippListShared;

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
        if (list.isEmpty)
          const PartFeedback(bad: LangText(zhCN: '', enUS: '')),
        PartLoadMore(
          loadState: _loadState,
          onLoad: _load,
        ),
      ],
    );
  }
}
