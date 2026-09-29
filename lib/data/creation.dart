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

/// 详情页（`showCreation`）封面遮罩种类，对应源项目模板里的一串 `v-if/v-else-if`。
enum ShowCoverKind {
  /// 被后台拒绝服务（`lifeState === 'CREATION_BANNED_BY_SYSTEM'`）。
  refused,

  /// 已被本人彻底删除。
  deletedByMe,

  /// 已被本人隐藏。
  hidden,

  /// 主人已被本人屏蔽。
  blocked,

  /// 已被下架，且与本人无关、未解密/未持有。
  unlisted,

  /// 中国区待审查（需已有 `pexdataUser`）。
  censoring,

  /// 有内容，正常渲染。
  content,

  /// 已加密、需解密后才有内容。
  locked,
}

/// 合约（pact）只读视图，对应源项目作品里的 `viewerPact` / `holderPact` / `ownerPact` / `workerPact`。
class Pact {
  const Pact(this.raw);

  final Map<String, dynamic> raw;

  static const Pact empty = Pact(<String, dynamic>{});

  factory Pact.of(Object? value) =>
      value is Map ? Pact(value.cast<String, dynamic>()) : empty;

  String get type => raw['type']?.toString() ?? '';

  String get coin => raw['coin']?.toString() ?? '';

  num get amount => _numOf(raw['amount']);

  /// 代理权分成比例（`workerPact.share`）。
  num get share => _numOf(raw['share']);

  /// 库存上限；空/0 视为无限。
  num? get quota {
    final Object? value = raw['quota'];
    if (value == null || value.toString().isEmpty) return null;
    final num? parsed = value is num ? value : num.tryParse(value.toString());
    if (parsed == null || !parsed.isFinite || parsed == 0) return null;
    return parsed;
  }

  bool get forbidden => type == 'FORBIDDEN';

  bool get payable => type == 'PAYABLE';
}

num _numOf(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
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

  String get creatorUsid => raw['creatorUsid']?.toString() ?? '';

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

  // ---- 详情页（showCreation）所需 ----

  String get lifeState => raw['lifeState']?.toString() ?? '';

  String get ownerState => raw['ownerState']?.toString() ?? '';

  String get creatorState => raw['creatorState']?.toString() ?? '';

  String get hideState => raw['hideState']?.toString() ?? '';

  String get blockState => raw['blockState']?.toString() ?? '';

  String get nftToid => raw['nftToid']?.toString() ?? '';

  String get nftContract => raw['nftContract']?.toString() ?? '';

  /// 是否已铸造成 NFT（有 tokenId 与合约地址）。
  bool get hasNft => nftToid.isNotEmpty && nftContract.isNotEmpty;

  /// 当前内容所在 IPFS 根（源项目 `pexBaseCidNow`）。
  String get pexBaseCidNow => raw['pexBaseCidNow']?.toString() ?? '';

  /// 原创内容根（源项目 `pexBaseCidRoot`；为空即「周边栏」不显示）。
  String get pexBaseCidRoot => raw['pexBaseCidRoot']?.toString() ?? '';

  Pact get viewerPact => Pact.of(raw['viewerPact']);

  Pact get holderPact => Pact.of(raw['holderPact']);

  Pact get ownerPact => Pact.of(raw['ownerPact']);

  Pact get workerPact => Pact.of(raw['workerPact']);

  int get countViewer => _intOf(raw['countViewer']);

  int get countHolder => _intOf(raw['countHolder']);

  int get countComment => _intOf(raw['countComment']);

  int get countLike => _intOf(raw['countLike']);

  int get countFueler => _intOf(raw['countFueler']);

  num get amountFuel => _numOf(raw['amountFuel']);

  bool get bannedBySystem => lifeState == 'CREATION_BANNED_BY_SYSTEM';

  bool get unlistedByOwner => ownerState == 'UNLISTED';

  /// 本人（原创主或权利主）下架了这个作品。
  bool unlistedByMe(String usid) =>
      usid.isNotEmpty &&
      ((usid == ownerUsid && ownerState == 'UNLISTED') ||
          (usid == creatorUsid && creatorState == 'UNLISTED'));

  /// 本人已彻底删除（任一方 DELETED_*，或 `hideState === 'HIDE2DEL'`）。
  bool deletedByMe(String usid) =>
      (usid.isNotEmpty && usid == ownerUsid && ownerState == 'DELETED_BY_OWNER') ||
      (usid.isNotEmpty && usid == creatorUsid && creatorState == 'DELETED_BY_CREATOR') ||
      hideState == 'HIDE2DEL';

  /// 本人已解密或已持有（因此即便被下架也仍可见）。
  bool get linkedByMe =>
      raw['mytxHold_txAmount'] != null || raw['mytxView_txAmount'] != null;

  /// 本人是原创主或权利主。
  bool belongToMe(String usid) =>
      usid.isNotEmpty && (ownerUsid == usid || creatorUsid == usid);

  /// 剩余库存 = `holderPact.quota - countHolder`；无限（quota 空/0）返回 null。
  num? get stockNumber {
    final num? quota = holderPact.quota;
    if (quota == null) return null;
    return quota - countHolder;
  }

  /// 详情页封面遮罩判定，优先级与源项目模板一致。
  ShowCoverKind showCoverKind({
    required String usid,
    required String userlandCode,
    required List<String> banChina,
  }) {
    if (bannedBySystem) return ShowCoverKind.refused;
    if (deletedByMe(usid)) return ShowCoverKind.deletedByMe;
    if (hideState == 'HIDED') return ShowCoverKind.hidden;
    if (blockState == 'BLOCKED') return ShowCoverKind.blocked;
    if (unlistedByOwner && !unlistedByMe(usid) && !linkedByMe) {
      return ShowCoverKind.unlisted;
    }
    if (unlocked) {
      if (needsCensorMask(userlandCode, banChina)) return ShowCoverKind.censoring;
      return ShowCoverKind.content;
    }
    return ShowCoverKind.locked;
  }
}

int _intOf(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
