/// 我的消息，对应源项目 `pages/umyMia.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/api/mia_api.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/router/app_routes.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/mia_provider.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../core/util/story_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/part_empty_list.dart';
import '../widgets/part_load_more.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_window_layout.dart';

const LangText _kEmpty = LangText(
  zhCN: '暂时没有找到消息。',
  enUS: 'No messages found at the moment.',
  deDE: 'Keine Nachrichten wurden derzeit gefunden.',
  jaJP: '現在、あなたのメッセージは見つかりませんでした。',
);

class UmyMiaPage extends ConsumerStatefulWidget {
  const UmyMiaPage({super.key});

  @override
  ConsumerState<UmyMiaPage> createState() => _UmyMiaPageState();
}

class _UmyMiaPageState extends ConsumerState<UmyMiaPage> {
  static const int _takeLimit = 10;

  LoadState _fresh = LoadState.loadFresh;
  LoadState _down = LoadState.loadUp;
  bool _ready = false;

  List<Map<String, dynamic>> get _list => ref.read(miaProvider).myMiaList;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 100), () async {
      await ref.read(appStartupProvider.notifier).waitAutologin();
      if (!mounted) return;
      // 源项目：`!myMiaList.length && !myMiaList.onceLoaded` 才自动拉第一页。
      if (!ref.read(miaProvider).onceLoaded) await _getOlder();
      if (mounted) setState(() => _ready = true);
    });
  }

  Future<Map<String, dynamic>> _call() => ref.read(miaApiProvider).listMyMia(
        takeLimit: _takeLimit,
        beforeTime: _list.isEmpty ? null : _intOf(_list.last['miaCreatedAt']),
      );

  static int _intOf(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  static List<Map<String, dynamic>> _asList(Object? value) => value is List
      ? value
          .whereType<Map>()
          .map((Map item) => item.cast<String, dynamic>())
          .toList()
      : <Map<String, dynamic>>[];

  /// 「刷新」：重拉最新一页并覆盖（源项目 `to_reload_messages`）。
  Future<void> _reload() async {
    if (_fresh == LoadState.loading) return;
    setState(() => _fresh = LoadState.loading);
    final Map<String, dynamic> data = await _call();
    if (!mounted) return;
    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> list = _asList(data['miaList']);
      ref.read(miaProvider.notifier).setList(list);
      setState(() => _down =
          list.length < _takeLimit ? LoadState.noMore : LoadState.loadUp);
    } else {
      _toast(data['_msg']);
    }
    if (mounted) setState(() => _fresh = LoadState.loadFresh);
  }

  /// 「加载更多」：向下翻页并追加（源项目是整表替换，会丢掉已加载的页）。
  Future<void> _getOlder() async {
    if (_down == LoadState.loading) return;
    setState(() => _down = LoadState.loading);
    final Map<String, dynamic> data = await _call();
    if (!mounted) return;
    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> list = _asList(data['miaList']);
      if (list.isNotEmpty) ref.read(miaProvider.notifier).appendList(list);
      setState(() => _down =
          list.length < _takeLimit ? LoadState.noMore : LoadState.loadUp);
      return;
    }
    _toast(data['_msg']);
    if (mounted) setState(() => _down = LoadState.loadUp);
  }

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

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> list =
        ref.watch(miaProvider.select((MiaState state) => state.myMiaList));

    return PartWindowLayout(
      pageName: AppRoutes.umyMia,
      child: Column(
        children: <Widget>[
          const PartNavibarPcFixed(),
          Expanded(
            child: !_ready
                ? const PartShowLoading()
                : SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: list.isEmpty
                            ? PartEmptyList(
                                prompt: _kEmpty,
                                aboveIcon: 'refresh',
                                aboveAction: _getOlder,
                              )
                            : Column(
                                children: <Widget>[
                                  PartLoadMore(
                                    loadState: _fresh,
                                    onLoad: _reload,
                                  ),
                                  for (final Map<String, dynamic> mia in list)
                                    _MiaRow(mia: mia, onOpen: _open),
                                  PartLoadMore(
                                    loadState: _down,
                                    onLoad: _getOlder,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 先把整条消息存进 `Mia.miaNow`，让详情页能立刻渲染（源项目同样做法）。
  void _open(Map<String, dynamic> mia) {
    ref.read(miaProvider.notifier).setMiaNow(mia);
    context.push(
      '${AppRoutes.path(AppRoutes.umyMiaDetail)}?miaUuid=${mia['miaUuid']?.toString() ?? ''}',
    );
  }
}

class _MiaRow extends ConsumerWidget {
  const _MiaRow({required this.mia, required this.onOpen});

  final Map<String, dynamic> mia;
  final ValueChanged<Map<String, dynamic>> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final String portrait = mia['from_portrait']?.toString() ?? '';
    final String nickname =
        ll(lang, LangText.fromMap(mia['from_nickname']));
    final String note = (mia['miaTitle']?.toString() ?? '').isNotEmpty
        ? mia['miaTitle'].toString()
        : extractStoryTitle(mia['miaStory'] as List<dynamic>?, lang: lang);
    final bool unread = mia['miaToState']?.toString() == 'UNREAD';

    return InkWell(
      onTap: () => onOpen(mia),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Stack(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: Color(0x4D000000), blurRadius: 10),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: portrait.isEmpty
                      ? const Center(
                          child: Icon(Icons.person,
                              size: 36, color: Color(0xFFD3D3D3)),
                        )
                      : ServerImage(portrait, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              nickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: PexColors.grey3,
                              ),
                            ),
                          ),
                          Text(
                            formatDate(mia['miaCreatedAt'], 'yyyy-mm-dd'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: PexColors.grey9,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: PexColors.grey6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (unread)
              const Positioned(
                top: 6,
                right: 6,
                child: SizedBox(
                  width: 8,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: PexColors.redMy,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
