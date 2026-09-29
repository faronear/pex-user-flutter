/// 内容摘要，对应源项目 `parts/partPexdataSummary.vue`。
///
/// 在「已加密」封面遮罩里，按段落类型列出字数/图片/视频/音频/文件/链接/未知的数量。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';

const LangText _kChars = LangText(zhCN: '字数', enUS: 'Chars', jaJP: '字数', deDE: 'Zeichen');
const LangText _kImages = LangText(zhCN: '图片', enUS: 'Images', jaJP: '画像', deDE: 'Bilder');
const LangText _kVideos = LangText(zhCN: '视频', enUS: 'Videos', jaJP: '動画', deDE: 'Videos');
const LangText _kAudios = LangText(zhCN: '音频', enUS: 'Audio', jaJP: '音声', deDE: 'Audio');
const LangText _kFiles = LangText(zhCN: '文件', enUS: 'Files', jaJP: 'ファイル', deDE: 'Datei');
const LangText _kLinks = LangText(zhCN: '链接', enUS: 'Links', jaJP: 'リンク', deDE: 'Links');
const LangText _kUnknown = LangText(zhCN: '未知', enUS: 'Unknown', jaJP: '不明', deDE: 'Unbekannt');

/// `pexdataSum` 的字段顺序与源项目一致（字数 → 图片 → 视频 → 音频 → 文件 → 链接 → 未知）。
const List<(String, LangText)> _kEntries = <(String, LangText)>[
  ('textLength', _kChars),
  ('imageCount', _kImages),
  ('videoCount', _kVideos),
  ('audioCount', _kAudios),
  ('fileCount', _kFiles),
  ('linkCount', _kLinks),
  ('untypeCount', _kUnknown),
];

class PartPexdataSummary extends ConsumerWidget {
  const PartPexdataSummary({super.key, required this.pexdataSum});

  final Map<String, dynamic> pexdataSum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pexdataSum.isEmpty || _isTrue(pexdataSum['emptyContent'])) {
      return const SizedBox.shrink();
    }
    final String lang = ref.watch(languageProvider);
    final List<Widget> lines = <Widget>[
      for (final (String key, LangText label) in _kEntries)
        if (_count(pexdataSum[key]) > 0)
          Text(
            '${ll(lang, label)} ${_count(pexdataSum[key])}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF19BE6B),
              fontSize: 14,
              height: 1.6,
            ),
          ),
    ];
    if (lines.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(mainAxisSize: MainAxisSize.min, children: lines),
    );
  }

  static bool _isTrue(Object? value) => value == true || value?.toString() == 'true';

  static int _count(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
