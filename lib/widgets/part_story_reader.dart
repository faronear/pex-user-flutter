/// 故事渲染，对应源项目 `parts/partStoryReader.vue`。
///
/// 支持段落类型：文本 / 图片 / 视频 / 音频 / 链接 / 文件；
/// 音频暂以链接形式呈现（原生播放待阶段四）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/state/envar_provider.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../theme/app_theme.dart';
import 'part_text_reader.dart';

const LangText _kValidUntil = LangText(
  zhCN: '有效期至 ',
  enUS: 'Valid until ',
  jaJP: '有効期限: ',
  deDE: 'Gültig bis ',
);

const LangText _kSize = LangText(zhCN: '大小：', enUS: 'Size: ');

const LangText _kUnknownType = LangText(zhCN: '未知内容类型', enUS: 'Unknown content type');

class PartStoryReader extends ConsumerWidget {
  const PartStoryReader({super.key, required this.story});

  final List<dynamic> story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: PexColors.bg,
        border: Border.all(color: PexColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final dynamic raw in story)
            if (raw is Map) _buildSection(context, ref, raw.cast<String, dynamic>()),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, WidgetRef ref, Map<String, dynamic> section) {
    if (section.containsKey('text') ||
        section['textIpfs'] != null ||
        section['_autocontent'] != null) {
      return Padding(
        padding: const EdgeInsets.all(5),
        child: PartTextReader(section: section),
      );
    }
    if (section['image'] != null) {
      return Padding(
        padding: const EdgeInsets.all(5),
        child: GestureDetector(
          onTap: () => _openUrl(context, ref, section['image']),
          child: ServerImage(
            section['image']?.toString(),
            fit: BoxFit.fitWidth,
            width: double.infinity,
          ),
        ),
      );
    }
    if (section['video'] != null) {
      return _linkBlock(
        context,
        ref,
        icon: 'uniui-videocam',
        title: section['_originalname']?.toString() ?? section['video'].toString(),
        onTap: () => _openUrl(context, ref, section['video']),
      );
    }
    if (section['audio'] != null) {
      return _linkBlock(
        context,
        ref,
        icon: 'uniui-sound',
        title: section['_originalname']?.toString() ?? section['audio'].toString(),
        onTap: () => _openUrl(context, ref, section['audio']),
      );
    }
    if (section['linkTarget'] != null || section['link'] != null) {
      return _linkBlock(
        context,
        ref,
        icon: 'icont-hyperlink',
        title: (section['linkTarget'] ?? section['link']).toString(),
        subtitle: _expireText(context, ref, section['linkExpireAt']),
        onTap: () => _openUrl(context, ref, section['linkTarget'] ?? section['link']),
      );
    }
    if (section['file'] != null) {
      final Map<String, dynamic> file =
          (section['file'] as Map).cast<String, dynamic>();
      return _linkBlock(
        context,
        ref,
        icon: 'icont-file-line',
        title: file['originalname']?.toString() ?? file['cid'].toString(),
        subtitle: file['size'] == null
            ? null
            : '${_resolve(context, ref, _kSize)}${segmentNumber(file['size'])}',
        onTap: () => _openUrl(context, ref, file['cid']),
      );
    }
    return Container(
      padding: const EdgeInsets.all(5),
      color: const Color(0xFFEEEEEE),
      child: Text(
        _resolve(context, ref, _kUnknownType),
        style: const TextStyle(color: Color(0xFF19BE6B), fontSize: 14),
      ),
    );
  }

  Widget _linkBlock(
    BuildContext context,
    WidgetRef ref, {
    required String icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PexIcon(
                PexIcons.byPrefix(icon.startsWith('icont') ? 'icont' : null, icon),
                size: 22,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(color: Color(0xFF2979FF), fontSize: 14),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        subtitle,
                        style: const TextStyle(color: Color(0xFF909399), fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _expireText(BuildContext context, WidgetRef ref, Object? expireAt) {
    if (expireAt == null) return '';
    return '${_resolve(context, ref, _kValidUntil)}'
        '${formatDate(expireAt, 'yyyy-mm-dd HH:MM')}';
  }

  String _resolve(BuildContext context, WidgetRef ref, LangText text) =>
      text.resolve(ref.read(languageProvider));

  Future<void> _openUrl(BuildContext context, WidgetRef ref, Object? path) async {
    final String url = makeServerUrl(path?.toString(), ref.read(envarProvider));
    if (url.isEmpty) return;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
