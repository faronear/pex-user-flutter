/// 探索页「全部创作品」列表，对应源项目 `parts/partCreationAll.vue`。
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
import '../widgets/part_creation_card_list.dart';
import '../widgets/part_empty_list.dart';
import '../widgets/part_load_more.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_texts.dart';

const LangText _kEmpty = LangText(
  zhCN: '暂时没有找到，请稍后再试',
  enUS: 'Found nothing. Try again later please.',
);

/// 底部「前往」按钮的目标页（源项目为 `midBabely`）。
const String kMidBabely = 'midBabely';

class PartCreationAll extends ConsumerStatefulWidget {
  const PartCreationAll({super.key});

  @override
  ConsumerState<PartCreationAll> createState() => _PartCreationAllState();
}

class _PartCreationAllState extends ConsumerState<PartCreationAll> {
  static const int _takeLimit = 12;

  LoadState _loadState = LoadState.loadUp;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 100), () async {
      await ref.read(appStartupProvider.notifier).waitAutologin();
      if (!mounted) return;
      final CreationState state = ref.read(creationProvider);
      if (!state.listAllLoaded) await _load();
      if (mounted) setState(() => _ready = true);
    });
  }

  Future<void> _load() async {
    if (_loadState == LoadState.loading) return;
    setState(() => _loadState = LoadState.loading);

    final Map<String, dynamic> data =
        await ref.read(creationApiProvider).getCreationList(takeLimit: _takeLimit);
    if (!mounted) return;

    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> list =
          (data['creationList'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];
      if (list.isNotEmpty) ref.read(creationProvider.notifier).setListAll(list);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              data['_msg'] == null
                  ? PartTexts.systemDown.resolve(ref.read(languageProvider))
                  : LangText.fromMap(data['_msg']).resolve(ref.read(languageProvider)),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
    setState(() => _loadState = LoadState.loadUp);
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> list = ref.watch(creationProvider).listAll;
    if (!_ready) return const PartShowLoading();

    if (list.isEmpty) {
      return PartEmptyList(
        prompt: _kEmpty,
        aboveAction: _load,
        belowText: const LangText(zhCN: '去逛逛', enUS: 'Explore'),
        belowAction: () => context.push('/$kMidBabely'),
      );
    }

    return Column(
      children: <Widget>[
        PartLoadMore(loadState: _loadState, onLoad: _load),
        PartCreationCardList(pexList: list, twoColumnOnPhone: true),
        PartLoadMore(loadState: LoadState.noMore),
      ],
    );
  }
}
