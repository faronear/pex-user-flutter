/// AI 对话核心，对应源项目 `parts/partAichat.vue`。
///
/// 已实现：模型头部、消息列表（story 渲染）、输入条、发送（`reply_challenge` + 思考中倒计时）、
/// 消息操作（拷贝/朗读/删除/预览/转存，对应 `partMenuRing` + `act_on_message`）、模型切换、
/// 记忆条数/图片数设置、重置对话、收藏/取消收藏。
/// 暂缓（后续轮次）：story 编辑模式、语音输入、分享弹窗、充值弹窗。
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/aimodel_api.dart';
import '../core/api/api_client.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/router/app_routes.dart';
import '../core/state/app_providers.dart';
import '../core/state/ai_provider.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/creation_draft_provider.dart';
import '../core/state/envar_provider.dart';
import '../core/util/feedback.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../data/ai_model.dart';
import '../theme/app_theme.dart';
import 'part_aipp_models.dart';
import 'part_breathing_opacity.dart';
import 'part_show_loading.dart';
import 'part_story_editor.dart';
import 'part_story_reader.dart';
import 'part_texts.dart';

const LangText _kThinking = LangText(zhCN: '思考中... ', enUS: 'Thinking... ');

const LangText _kInputHint = LangText(
  zhCN: '输入您的问题...',
  enUS: 'Enter your question...',
  jaJP: '質問を入力してください...',
);

const LangText _kPleaseInput = LangText(
  zhCN: '请输入您的问题！',
  enUS: 'Please enter your question!',
);

const LangText _kClearChat = LangText(zhCN: '清空对话', enUS: 'Clear chat');

const LangText _kResetDone = LangText(
  zhCN: '对话已清空。',
  enUS: 'The chat is cleared.',
);

const LangText _kMemory = LangText(zhCN: '记忆', enUS: 'Memory', jaJP: '記憶');

const LangText _kImgNum = LangText(zhCN: '图片数', enUS: 'Images', jaJP: '画像数');

const LangText _kCopy = LangText(zhCN: '拷贝', enUS: 'Copy');

const LangText _kDrop = LangText(zhCN: '删除', enUS: 'Drop');

const LangText _kCopied = LangText(zhCN: '已拷贝', enUS: 'Copied');

const LangText _kRead = LangText(zhCN: '朗读', enUS: 'Read');

const LangText _kPreview = LangText(zhCN: '预览', enUS: 'View');

const LangText _kSave = LangText(zhCN: '转存', enUS: 'Transfer');

const LangText _kCannotRead = LangText(zhCN: '暂时无法朗读', enUS: 'Cannot readout');

const LangText _kDropTitle = LangText(zhCN: '删除这一段吗？', enUS: 'Delete this section?');

const LangText _kDropConfirm = LangText(zhCN: '删除', enUS: 'Delete');

const LangText _kSavedTitle = LangText(
  zhCN: '本段落已转存为创作内容',
  enUS: 'This section is copied to a new creation',
);

const LangText _kSavedContent = LangText(
  zhCN: '接下来，您可以留在当前页面继续AIGC，或者跳转到创造页面修改内容。',
  enUS: 'Next, you can stay on this page to continue using AIGC, or go to the create page to edit content.',
  deDE: 'Als nächstes können Sie auf dieser Seite bleiben, order zur Erstellungsseite wechseln.',
  jaJP: '次に、このページにとどまってAIGCを続行するか、作成ページに移動してコンテンツを編集できます。',
);

const LangText _kGoCreate = LangText(zhCN: '跳转去创造', enUS: 'Go to Create');

const LangText _kStayAigc = LangText(zhCN: '留在AIGC', enUS: 'Stay at AIGC');

class PartAichat extends ConsumerStatefulWidget {
  const PartAichat({super.key, this.aicode});

  /// 路由传入的模型/Aibot 编码（源项目 `?aicode=`）。
  final String? aicode;

  @override
  ConsumerState<PartAichat> createState() => _PartAichatState();
}

class _PartAichatState extends ConsumerState<PartAichat> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _inited = false;
  bool _loadingHistory = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// 解析当前模型：路由参数 → 现有 → 后端默认 → 第一个模型。
  AiModel? _resolveModel() {
    final AiNotifier ai = ref.read(aiProvider.notifier);
    final List<AiModel> models = ref.read(aiModelListProvider);
    final String defaultCode = ref.read(envarProvider).str('aicodeDefault');
    final String code = widget.aicode ??
        ref.read(aiProvider).aicodeNow.let((String v) => v.isNotEmpty ? v : '');
    final String chosen = code.isNotEmpty
        ? code
        : (defaultCode.isNotEmpty
            ? defaultCode
            : (models.isNotEmpty ? models.first.aicode : ''));
    ai.setAicodeNow(chosen);
    for (final AiModel model in models) {
      if (model.aicode == chosen) return model;
    }
    return null;
  }

  Future<void> _init() async {
    if (_inited) return;
    _inited = true;

    final AiNotifier ai = ref.read(aiProvider.notifier);
    AiModel? model = _resolveModel();
    ai.setAintNow(model?.raw);

    // Aibot（asst_ 前缀）需要向后端取详情。
    if (model == null && ref.read(aiProvider).aicodeNow.startsWith('asst_')) {
      final Map<String, dynamic> data = await ref
          .read(aimodelApiProvider)
          .getAipp(ref.read(aiProvider).aicodeNow);
      if (!mounted) return;
      if (bok(data['_state']?.toString()) && data['aipp'] is Map) {
        ai.setAintNow((data['aipp'] as Map).cast<String, dynamic>());
      } else {
        final List<AiModel> models = ref.read(aiModelListProvider);
        if (models.isNotEmpty) {
          ai.setAicodeNow(models.first.aicode);
          ai.setAintNow(models.first.raw);
        }
      }
    }

    await _loadHistory(reset: true);
  }

  Future<void> _loadHistory({bool reset = false}) async {
    if (_loadingHistory) return;
    final String aicode = ref.read(aiProvider).aicodeNow;
    if (aicode.isEmpty) return;
    setState(() => _loadingHistory = true);

    final List<Map<String, dynamic>> current = ref.read(aiProvider).chatList;
    final Map<String, dynamic> data =
        await ref.read(aimodelApiProvider).getChatHistory(
              aicode: aicode,
              skip: reset ? 0 : current.length,
              takeLimit: 10,
            );
    if (!mounted) return;
    setState(() => _loadingHistory = false);

    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> history =
          (data['chatHistory'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];
      ref.read(aiProvider.notifier).setChatList(
            reset ? history : <Map<String, dynamic>>[...history, ...current],
          );
    }
  }

  Future<void> _send({bool storylike = false}) async {
    final String promptText = _input.text.trim();
    // story 模式：过滤掉空文本段落（对应源项目 `wo.tt.filter_story`）。
    final List<Map<String, dynamic>> storyPrompt = ref
        .read(aiProvider)
        .promptStory
        .where((Map<String, dynamic> section) => section.values.any(
              (Object? value) => !isEmptyValue(value),
            ))
        .toList();
    if (storylike ? storyPrompt.isEmpty : promptText.isEmpty) {
      showPexToast(context, ref, _kPleaseInput);
      return;
    }

    final AiNotifier ai = ref.read(aiProvider.notifier);
    final AiState state = ref.read(aiProvider);
    final String aicodeChat = state.aicodeNow;

    // 组装历史（按记忆条数）
    final List<Map<String, dynamic>> history = <Map<String, dynamic>>[];
    if (state.isTextModel && state.contextToRemember > 0) {
      int count = 0;
      for (int i = state.chatList.length - 1; i >= 0; i--) {
        final Map<String, dynamic> item = state.chatList[i];
        final List<dynamic> story = (item['story'] as List?) ?? <dynamic>[];
        final Object content = storylike
            ? item['story']
            : (story.isNotEmpty && story.first is Map
                ? ((story.first as Map)['textRejected'] ??
                    (story.first as Map)['text'] ??
                    '')
                : '');
        history.insert(0, <String, dynamic>{
          'role': item['role'],
          'content': content,
        });
        count++;
        if (count >= state.contextToRemember) break;
      }
    }

    final Map<String, dynamic> promptObj = <String, dynamic>{
      'role': 'user',
      'aicode': aicodeChat,
      'story': storylike
          ? storyPrompt
          : <Map<String, dynamic>>[<String, dynamic>{'text': promptText}],
      'chatTimeUnix': DateTime.now().millisecondsSinceEpoch,
    };
    final Object prompt4base = storylike ? storyPrompt : promptText;

    ai.appendChat(promptObj);
    _input.clear();
    if (storylike) {
      ai.setPromptStory(<Map<String, dynamic>>[<String, dynamic>{'text': ''}]);
    }
    ai.setLoadingSend(true);

    int remaining = 60;
    final Map<String, dynamic> waiting = <String, dynamic>{
      'role': 'assistant',
      'aicode': aicodeChat,
      'chatTimeUnix': DateTime.now().millisecondsSinceEpoch,
      'story': <Map<String, dynamic>>[
        <String, dynamic>{'text': '${_kThinking.resolve(ref.read(languageProvider))}$remaining'},
      ],
    };
    ai.appendChat(waiting);
    _scrollToEnd();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) return;
      setState(() {
        if (remaining > 0) remaining--;
      });
      // 更新等待中的那条消息
      final List<Map<String, dynamic>> list = ref.read(aiProvider).chatList;
      if (list.isNotEmpty) {
        final Map<String, dynamic> last = list.last;
        final List<dynamic> story = (last['story'] as List?) ?? <dynamic>[];
        if (story.isNotEmpty && story.first is Map) {
          (story.first as Map)['text'] =
              '${_kThinking.resolve(ref.read(languageProvider))}$remaining';
        }
      }
    });

    final Map<String, dynamic> data =
        await ref.read(aimodelApiProvider).replyChallenge(
              aicode: aicodeChat,
              prompt: prompt4base,
              history: history,
              imgNum: state.imgNumToCreate,
              autoTTS: state.autoTTS,
            );
    _timer?.cancel();
    if (!mounted) return;
    ai.setLoadingSend(false);

    if (data['promptUuid'] != null) {
      promptObj['chatUuid'] = data['promptUuid'];
      ai.setPromptUuid(data['promptUuid'].toString());
    }

    if (bok(data['_state']?.toString())) {
      final Map<String, dynamic> newBalance = <String, dynamic>{
        'balanceTUC': data['newBalance'],
      };
      ref.read(appStartupProvider.notifier).mergeOnlineUser(newBalance);
      ai.replaceLastChat(<String, dynamic>{
        'role': data['role'] ?? 'assistant',
        'chatTimeUnix': data['chatTimeUnix'],
        'aicode': data['aicode'],
        'aiUsage': data['aiUsage'],
        'tucCost': data['tucCost'],
        'timeCost': data['timeCost'],
        'story': data['aiReply'] ?? <Map<String, dynamic>>[],
      });
      _scrollToEnd();
    } else {
      ai.replaceLastChat(<String, dynamic>{
        'role': 'assistant',
        'chatTimeUnix': DateTime.now().millisecondsSinceEpoch,
        'story': <Map<String, dynamic>>[
          <String, dynamic>{'text': _errorText(data)},
        ],
      });
    }
  }

  String _errorText(Map<String, dynamic> data) {
    final String lang = ref.read(languageProvider);
    if (data['_msg'] != null) return LangText.fromMap(data['_msg']).resolve(lang);
    return PartTexts.systemDown.resolve(lang);
  }

  Future<void> _resetThread() async {
    final bool confirmed = await showPexModal(
      context,
      ref,
      title: _kClearChat,
      showCancel: true,
    );
    if (!confirmed) return;
    final Map<String, dynamic> data =
        await ref.read(aimodelApiProvider).resetThread(ref.read(aiProvider).aicodeNow);
    if (!mounted) return;
    if (bok(data['_state']?.toString())) {
      ref.read(aiProvider.notifier).setChatList(<Map<String, dynamic>>[]);
      showPexToast(context, ref, _kResetDone);
    } else {
      showPexToast(context, ref, LangText.fromMap(data['_msg']));
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickModel() async {
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: SingleChildScrollView(
          child: PartAippModels(
            onPick: (String aicode) => Navigator.of(context).pop(aicode),
          ),
        ),
      ),
    );
    if (picked == null) return;
    ref.read(aiProvider.notifier).setAicodeNow(picked);
    final List<AiModel> models = ref.read(aiModelListProvider);
    for (final AiModel model in models) {
      if (model.aicode == picked) {
        ref.read(aiProvider.notifier).setAintNow(model.raw);
        break;
      }
    }
    ref.read(aiProvider.notifier).setChatList(<Map<String, dynamic>>[]);
    await _loadHistory(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final AppStartupState startup = ref.watch(appStartupProvider);
    if (!startup.afterAutologging) return const PartShowLoading();
    if (!_inited) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _init());
    }

    final AiState ai = ref.watch(aiProvider);
    final String lang = ref.watch(languageProvider);
    final AiModel? model = ai.modelNow;

    return Container(
      color: PexColors.bg,
      child: Column(
        children: <Widget>[
          _buildHeader(model, lang),
          if (ai.chatList.isEmpty && !_loadingHistory)
            _buildWelcome(model, lang)
          else
            Expanded(child: _buildChatList(lang)),
          _buildSettingsBar(ai, model, lang),
          model != null && (model.isImageChat || model.isAibot)
              ? _buildStoryEditor(ai, lang)
              : _buildInputBar(ai, lang),
        ],
      ),
    );
  }

  Widget _buildHeader(AiModel? model, String lang) {
    final AiState ai = ref.watch(aiProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  model == null ? '' : model.ainame.resolve(lang),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (model != null)
                  Text(
                    '${model.aiprice.resolve(lang)} · ${model.aiprovider.resolve(lang)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF909399)),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _resetThread,
            tooltip: _kClearChat.resolve(lang),
            icon: PexIcon.uni('compose', size: 22, color: PexColors.grey6),
          ),
          IconButton(
            onPressed: () => _loadHistory(),
            tooltip: 'Load more',
            icon: PexIcon.uni('refreshempty', size: 22, color: PexColors.grey6),
          ),
          PartBreathingOpacity(
            isBreathing: !ai.loadingSend,
            child: PexIcon.uni('hand-down', size: 22, color: PexColors.grey6),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome(AiModel? model, String lang) {
    // 模型详情尚未返回（如 Aibot 需 get_aipp）时显示加载中；否则显示该模型的介绍语。
    if (model == null) {
      return const Expanded(child: PartShowLoading());
    }
    final String text = model.ainote.resolve(lang);
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            text.isEmpty ? model.ainame.resolve(lang) : text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF909399)),
          ),
        ),
      ),
    );
  }

  Widget _buildChatList(String lang) {
    final List<Map<String, dynamic>> list = ref.watch(aiProvider).chatList;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      itemCount: list.length,
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> chat = list[index];
        final bool isUser = chat['role']?.toString() == 'user';
        return _buildChatItem(context, ref, lang, chat, isUser);
      },
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    WidgetRef ref,
    String lang,
    Map<String, dynamic> chat,
    bool isUser,
  ) {
    final List<dynamic> story = (chat['story'] as List?) ?? <dynamic>[];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!isUser) _buildAvatar(chat, isUser: false),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                GestureDetector(
                  // 源项目是**点击**气泡弹操作菜单（`partMenuRing`）；长按留给触屏用户。
                  onTap: () => _showMessageActions(chat, story),
                  onLongPress: () => _showMessageActions(chat, story),
                  child: PartStoryReader(story: story),
                ),
                if (chat['tucCost'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${numberPrecision(chat['tucCost'])}${ref.watch(envarProvider).tucSymbol}'
                      '${chat['timeCost'] == null ? '' : ' · ${numberPrecision(chat['timeCost'], 1)}s'}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) _buildAvatar(chat, isUser: true),
        ],
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> chat, {required bool isUser}) {
    final String portrait = isUser
        ? ref.read(onlineUserProvider)['portrait']?.toString() ?? ''
        : chat['portrait']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ClipOval(
        child: SizedBox(
          width: 32,
          height: 32,
          child: portrait.isEmpty
              ? Container(
                  color: isUser ? PexColors.greyC : PexColors.grey6,
                  child: PexIcon.uni(
                    isUser ? 'person-filled' : 'chatboxes',
                    size: 18,
                    color: Colors.white,
                  ),
                )
              : ServerImage(portrait, fit: BoxFit.cover),
        ),
      ),
    );
  }

  /// 消息操作菜单，对应源项目 `partMenuRing` + `act_on_message`。
  ///
  /// 可用动作按内容过滤（有文字才「朗读」、有图才「预览」），「转存」仅 Babelyx 有。
  /// 源项目是径向环形菜单，这里改为底部操作表（Web/桌面更好点，动作集合与行为保持一致）。
  Future<void> _showMessageActions(
    Map<String, dynamic> chat,
    List<dynamic> story,
  ) async {
    final String lang = ref.read(languageProvider);
    final bool hasText = story.any((dynamic section) =>
        section is Map && ((section['text'] ?? '').toString().isNotEmpty));
    final bool hasImage = story.any((dynamic section) =>
        section is Map && (section['image'] ?? '').toString().isNotEmpty);
    final bool canSave = ref.read(brandProvider).appkey == 'AKBABELY';

    final String? action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _actionRow('drop', Icons.delete_outline, _kDrop, const Color(0xFFFF2972), lang),
            _actionRow('copy', Icons.copy, _kCopy, const Color(0xFF01BDAB), lang),
            if (canSave)
              _actionRow('save', Icons.upload_outlined, _kSave, const Color(0xFF00B0FE), lang),
            if (hasText)
              _actionRow('read', Icons.volume_up_outlined, _kRead, const Color(0xFFA529FF), lang),
            if (hasImage)
              _actionRow('preview', Icons.visibility_outlined, _kPreview, const Color(0xFFFEA600), lang),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    await _actOnMessage(action, chat, story);
  }

  Widget _actionRow(
    String action,
    IconData icon,
    LangText label,
    Color color,
    String lang,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label.resolve(lang)),
      onTap: () => Navigator.of(context).pop(action),
    );
  }

  /// 执行某个动作（源项目 `act_on_message`）。
  Future<void> _actOnMessage(
    String action,
    Map<String, dynamic> chat,
    List<dynamic> story,
  ) async {
    switch (action) {
      case 'copy':
        await _copyMessage(story);
      case 'read':
        await _readMessage(story);
      case 'drop':
        await _dropMessage(chat, story);
      case 'preview':
        await _previewMessage(story);
      case 'save':
        await _saveMessage(story);
    }
  }

  /// 拷贝：文字直接拼，媒体按 markdown 形式（与源项目 `act_on_message('copy')` 一致）。
  Future<void> _copyMessage(List<dynamic> story) async {
    final List<String> parts = <String>[];
    for (final dynamic raw in story) {
      if (raw is! Map) continue;
      final Map<dynamic, dynamic> section = raw;
      final String text =
          (section['textRejected'] ?? section['text'] ?? '').toString();
      final String image = (section['image'] ?? '').toString();
      final String video = (section['video'] ?? '').toString();
      final String link =
          (section['link'] ?? section['linkTarget'] ?? '').toString();
      final Object? file = section['file'];
      if (text.isNotEmpty) {
        parts.add(text);
      } else if (image.isNotEmpty) {
        parts.add('[image](${makeServerUrl(image, ref.read(envarProvider))})');
      } else if (video.isNotEmpty) {
        parts.add('[video](${makeServerUrl(video, ref.read(envarProvider))})');
      } else if (link.isNotEmpty) {
        parts.add(
            '[${section['_linkText'] ?? ''}](${makeServerUrl(link, ref.read(envarProvider))})');
      } else if (file is Map) {
        parts.add(
            '[file:${file['originalname'] ?? ''}](${makeServerUrl(file['cid']?.toString(), ref.read(envarProvider))})');
      }
    }
    await Clipboard.setData(ClipboardData(text: parts.join('\n')));
    if (mounted) showPexToast(context, ref, _kCopied);
  }

  /// 朗读：只送文字段落，成功后播放音频并按 `tucCost` 扣费（源项目 `act_on_message('read')`）。
  Future<void> _readMessage(List<dynamic> story) async {
    final List<String> texts = <String>[
      for (final dynamic raw in story)
        if (raw is Map && (raw['text'] ?? '').toString().isNotEmpty)
          (raw['textRejected'] ?? raw['text']).toString(),
    ];
    if (texts.isEmpty) return;

    final Map<String, dynamic> data =
        await ref.read(aimodelApiProvider).textToSpeech(texts.join('\n'));
    if (!mounted) return;

    if (!bok(data['_state']?.toString())) {
      final LangText message = LangText.fromMap(data['_msg']);
      showPexToast(context, ref, message.isEmpty ? _kCannotRead : message);
      return;
    }

    final String audio = data['ttsAudio']?.toString() ?? '';
    if (audio.isNotEmpty) {
      final AudioPlayer player = AudioPlayer();
      await player.play(
        UrlSource(makeServerUrl(audio, ref.read(envarProvider))),
      );
    }
    // 扣费：源项目同时更新余额与 `sumOutTTS`。
    final num cost = _numOf(data['tucCost']);
    if (cost > 0) {
      final Map<String, dynamic> user = ref.read(onlineUserProvider);
      ref.read(appStartupProvider.notifier).mergeOnlineUser(<String, dynamic>{
        'balanceTUC': numberPrecision(_numOf(user['balanceTUC']) - cost),
        'sumOutTTS': numberPrecision(_numOf(user['sumOutTTS']) + cost),
      });
    }
  }

  /// 删除：确认弹窗 → 有 `chatUuid` 走后端，否则只删本地（源项目 `act_on_message('drop')`）。
  Future<void> _dropMessage(
    Map<String, dynamic> chat,
    List<dynamic> story,
  ) async {
    final List<String> preview = <String>[
      for (final dynamic raw in story)
        if (raw is Map)
          if ((raw['text'] ?? '').toString().isNotEmpty)
            raw['text'].toString()
          else if ((raw['image'] ?? '').toString().isNotEmpty)
            '<img:${makeServerUrl(raw['image'].toString(), ref.read(envarProvider))}>'
          else if ((raw['link'] ?? raw['linkTarget'] ?? '').toString().isNotEmpty)
            '<link:${raw['_linkText'] ?? ''}>',
    ];

    final bool confirmed = await showPexModal(
      context,
      ref,
      title: _kDropTitle,
      content: LangText.from(preview.join('\n')),
      confirmText: _kDropConfirm,
      showCancel: true,
    );
    if (!confirmed || !mounted) return;

    final String chatUuid = chat['chatUuid']?.toString() ?? '';
    if (chatUuid.isNotEmpty) {
      final Map<String, dynamic> data =
          await ref.read(aimodelApiProvider).deleteChatItem(
                chatUuid: chatUuid,
                chatTimeUnix: _intOf(chat['chatTimeUnix']),
              );
      if (!mounted) return;
      if (!bok(data['_state']?.toString())) {
        final LangText message = LangText.fromMap(data['_msg']);
        showPexToast(context, ref,
            message.isEmpty ? PartTexts.systemDown : message);
        return;
      }
    }
    ref.read(aiProvider.notifier).setChatList(
          ref
              .read(aiProvider)
              .chatList
              .where((Map<String, dynamic> item) => item != chat)
              .toList(),
        );
  }

  /// 预览：把消息里的图片摊开成画廊（源项目用 `uni.previewImage`）。
  Future<void> _previewMessage(List<dynamic> story) async {
    final List<String> images = <String>[
      for (final dynamic raw in story)
        if (raw is Map && (raw['image'] ?? '').toString().isNotEmpty)
          makeServerUrl(raw['image'].toString(), ref.read(envarProvider)),
    ];
    if (images.isEmpty) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext dialogContext) => GestureDetector(
        onTap: () => Navigator.of(dialogContext).pop(),
        child: PageView(
          children: <Widget>[
            for (final String url in images)
              InteractiveViewer(
                child: Center(child: ServerImage(url, fit: BoxFit.contain)),
              ),
          ],
        ),
      ),
    );
  }

  /// 转存：把该段并入创作草稿（源项目 `act_on_message('save')`）。
  Future<void> _saveMessage(List<dynamic> story) async {
    final CreationDraftNotifier draft = ref.read(creationDraftProvider.notifier);
    draft.setStory(<Map<String, dynamic>>[
      ...ref.read(creationDraftProvider).story,
      ...story.whereType<Map>().map((Map item) => item.cast<String, dynamic>()),
    ]);
    if (!mounted) return;
    final bool goCreate = await showPexModal(
      context,
      ref,
      title: _kSavedTitle,
      content: _kSavedContent,
      confirmText: _kGoCreate,
      cancelText: _kStayAigc,
      showCancel: true,
    );
    if (goCreate && mounted) {
      context.go(AppRoutes.path(AppRoutes.midBabely));
    }
  }

  static num _numOf(Object? value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;

  static int _intOf(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  Widget _buildSettingsBar(AiState ai, AiModel? model, String lang) {
    final bool isText = ai.isTextModel;
    final bool isImage = model?.isImageChat == true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: _pickModel,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  model == null ? 'AI' : model.ainame.resolve(lang),
                  style: const TextStyle(fontSize: 13, color: PexColors.grey6),
                ),
                PexIcon.uni('bottom', size: 14, color: PexColors.grey6),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (isText)
            _numberBox(
              label: _kMemory.resolve(lang),
              value: ai.contextToRemember,
              onChanged: ref.read(aiProvider.notifier).setContextToRemember,
            ),
          if (isImage)
            _numberBox(
              label: _kImgNum.resolve(lang),
              value: ai.imgNumToCreate,
              onChanged: ref.read(aiProvider.notifier).setImgNumToCreate,
            ),
          const Spacer(),
          Text(
            '${numberPrecision(ref.watch(onlineUserProvider)['balanceTUC'])}'
            '${ref.watch(envarProvider).tucSymbol}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF909399)),
          ),
        ],
      ),
    );
  }

  Widget _numberBox({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: const TextStyle(fontSize: 13, color: PexColors.grey6)),
          IconButton(
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$value', style: const TextStyle(fontSize: 14)),
          IconButton(
            onPressed: () => onChanged(value + 1),
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  /// story 模式输入（图片对话模型或 Aibot），对应源项目 `partStoryEditor` 的用法。
  Widget _buildStoryEditor(AiState ai, String lang) {
    final AiModel? model = ai.modelNow;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: PartStoryEditor(
        story: ai.promptStory,
        onStoryChanged: ref.read(aiProvider.notifier).setPromptStory,
        allowImage: model?.isImageChat == true,
        allowFile: model?.isAibot == true,
        allowSpeak: true,
        allowVideo: false,
        textPlaceholder: const LangText(
          zhCN: '请随意提问！',
          enUS: 'Ask any question! ',
        ),
        publishing: ai.loadingSend,
        busy: ai.loadingSend,
        onPublish: () => _send(storylike: true),
      ),
    );
  }

  Widget _buildInputBar(AiState ai, String lang) {
    return Container(
      color: PexColors.bg,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44, maxHeight: 160),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _input,
                maxLines: null,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: _kInputHint.resolve(lang),
                  hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: FilledButton(
              onPressed: ai.loadingSend || _input.text.trim().isEmpty ? null : _send,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child: ai.loadingSend
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : PexIcon.uni('paperplane-filled', size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T it) block) => block(this);
}
