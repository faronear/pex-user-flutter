/// 故事编辑器：把不同类型的内容（文本/图片/视频/音频/文件/链接）组织在一个容器里。
///
/// 对应源项目 `parts/partStoryEditor.vue`。这是 AI 对话（story 模式）与创作/NFT 共用的
/// **核心内容容器**：`story` 为段落数组，每段可含 `text` / `image` / `video` / `audio` /
/// `file` / `link` 之一。
///
/// 已实现：文本段落编辑、段落增删、链接/图片/视频/音频/文件段落渲染与删除、发布按钮、
/// 按 `allow*` 开关控制可添加类型。
/// 待接入：媒体选择与上传（需 `pickupFile2Server` 等价的 Dio 上传）、拖拽排序、语音输入。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../theme/app_theme.dart';
import 'part_button_submit.dart';

const LangText _kPublish = LangText(zhCN: '发 表', enUS: 'Publish', jaJP: '送信');

const LangText _kAddText = LangText(zhCN: '文字', enUS: 'Text');

const LangText _kAddImage = LangText(zhCN: '图片', enUS: 'Image');

const LangText _kAddVideo = LangText(zhCN: '视频', enUS: 'Video');

const LangText _kAddAudio = LangText(zhCN: '语音', enUS: 'Audio');

const LangText _kAddFile = LangText(zhCN: '文件', enUS: 'File');

const LangText _kAddLink = LangText(zhCN: '链接', enUS: 'Link');

const LangText _kUploadPending = LangText(
  zhCN: '媒体上传待接入（阶段四）',
  enUS: 'Media upload is not wired up yet (Phase 4)',
);

class PartStoryEditor extends ConsumerStatefulWidget {
  const PartStoryEditor({
    super.key,
    required this.story,
    required this.onStoryChanged,
    this.allowText = true,
    this.allowSpeak = false,
    this.allowImage = false,
    this.allowVideo = false,
    this.allowAudio = false,
    this.allowFile = false,
    this.allowLink = false,
    this.minSections = 1,
    this.maxSections,
    this.textPlaceholder,
    this.storyTitle,
    this.publishing = false,
    this.onPublish,
    this.busy = false,
  });

  /// 段落数组（受控）。
  final List<Map<String, dynamic>> story;
  final ValueChanged<List<Map<String, dynamic>>> onStoryChanged;

  final bool allowText;
  final bool allowSpeak;
  final bool allowImage;
  final bool allowVideo;
  final bool allowAudio;
  final bool allowFile;
  final bool allowLink;

  final int minSections;
  final int? maxSections;
  final LangText? textPlaceholder;
  final LangText? storyTitle;
  final bool publishing;
  final VoidCallback? onPublish;
  final bool busy;

  @override
  ConsumerState<PartStoryEditor> createState() => _PartStoryEditorState();
}

class _PartStoryEditorState extends ConsumerState<PartStoryEditor> {
  final List<TextEditingController> _controllers = <TextEditingController>[];

  /// 保证段落数变化时控制器数量同步。
  void _syncControllers() {
    while (_controllers.length < widget.story.length) {
      final int index = _controllers.length;
      final Object? text = widget.story[index]['text'];
      _controllers.add(TextEditingController(text: text?.toString() ?? ''));
    }
    while (_controllers.length > widget.story.length) {
      _controllers.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _notify(List<Map<String, dynamic>> next) => widget.onStoryChanged(next);

  void _addSection(String key, {String initial = ''}) {
    if (widget.maxSections != null && widget.story.length >= widget.maxSections!) {
      return;
    }
    _notify(<Map<String, dynamic>>[
      ...widget.story,
      <String, dynamic>{key: initial},
    ]);
  }

  void _deleteSection(int index) {
    if (widget.story.length <= widget.minSections) return;
    _notify(<Map<String, dynamic>>[
      ...widget.story.take(index),
      ...widget.story.skip(index + 1),
    ]);
    setState(() {});
  }

  void _updateText(int index, String value) {
    final List<Map<String, dynamic>> next = widget.story
        .map((Map<String, dynamic> section) => Map<String, dynamic>.from(section))
        .toList();
    next[index]['text'] = value;
    _notify(next);
  }

  @override
  Widget build(BuildContext context) {
    _syncControllers();
    final String lang = ref.watch(languageProvider);

    return Container(
      decoration: BoxDecoration(
        color: PexColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.storyTitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                ll(lang, widget.storyTitle!),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          for (int i = 0; i < widget.story.length; i++)
            _buildSection(lang, i, widget.story[i]),
          const SizedBox(height: 6),
          _buildToolbar(lang),
        ],
      ),
    );
  }

  Widget _buildSection(String lang, int index, Map<String, dynamic> section) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        children: <Widget>[
          _buildSectionBody(lang, index, section),
          if (widget.story.length > widget.minSections)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                iconSize: 20,
                onPressed: () => _deleteSection(index),
                icon: const Icon(Icons.cancel, color: Color(0xFF909399)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionBody(String lang, int index, Map<String, dynamic> section) {
    if (section.containsKey('text')) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: TextField(
          controller: _controllers[index],
          maxLines: null,
          minLines: 1,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: widget.textPlaceholder == null
                ? null
                : ll(lang, widget.textPlaceholder!),
            hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
          ),
          onChanged: (String value) => _updateText(index, value),
        ),
      );
    }
    if (section['image'] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: ServerImage(
          section['image']?.toString(),
          fit: BoxFit.fitWidth,
          width: double.infinity,
        ),
      );
    }
    if (section['video'] != null) {
      return _pendingBlock(lang, 'uniui-videocam', section['video'].toString());
    }
    if (section['audio'] != null) {
      return _pendingBlock(lang, 'uniui-sound', section['audio'].toString());
    }
    if (section['file'] != null) {
      final Map<String, dynamic> file = (section['file'] as Map).cast<String, dynamic>();
      return _pendingBlock(
        lang,
        'icont-file-line',
        file['originalname']?.toString() ?? file['cid'].toString(),
        subtitle: file['size'] == null ? null : segmentNumber(file['size']),
      );
    }
    if (section['link'] != null || section['linkTarget'] != null) {
      return _pendingBlock(
        lang,
        'icont-hyperlink',
        (section['linkTarget'] ?? section['link']).toString(),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _pendingBlock(String lang, String icon, String title, {String? subtitle}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: PexColors.border),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
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
                Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF2979FF))),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF909399)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(String lang) {
    final List<Widget> adders = <Widget>[
      if (widget.allowText)
        _addButton(PexIcons.uni('compose'), _kAddText, () => _addSection('text')),
      if (widget.allowImage)
        _addButton(PexIcons.uni('camera'), _kAddImage, () => _pendingUpload()),
      if (widget.allowVideo)
        _addButton(PexIcons.uni('videocam'), _kAddVideo, () => _pendingUpload()),
      if (widget.allowAudio)
        _addButton(PexIcons.uni('sound'), _kAddAudio, () => _pendingUpload()),
      if (widget.allowFile)
        _addButton(PexIcons.icont('icont-file-line'), _kAddFile, () => _pendingUpload()),
      if (widget.allowLink)
        _addButton(PexIcons.icont('icont-hyperlink'), _kAddLink, () => _addSection('link')),
    ];

    return Row(
      children: <Widget>[
        Expanded(
          child: Wrap(spacing: 6, children: adders),
        ),
        if (widget.onPublish != null)
          PartButtonSubmit(
            disabled: widget.busy,
            loading: widget.publishing,
            fullWidth: false,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            onPressed: widget.onPublish,
            children: <Widget>[
              Text(ll(lang, _kPublish), style: const TextStyle(fontSize: 14)),
            ],
          ),
      ],
    );
  }

  Widget _addButton(dynamic glyph, LangText label, VoidCallback onTap) {
    return Tooltip(
      message: label.resolve(ref.read(languageProvider)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: PexIcon(glyph, size: 22, color: PexColors.grey6),
        ),
      ),
    );
  }

  void _pendingUpload() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_kUploadPending.resolve(ref.read(languageProvider))),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
