/// 消息详情（含回复），对应源项目 `pages/umyMiaDetail.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/api/mia_api.dart';
import '../core/icons/pex_icon.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/router/app_routes.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../core/state/mia_provider.dart';
import '../core/util/feedback.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../core/util/story_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/part_empty_list.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_story_editor.dart';
import '../widgets/part_story_reader.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_window_layout.dart';

const LangText _kNotFound = LangText(
  zhCN: '没有找到这个消息。',
  enUS: 'This message is not found.',
  deDE: 'Diese Nachricht wurde nicht gefunden.',
  jaJP: '現在、あなたのメッセージは見つかりませんでした。',
);

const LangText _kMessageList = LangText(zhCN: '消息列表', enUS: 'Messages');

const LangText _kMyReply = LangText(zhCN: '我的回复：', enUS: 'My Reply:');

const LangText _kEmptyReply = LangText(
  zhCN: '回复是空的。请先写点儿什么！',
  enUS: 'Reply is empty. Please write something!',
);

const LangText _kReplySent = LangText(
  zhCN: '您的回复已发送成功',
  enUS: 'Your reply has been sent successfully',
  deDE: 'Ihre Antwort wurde erfolgreich gesendet',
  jaJP: 'あなたの返信は正常に送信されました',
);

class UmyMiaDetailPage extends ConsumerStatefulWidget {
  const UmyMiaDetailPage({super.key, this.miaUuid = ''});

  /// 路由 `?miaUuid=`；从列表页进入时 `Mia.miaNow` 已有内容，可先渲染再刷新。
  final String miaUuid;

  @override
  ConsumerState<UmyMiaDetailPage> createState() => _UmyMiaDetailPageState();
}

class _UmyMiaDetailPageState extends ConsumerState<UmyMiaDetailPage> {
  List<Map<String, dynamic>> _replyStory = <Map<String, dynamic>>[
    <String, dynamic>{'text': ''},
  ];
  bool _loadingMia = false;
  bool _sendingMia = false;
  bool _ready = false;
  LangText? _feedbackRemote;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 100), () async {
      await ref.read(appStartupProvider.notifier).waitAutologin();
      if (!mounted) return;
      // 源项目：列表页已把整条消息放进 `Mia.miaNow`，故可先渲染再拉详情。
      if ((ref.read(miaProvider).miaNow['miaStory']) != null) {
        setState(() => _ready = true);
      }
      final String uuid =
          ref.read(miaProvider).miaNow['miaUuid']?.toString() ?? '';
      if (uuid.isNotEmpty || widget.miaUuid.isNotEmpty) {
        await _loadDetail(uuid.isEmpty ? widget.miaUuid : uuid);
      }
      if (mounted) setState(() => _ready = true);
    });
  }

  Future<void> _loadDetail(String uuid) async {
    setState(() => _loadingMia = true);
    final Map<String, dynamic> data =
        await ref.read(miaApiProvider).getMiaDetail(uuid);
    if (!mounted) return;
    setState(() => _loadingMia = false);

    final Map<String, dynamic> mia =
        (data['mia'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    if (!bok(data['_state']?.toString()) || (mia['miaUuid'] == null)) return;

    if (data['miaUnread'] != null) {
      // 后端已标记已读；前端同步把未读数减一（源项目 `onlineUser.countMiaUnread--`）。
      mia['miaToState'] = 'READ';
      _decrementUnread();
    }
    if (ref.read(miaProvider).miaNow['miaUuid'] != null) {
      ref.read(miaProvider.notifier).mergeMiaNow(mia);
    } else {
      ref.read(miaProvider.notifier).setMiaNow(mia);
    }
    // 列表页上的红点也要跟着消失。
    ref.read(miaProvider.notifier).mergeInList(mia);
  }

  void _decrementUnread() {
    final Object? current =
        ref.read(appStartupProvider).onlineUser['countMiaUnread'];
    final int value =
        current is num ? current.toInt() : int.tryParse('$current') ?? 0;
    ref.read(appStartupProvider.notifier)
        .mergeOnlineUser(<String, dynamic>{'countMiaUnread': value - 1});
  }

  Future<void> _reply() async {
    if (!(ref.read(onlineUserProvider)['usid']?.toString() ?? '').isNotEmpty) {
      return;
    }
    setState(() => _feedbackRemote = null);
    _replyStory = filterStory(_replyStory).cast<Map<String, dynamic>>();
    if (_replyStory.isEmpty) {
      setState(() {
        _replyStory = <Map<String, dynamic>>[<String, dynamic>{'text': ''}];
        _feedbackRemote = _kEmptyReply;
      });
      Future<void>.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _feedbackRemote = null);
      });
      return;
    }

    final Map<String, dynamic> miaNow = ref.read(miaProvider).miaNow;
    setState(() => _sendingMia = true);
    final Map<String, dynamic> data = await ref.read(miaApiProvider).sendMia(
          miaToUsid: miaNow['miaFromUsid']?.toString() ?? '',
          miaToMid: miaNow['miaUuid']?.toString() ?? '',
          miaStory: _replyStory,
        );
    if (!mounted) return;
    setState(() => _sendingMia = false);

    if (bok(data['_state']?.toString())) {
      await showPexModal(context, ref, title: _kReplySent);
      if (!mounted) return;
      // 源项目：确认后再清空回复框（留在页面上给用户提示）。
      setState(() =>
          _replyStory = <Map<String, dynamic>>[<String, dynamic>{'text': ''}]);
      return;
    }
    final LangText message = LangText.fromMap(data['_msg']);
    setState(() => _feedbackRemote =
        message.isEmpty ? PartTexts.systemDown : message);
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final Map<String, dynamic> mia =
        ref.watch(miaProvider.select((MiaState state) => state.miaNow));

    return PartWindowLayout(
      pageName: AppRoutes.umyMiaDetail,
      child: Column(
        children: <Widget>[
          const PartNavibarPcFixed(),
          Expanded(
            child: !_ready || _loadingMia
                ? const PartShowLoading()
                : SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: (mia['miaUuid']?.toString() ?? '').isEmpty
                              ? PartEmptyList(
                                  prompt: _kNotFound,
                                  belowIcon: 'list',
                                  belowText: _kMessageList,
                                  belowAction: () => context
                                      .go(AppRoutes.path(AppRoutes.umyMia)),
                                )
                              : _body(lang, envar, mia),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _body(String lang, Envar envar, Map<String, dynamic> mia) {
    final String portrait = mia['from_portrait']?.toString() ?? '';
    final String nickname = ll(lang, LangText.fromMap(mia['from_nickname']));
    final Object? createdAt = mia['miaCreatedAt'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: portrait.isEmpty
                  ? const Center(
                      child:
                          Icon(Icons.person, size: 36, color: Color(0xFFD3D3D3)),
                    )
                  : ServerImage(portrait, fit: BoxFit.cover),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: SizedBox(
                height: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                            ),
                          ),
                        ),
                        Text(
                          formatDate(createdAt, 'yyyy-mm-dd'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: PexColors.grey9,
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        formatDate(createdAt, 'HH:MM'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: PexColors.grey9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.only(bottom: 20),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: PexColors.border)),
          ),
          child: PartStoryReader(
            story: (mia['miaStory'] as List?) ??
                <Map<String, dynamic>>[
                  <String, dynamic>{'text': mia['miaTitle']?.toString() ?? ''},
                ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: <Widget>[
              PexIcon.uni(
                'compose',
                size: 20,
                color: PexColors.blueMy,
              ),
              const SizedBox(width: 5),
              Text(
                _kMyReply.resolve(lang),
                style: const TextStyle(fontSize: 14, color: PexColors.grey6),
              ),
            ],
          ),
        ),
        if (_feedbackRemote != null)
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              _feedbackRemote!.resolve(lang),
              style: const TextStyle(color: PexColors.redMy, fontSize: 13),
            ),
          ),
        PartStoryEditor(
          story: _replyStory,
          onStoryChanged: (List<Map<String, dynamic>> next) =>
              setState(() => _replyStory = next),
          allowText: envar.boolOf('miaText', true),
          allowSpeak: envar.boolOf('miaSpeak'),
          allowImage: envar.boolOf('miaImage'),
          allowVideo: envar.boolOf('miaVideo'),
          allowAudio: envar.boolOf('miaAudio'),
          allowFile: envar.boolOf('miaFile'),
          allowLink: envar.boolOf('miaLink'),
          maxSections: envar.intOf('miaMaxSections', 2),
          publishing: _sendingMia,
          onPublish: _reply,
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
