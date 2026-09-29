/// AI 会话与 Aibot 状态，对应源项目 `wo.ss.AI`。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai_model.dart';
import 'envar_provider.dart';

/// Aibot 市场的分类标签（源项目 `wo.ss.AI.aippDict`）。
const Map<String, Map<String, String>> kAippDict = <String, Map<String, String>>{
  'AIMODELS': <String, String>{'zhCN': '基础模型', 'enUS': 'Models', 'jaJP': '基本モデル'},
  'AIPPS': <String, String>{'zhCN': '共享应用', 'enUS': 'Aibot', 'jaJP': '共有アプリ'},
  'AIPPMY': <String, String>{'zhCN': '我的应用', 'enUS': 'Favorites', 'jaJP': 'お気に入り'},
};

class AiState {
  const AiState({
    this.chatList = const <Map<String, dynamic>>[],
    this.aicodeNow = '',
    this.aintNow,
    this.promptNow = '',
    this.promptStory = const <Map<String, dynamic>>[<String, dynamic>{'text': ''}],
    this.contextToRemember = 0,
    this.temperature = 0,
    this.imgNumToCreate = 1,
    this.autoTTS = false,
    this.allChatInOne = false,
    this.aippTagNow = 'AIMODELS',
    this.aippListShared = const <Map<String, dynamic>>[],
    this.aippListPicked = const <Map<String, dynamic>>[],
    this.loadingSend = false,
    this.promptUuid = '',
  });

  /// 当前会话的消息列表（源项目 `chatList4All`）。
  final List<Map<String, dynamic>> chatList;

  /// 当前选中的模型 / Aibot 编码。
  final String aicodeNow;

  /// 当前模型 / Aibot 详情。
  final Map<String, dynamic>? aintNow;

  final String promptNow;
  final List<Map<String, dynamic>> promptStory;

  /// 记忆上下文条数（0 表示不带历史）。
  final int contextToRemember;
  final int temperature;
  final int imgNumToCreate;
  final bool autoTTS;
  final bool allChatInOne;

  /// Aibot 市场当前分类。
  final String aippTagNow;
  final List<Map<String, dynamic>> aippListShared;
  final List<Map<String, dynamic>> aippListPicked;

  final bool loadingSend;

  /// 当前会话的 thread 标识（源项目 `promptUuid` / `chatUuid`）。
  final String promptUuid;

  AiModel? get modelNow => aintNow == null ? null : AiModel(aintNow!);

  bool get isTextModel => modelNow?.isTextChat == true;

  AiState copyWith({
    List<Map<String, dynamic>>? chatList,
    String? aicodeNow,
    Map<String, dynamic>? aintNow,
    String? promptNow,
    List<Map<String, dynamic>>? promptStory,
    int? contextToRemember,
    int? temperature,
    int? imgNumToCreate,
    bool? autoTTS,
    bool? allChatInOne,
    String? aippTagNow,
    List<Map<String, dynamic>>? aippListShared,
    List<Map<String, dynamic>>? aippListPicked,
    bool? loadingSend,
    String? promptUuid,
  }) =>
      AiState(
        chatList: chatList ?? this.chatList,
        aicodeNow: aicodeNow ?? this.aicodeNow,
        aintNow: aintNow ?? this.aintNow,
        promptNow: promptNow ?? this.promptNow,
        promptStory: promptStory ?? this.promptStory,
        contextToRemember: contextToRemember ?? this.contextToRemember,
        temperature: temperature ?? this.temperature,
        imgNumToCreate: imgNumToCreate ?? this.imgNumToCreate,
        autoTTS: autoTTS ?? this.autoTTS,
        allChatInOne: allChatInOne ?? this.allChatInOne,
        aippTagNow: aippTagNow ?? this.aippTagNow,
        aippListShared: aippListShared ?? this.aippListShared,
        aippListPicked: aippListPicked ?? this.aippListPicked,
        loadingSend: loadingSend ?? this.loadingSend,
        promptUuid: promptUuid ?? this.promptUuid,
      );
}

class AiNotifier extends Notifier<AiState> {
  @override
  AiState build() => const AiState();

  void resetChat() {
    state = state.copyWith(
      chatList: <Map<String, dynamic>>[],
      promptNow: '',
      promptStory: <Map<String, dynamic>>[<String, dynamic>{'text': ''}],
      aicodeNow: '',
      aintNow: null,
      contextToRemember: 0,
      temperature: 0,
      imgNumToCreate: 1,
    );
  }

  void setAicodeNow(String aicode) => state = state.copyWith(aicodeNow: aicode);

  void setAintNow(Map<String, dynamic>? aint) {
    state = aint == null
        ? AiState(
            chatList: state.chatList,
            aicodeNow: state.aicodeNow,
            promptNow: state.promptNow,
            promptStory: state.promptStory,
            contextToRemember: state.contextToRemember,
            temperature: state.temperature,
            imgNumToCreate: state.imgNumToCreate,
            autoTTS: state.autoTTS,
            allChatInOne: state.allChatInOne,
            aippTagNow: state.aippTagNow,
            aippListShared: state.aippListShared,
            aippListPicked: state.aippListPicked,
            loadingSend: state.loadingSend,
            promptUuid: state.promptUuid,
          )
        : state.copyWith(aintNow: aint);
  }

  void setPromptNow(String value) => state = state.copyWith(promptNow: value);

  void setPromptStory(List<Map<String, dynamic>> value) =>
      state = state.copyWith(promptStory: value);

  void setChatList(List<Map<String, dynamic>> value) =>
      state = state.copyWith(chatList: value);

  void appendChat(Map<String, dynamic> item) =>
      state = state.copyWith(chatList: <Map<String, dynamic>>[...state.chatList, item]);

  void replaceLastChat(Map<String, dynamic> item) => state = state.copyWith(
        chatList: <Map<String, dynamic>>[
          ...state.chatList.take(state.chatList.length - 1),
          item,
        ],
      );

  void setLoadingSend(bool value) => state = state.copyWith(loadingSend: value);

  void setAippTagNow(String value) => state = state.copyWith(aippTagNow: value);

  void setAippListShared(List<Map<String, dynamic>> value) =>
      state = state.copyWith(aippListShared: value);

  void setAippListPicked(List<Map<String, dynamic>> value) =>
      state = state.copyWith(aippListPicked: value);

  void setContextToRemember(int value) =>
      state = state.copyWith(contextToRemember: value);

  void setImgNumToCreate(int value) => state = state.copyWith(imgNumToCreate: value);

  void setAutoTTS(bool value) => state = state.copyWith(autoTTS: value);

  void setAllChatInOne(bool value) => state = state.copyWith(allChatInOne: value);

  void setPromptUuid(String value) => state = state.copyWith(promptUuid: value);
}

final NotifierProvider<AiNotifier, AiState> aiProvider =
    NotifierProvider<AiNotifier, AiState>(AiNotifier.new);

/// 基础模型集合（源项目 `wo.ss.aiModelSet`，按后端下发顺序，过滤 hiddenModel）。
final Provider<List<AiModel>> aiModelListProvider = Provider<List<AiModel>>((ref) {
  final Map<String, dynamic> raw = ref.watch(envarProvider).raw;
  final Object? modelSet = raw['aiModelSet'];
  if (modelSet is! Map) return const <AiModel>[];
  return modelSet.values
      .map<AiModel?>((dynamic value) => AiModel.of(value))
      .whereType<AiModel>()
      .where((AiModel model) => model.aicode.isNotEmpty && !model.hiddenModel)
      .toList();
});
