/// 创作品视图，对应源项目 `wo.ss.Creation.*` 里的创作品对象。
///
/// 后端字段较杂且随业务演进，故此处只做**只读视图 + 展示派生**，不复制原始字段。
library;

import '../core/i18n/lang_text.dart';
import '../core/util/story_utils.dart';

/// 封面呈现方式。
enum CreationCoverKind {
  /// 中国区待审查（源项目 `banChina.includes(censorState)` 且用户区为 CN）。
  censoring,

  /// 未解锁（无 `pexdataUser`）→ 显示加密封面 + 摘要。
  locked,

  /// 正常内容封面。
  content,
}

class Creation {
  const Creation(this.raw);

  final Map<String, dynamic> raw;

  static Creation of(Object? value) => Creation(
        value is Map ? value.cast<String, dynamic>() : <String, dynamic>{},
      );

  String get csid => raw['csid']?.toString() ?? '';

  String get openTitle => raw['openTitle']?.toString() ?? '';

  String get openCover => raw['openCover']?.toString() ?? '';

  String get pexdataCidHashRoot => raw['pexdataCidHashRoot']?.toString() ?? '';

  String get portrait => raw['portrait']?.toString() ?? '';

  String get nickname => raw['nickname']?.toString() ?? '';

  String get ownerUsid => raw['ownerUsid']?.toString() ?? '';

  int? get createTimeUnix {
    final Object? value = raw['createTimeUnix'];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  List<dynamic> get story => (raw['pexdataUser'] as List?) ?? <dynamic>[];

  bool get hasContent => raw['pexdataUser'] != null;

  Map<String, dynamic> get pexdataSum =>
      (raw['pexdataSum'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

  /// 标题栏文案：`openTitle`，或「无题 #`csid 后 6 位`」。
  String displayTitle(String lang) {
    if (openTitle.isNotEmpty) return openTitle;
    final String tail = csid.length >= 6 ? csid.substring(csid.length - 6) : csid;
    return '${const LangText(zhCN: '无题', enUS: 'Untitled').resolve(lang)} #$tail';
  }

  /// 封面图片：优先 `openCover`，否则取 story 里第一张图。
  String get coverImage => openCover.isNotEmpty ? openCover : filterStoryImage(story);

  String get coverVideo => filterStoryVideo(story);

  /// 加密封面文字：源项目取 `creatorSeal.cidoSeal`，否则回落到 `pexdataCidHashRoot`。
  String get sealText {
    final Object? seal = readVarchain('creatorSeal.cidoSeal', raw);
    final String text = seal?.toString() ?? '';
    return text.isNotEmpty ? text : pexdataCidHashRoot;
  }

  String get censorState => raw['censorState']?.toString() ?? '';

  /// 中国区审查态的禁用遮罩（源项目：用户区 CN 且 `banChina` 含该状态）。
  bool needsCensorMask(String userlandCode, List<String> banChina) =>
      userlandCode == 'CN' && banChina.contains(censorState);

  /// 是否已解锁（有 `pexdataUser`）。
  bool get unlocked => raw['pexdataUser'] != null;

  /// 禁用遮罩文案的 key；无遮罩返回空串。
  /// 对齐源项目：`lifeState/hideState/blockState`，以及 `ownerState|creatorState === 'UNLISTED'`。
  String get disabledReason {
    if (raw['lifeState']?.toString() == 'CREATION_BANNED_BY_SYSTEM') return 'refused';
    if (raw['hideState']?.toString() == 'HIDED') return 'hidden';
    if (raw['blockState']?.toString() == 'BLOCKED') return 'blocked';
    final List<String> states = <String>[
      raw['ownerState']?.toString() ?? '',
      raw['creatorState']?.toString() ?? '',
    ];
    if (states.contains('UNLISTED')) return 'unlisted';
    return '';
  }

  /// 汇总的金额（源项目展示 `viewerPact.amount`）。
  num get viewerPactAmount {
    final Object? pact = raw['viewerPact'];
    if (pact is Map) {
      final Object? amount = pact['amount'];
      if (amount is num) return amount;
      return num.tryParse(amount?.toString() ?? '') ?? 0;
    }
    return 0;
  }

  String get groupPactType => raw['groupPactType']?.toString() ?? '';

  String get viewerPactType => raw['viewerPactType']?.toString() ?? '';

  bool get forbiddenAll => groupPactType == 'FORBIDDEN_ALL';

  bool get forbiddenDecrypt => viewerPactType == 'FORBIDDEN';

  /// 我和这个作品的关系（用于统计条右侧图标）。
  bool get myViewed => raw['mytxView_txAmount'] != null;

  bool get myHeld => raw['mytxHold_txAmount'] != null;

  bool get myFueled => raw['mytxFuel_txAmount'] != null;

  bool get myCommented => raw['myCommentCount'] != null;

  bool isOwner(String usid) => usid.isNotEmpty && ownerUsid == usid;

  /// story 是否为空内容（源项目显示「没有内容」）。
  bool get autocontent => isAutocontent(story);

  /// 首个段落（用于纯文本封面）。
  Map<String, dynamic>? get firstSection {
    if (story.isEmpty) return null;
    final dynamic first = story.first;
    return first is Map ? first.cast<String, dynamic>() : null;
  }
}
