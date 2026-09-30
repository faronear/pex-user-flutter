/// 创作品卡片列表，对应源项目 `parts/partCreationCardList.vue`。
///
/// 卡片结构（自上而下）：封面（3 种状态）→ 标题栏（标题 + 头像）→ 统计条（金额 + 我和它的关系）→ 禁用遮罩。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/state/envar_provider.dart';
import '../core/state/region_provider.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../data/creation.dart';
import '../theme/app_theme.dart';
import 'part_pexdata_summary.dart';
import 'part_text_reader.dart';

const LangText _kNoContent = LangText(zhCN: '没有内容', enUS: 'No Content');

const LangText _kNoAccess = LangText(zhCN: '禁止访问', enUS: 'No Access');

const LangText _kInvisible = LangText(zhCN: '禁止解密', enUS: 'Invisible');

const LangText _kCensoring = LangText(zhCN: '等待中国区审查中', enUS: 'Waiting China Censoring');

const LangText _kRefused = LangText(zhCN: '已被拒绝服务', enUS: 'Refused');

const LangText _kHidden = LangText(zhCN: '已被您隐藏', enUS: 'Hidden by You');

const LangText _kBlocked = LangText(zhCN: '已被您屏蔽', enUS: 'Blocked by You');

const LangText _kUnlisted = LangText(zhCN: '已下架', enUS: 'Unlisted');

class PartCreationCardList extends ConsumerWidget {
  const PartCreationCardList({
    super.key,
    required this.pexList,
    this.twoColumnOnPhone = false,
    this.inCreatorCard = false,
    this.hideAvatar = false,
    this.hideInfobar = false,
  });

  final List<Map<String, dynamic>> pexList;
  final bool twoColumnOnPhone;

  /// 创作者主页里的小卡片（更紧凑）。
  final bool inCreatorCard;
  final bool hideAvatar;
  final bool hideInfobar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DeviceInfo device = DeviceInfo.of(context);
    final double width = MediaQuery.sizeOf(context).width;
    final List<double> columns = device.inPc
        ? <double>[345]
        : device.inPad
            ? <double>[width / 3]
            : twoColumnOnPhone
                ? <double>[width / 2]
                : <double>[width];
    final double itemWidth = columns.first;

    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      children: <Widget>[
        for (final Map<String, dynamic> raw in pexList)
          SizedBox(
            width: itemWidth,
            child: Padding(
              padding: EdgeInsets.all(inCreatorCard ? 0 : 10),
              child: _CreationCard(
                creation: Creation.of(raw),
                inCreatorCard: inCreatorCard,
                hideAvatar: hideAvatar,
                hideInfobar: hideInfobar,
              ),
            ),
          ),
      ],
    );
  }
}

class _CreationCard extends ConsumerWidget {
  const _CreationCard({
    required this.creation,
    required this.inCreatorCard,
    required this.hideAvatar,
    required this.hideInfobar,
  });

  final Creation creation;
  final bool inCreatorCard;
  final bool hideAvatar;
  final bool hideInfobar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final String usid = ref.watch(onlineUserProvider)['usid']?.toString() ?? '';
    final Map<String, dynamic> pactDict =
        (envar.raw['pactDict'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final Object? statDict = readStatDict(envar);

    return InkWell(
      onTap: inCreatorCard
          ? null
          : () => context.push('/showCreation?unid=${creation.csid}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(inCreatorCard ? 0 : 4),
          boxShadow: inCreatorCard
              ? null
              : const <BoxShadow>[
                  BoxShadow(color: Color(0x4D000000), blurRadius: 5, spreadRadius: 0),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Cover(creation: creation),
            _TitleBar(creation: creation, lang: lang, hideAvatar: hideAvatar),
            if (!hideInfobar)
              _StatsBar(
                creation: creation,
                lang: lang,
                pactDict: pactDict,
                statDict: statDict,
                tucSymbol: envar.tucSymbol,
                isOwner: creation.isOwner(usid),
              ),
            if (creation.disabledReason.isNotEmpty)
              _DisabledCover(label: _disabledLabel(creation.disabledReason, lang), height: null),
          ],
        ),
      ),
    );
  }
}

/// 封面 3 种状态。
class _Cover extends ConsumerWidget {
  const _Cover({required this.creation});

  final Creation creation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final List<String> banChina = (envar.raw['banChina'] as List?)
            ?.map((dynamic e) => e.toString())
            .toList() ??
        const <String>[];
    final String userlandCode = ref.watch(userlandCodeProvider);

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (creation.needsCensorMask(userlandCode, banChina))
            _plainCover(<Widget>[
              Center(
                child: Text(
                  _kCensoring.resolve(lang),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFA3534), fontSize: 14),
                ),
              ),
            ])
          else if (!creation.unlocked)
            _lockedCover(ref, lang)
          else
            _contentCover(ref, lang),
        ],
      ),
    );
  }

  Widget _plainCover(List<Widget> children) => Container(
        color: const Color(0xFF333333),
        padding: const EdgeInsets.all(5),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: children),
      );

  /// 加密封面：显示封条文字 + 半透明遮罩里的摘要。
  Widget _lockedCover(WidgetRef ref, String lang) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (creation.openCover.isNotEmpty)
          ServerImage(creation.openCover, fit: BoxFit.cover)
        else
          const ColoredBox(color: Color(0xFF19BE6B)),
        Padding(
          padding: const EdgeInsets.all(5),
          child: Text(
            creation.sealText,
            style: const TextStyle(
              color: Color(0xFF19BE6B),
              fontSize: 13,
              letterSpacing: 20,
              height: 1.5,
            ),
          ),
        ),
        ColoredBox(
          color: const Color(0x99000000),
          child: Center(
            child: PartPexdataSummary(pexdataSum: creation.pexdataSum),
          ),
        ),
      ],
    );
  }

  /// 内容封面：图 / 视频 / 纯文本。
  Widget _contentCover(WidgetRef ref, String lang) {
    final String image = creation.coverImage;
    if (image.isNotEmpty) {
      return ServerImage(image, fit: BoxFit.cover);
    }
    if (creation.coverVideo.isNotEmpty) {
      // Web 可内联播放；此处统一用封面占位 + 提示，视频播放能力见阶段四。
      return _plainCover(<Widget>[
        Text(creation.coverVideo, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]);
    }
    final Map<String, dynamic>? section = creation.firstSection;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(5),
      child: creation.autocontent
          ? Center(
              child: Text(
                _kNoContent.resolve(lang),
                style: const TextStyle(color: Color(0xFF909399), fontSize: 14),
              ),
            )
          : (section != null &&
                  ((section['text']?.toString() ?? '').isNotEmpty ||
                      (section['textIpfs']?.toString() ?? '').isNotEmpty))
              ? PartTextReader(section: section)
              : Center(
                  child: PartPexdataSummary(pexdataSum: creation.pexdataSum),
                ),
    );
  }
}

class _TitleBar extends ConsumerWidget {
  const _TitleBar({required this.creation, required this.lang, required this.hideAvatar});

  final Creation creation;
  final String lang;
  final bool hideAvatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 25,
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              creation.displayTitle(lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          if (!hideAvatar)
            ClipOval(
              child: SizedBox(
                width: 25,
                height: 25,
                child: creation.portrait.isEmpty
                    ? ColoredBox(
                        color: Colors.white,
                        child: Center(
                          child: Text(
                            creation.nickname.isEmpty
                                ? ''
                                : creation.nickname.substring(
                                    0,
                                    creation.nickname.length >= 2 ? 2 : 1,
                                  ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                    : ServerImage(creation.portrait, fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.creation,
    required this.lang,
    required this.pactDict,
    required this.statDict,
    required this.tucSymbol,
    required this.isOwner,
  });

  final Creation creation;
  final String lang;
  final Map<String, dynamic> pactDict;
  final Object? statDict;
  final String tucSymbol;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: <Widget>[
          Expanded(child: _left(lang)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (creation.myViewed) _pactIcon('TVIEW', on: true),
              if (creation.myHeld) _pactIcon('THOLD', on: true),
              if (isOwner) _pactIcon('TOWN', on: false),
              if (creation.myCommented) _statIcon('comment', on: true),
              if (creation.myFueled) _statIcon('fuel', on: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _left(String lang) {
    if (creation.forbiddenAll) {
      return _badge(_kNoAccess.resolve(lang), const Color(0xFF000000));
    }
    if (creation.forbiddenDecrypt) {
      return _badge(_kInvisible.resolve(lang), const Color(0xFF808080));
    }
    final bool lockedWithPrice = !creation.unlocked && creation.viewerPactAmount > 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          numberPrecision(creation.viewerPactAmount).toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: lockedWithPrice ? const Color(0xFFFA3534) : const Color(0xFF303133),
          ),
        ),
        Text(tucSymbol, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      );

  Widget _pactIcon(String key, {required bool on}) {
    final Map<String, dynamic> item =
        (pactDict[key] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final String type = (on ? item['iconTypeOn'] : item['iconType'])?.toString() ??
        item['iconType']?.toString() ??
        '';
    if (type.isEmpty) return const SizedBox.shrink();
    final String? prefix = item['iconPrefix']?.toString();
    return PexIcon(PexIcons.byPrefix(prefix, type), size: 20, color: PexColors.greyA);
  }

  Widget _statIcon(String key, {required bool on}) {
    final Map<String, dynamic> dict =
        (statDict as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final Map<String, dynamic> item =
        (dict[key] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final String type = (on ? item['iconTypeOn'] : item['iconType'])?.toString() ?? '';
    if (type.isEmpty) return const SizedBox.shrink();
    return PexIcon(PexIcons.uni(type), size: 20, color: PexColors.greyA);
  }
}

/// 禁用遮罩（拒绝/隐藏/屏蔽/下架）。
class _DisabledCover extends StatelessWidget {
  const _DisabledCover({required this.label, this.height});

  final String label;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: const Color(0xFF333333),
      padding: const EdgeInsets.all(5),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(color: Color(0xFFEEEEEE), fontSize: 14)),
    );
  }
}

String _disabledLabel(String reason, String lang) => switch (reason) {
      'refused' => _kRefused.resolve(lang),
      'hidden' => _kHidden.resolve(lang),
      'blocked' => _kBlocked.resolve(lang),
      'unlisted' => _kUnlisted.resolve(lang),
      _ => '',
    };

/// 取 `Creation.uiStatDict`（服务端不发，来自本地预置层）。
Object? readStatDict(Envar envar) {
  final Object? creation = envar.raw['Creation'];
  return creation is Map ? creation['uiStatDict'] : null;
}


