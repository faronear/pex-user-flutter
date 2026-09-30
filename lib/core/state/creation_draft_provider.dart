/// 创作草稿状态，对应源项目 `wo.ss.Creation.ctnCreate`（新建）与 `ctnUpdate`（修改）。
///
/// 两者结构完全一致，源项目的 `partCreate` 也是同一个组件靠 `ctnNow` 复用，
/// 因此这里用一个 Notifier 承载「当前正在编辑的作品」，由 [initCreate] / [initUpdate] 装载。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/creation.dart';
import '../api/api_client.dart';
import '../api/creation_api.dart';
import 'envar_provider.dart';

/// 新建作品的初始草稿（对应源项目 `App.data.js` 的 `creation_reset_pexNew`）。
Map<String, dynamic> newCreationDraft() => <String, dynamic>{
      'pexdataRaw': <Map<String, dynamic>>[<String, dynamic>{'text': ''}],
      'openTitle': '',
      'openCover': '',
      'viewerPact': <String, dynamic>{'type': 'PAYABLE', 'amount': '', 'coin': 'TUC'},
      'holderPact': <String, dynamic>{
        'type': 'FORBIDDEN',
        'amount': '',
        'quota': '',
        'coin': 'TUC'
      },
      'workerPact': <String, dynamic>{
        'type': 'FORBIDDEN',
        'amount': '',
        'share': '',
        'coin': 'TUC'
      },
      'ownerPact': <String, dynamic>{'type': 'FORBIDDEN', 'amount': '', 'coin': 'TUC'},
    };

class CreationDraftState {
  const CreationDraftState({
    this.raw = const <String, dynamic>{},
    this.readyShow = false,
    this.notFound = false,
    this.denied = false,
  });

  /// 草稿本体（`partCreate` 以 `ctnNow` 形式读写它）。
  final Map<String, dynamic> raw;

  final bool readyShow;

  /// 修改模式下按 unid 找不到作品。
  final bool notFound;

  /// 修改模式下本人既非原创主也非权利主。
  final bool denied;

  /// 是否为「修改已有作品」（有 csid）。
  bool get isUpdate => (raw['csid']?.toString() ?? '').isNotEmpty;

  Creation get creation => Creation(raw);

  List<Map<String, dynamic>> get story =>
      (raw['pexdataRaw'] as List?)?.cast<Map<String, dynamic>>() ??
      <Map<String, dynamic>>[];

  Map<String, dynamic> get viewerPact => _pact('viewerPact');

  Map<String, dynamic> get holderPact => _pact('holderPact');

  Map<String, dynamic> get workerPact => _pact('workerPact');

  Map<String, dynamic> get ownerPact => _pact('ownerPact');

  Map<String, dynamic> _pact(String key) {
    final Object? value = raw[key];
    return value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
  }

  CreationDraftState copyWith({
    Map<String, dynamic>? raw,
    bool? readyShow,
    bool? notFound,
    bool? denied,
  }) =>
      CreationDraftState(
        raw: raw ?? this.raw,
        readyShow: readyShow ?? this.readyShow,
        notFound: notFound ?? this.notFound,
        denied: denied ?? this.denied,
      );
}

class CreationDraftNotifier extends Notifier<CreationDraftState> {
  @override
  CreationDraftState build() => const CreationDraftState();

  /// 新建：装载空白草稿（对应源项目 `creation_reset_pexNew`）。
  void initCreate() {
    state = CreationDraftState(raw: newCreationDraft(), readyShow: true);
  }

  /// 修改：按 unid 取回作品，并校验当前用户是原创主或权利主
  /// （对应源项目 `showCreationUpdate.vue` 的 `onLoad`）。
  Future<void> initUpdate(String csid) async {
    state = const CreationDraftState();
    final Map<String, dynamic> data =
        await ref.read(creationApiProvider).getSingleCreation(csid: csid);
    if (!bok(data['_state']?.toString())) {
      state = const CreationDraftState(readyShow: true, notFound: true);
      return;
    }
    final Map<String, dynamic> creation =
        (data['creation'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final String usid = ref.read(onlineUserProvider)['usid']?.toString() ?? '';
    final List<String> owners = <String>[
      creation['creatorUsid']?.toString() ?? '',
      creation['ownerUsid']?.toString() ?? '',
    ];
    if (creation['csid'] == null || usid.isEmpty || !owners.contains(usid)) {
      state = CreationDraftState(
        raw: creation,
        readyShow: true,
        denied: creation['csid'] != null,
        notFound: creation['csid'] == null,
      );
      return;
    }
    state = CreationDraftState(
      raw: <String, dynamic>{
        ...creation,
        // 源项目：编辑的是「用户内容」（非加密态）。
        'pexdataRaw': creation['pexdataUser'] ?? <Map<String, dynamic>>[<String, dynamic>{'text': ''}],
      },
      readyShow: true,
    );
  }

  /// 置顶层字段（标题 / 封面）。
  void setField(String key, Object? value) {
    state = state.copyWith(raw: <String, dynamic>{...state.raw, key: value});
  }

  /// 置 story 段落（编辑器每次改动都会回传新数组）。
  void setStory(List<Map<String, dynamic>> story) {
    state = state.copyWith(
      raw: <String, dynamic>{...state.raw, 'pexdataRaw': story},
    );
  }

  /// 置某个合约的字段（如 `holderPact.type`）。
  void setPact(String pactKey, String field, Object? value) {
    final Map<String, dynamic> pact = <String, dynamic>{
      ...(state.raw[pactKey] is Map
          ? (state.raw[pactKey] as Map).cast<String, dynamic>()
          : <String, dynamic>{}),
      field: value,
    };
    state = state.copyWith(
      raw: <String, dynamic>{...state.raw, pactKey: pact},
    );
  }

  void reset() => state = const CreationDraftState();
}

final NotifierProvider<CreationDraftNotifier, CreationDraftState>
    creationDraftProvider =
    NotifierProvider<CreationDraftNotifier, CreationDraftState>(
        CreationDraftNotifier.new);
