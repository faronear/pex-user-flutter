/// 基础模型列表，对应源项目 `parts/partAippModels.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/state/ai_provider.dart';
import '../data/ai_model.dart';
import 'ai_model_tile.dart';
import 'part_load_more.dart';
import 'part_show_loading.dart';

const LangText _kIntro = LangText(
  zhCN: '基础AI模型，适用于通用场景。定价等同于原始模型商，不加价！',
  enUS: 'Base AI models for general purposes. Prices are the same as original suppliers without any additional charges!',
);

class PartAippModels extends ConsumerWidget {
  const PartAippModels({super.key, this.onPick});

  /// 点击回调：`aicode`。
  final ValueChanged<String>? onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final List<AiModel> models = ref.watch(aiModelListProvider);
    final String aicodeNow = ref.watch(aiProvider).aicodeNow;

    if (models.isEmpty) return const PartShowLoading();

    return Column(
      children: <Widget>[
        AiListHeader(text: ll(lang, _kIntro)),
        for (final AiModel model in models)
          AiModelTile(
            key: ValueKey<String>(aiModelKey(model)),
            model: model,
            selected: model.aicode == aicodeNow,
            onTap: onPick == null ? null : () => onPick!(model.aicode),
          ),
        const PartLoadMore(loadState: LoadState.noMore),
      ],
    );
  }
}
