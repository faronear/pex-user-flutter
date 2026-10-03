/// story（内容容器）相关的取用工具，对应源项目 `wo.tt.filter_story_*` / `is_autocontent` / `read_varchain`。
library;

import 'pex_toolkit.dart';

/// 段落是否有实质内容（对应 `wo.tt.is_filled_section`）：
/// 任一「非下划线开头」的键有非空值即为有内容。
bool isFilledSection(Map<String, dynamic> section) => section.entries.any(
      (MapEntry<String, dynamic> entry) =>
          !entry.key.startsWith('_') && !isEmptyValue(entry.value),
    );

/// story 是否为空（对应 `wo.tt.is_empty_story`）。
bool isEmptyStory(List<dynamic>? story) {
  if (story == null || story.isEmpty) return true;
  return !story.any(
    (dynamic section) =>
        section is Map && isFilledSection(section.cast<String, dynamic>()),
  );
}

/// 去掉空段落（对应 `wo.tt.filter_story`）：例如 `{text: ''}` 会被删除。
/// 上传/提交前调用，避免把空段落写进后端。
List<dynamic> filterStory(List<dynamic>? story) {
  if (story == null) return <dynamic>[];
  return story
      .where(
        (dynamic section) =>
            section is Map && isFilledSection(section.cast<String, dynamic>()),
      )
      .toList();
}

/// 取 story 中第一个图片地址（对应 `wo.tt.filter_story_image`）。
String filterStoryImage(List<dynamic>? story) {
  if (story == null) return '';
  for (final dynamic raw in story) {
    if (raw is Map) {
      final String image = raw['image']?.toString() ?? '';
      if (image.isNotEmpty) return image;
    }
  }
  return '';
}

/// 取 story 中第一个视频地址（对应 `wo.tt.filter_story_video`）。
String filterStoryVideo(List<dynamic>? story) {
  if (story == null) return '';
  for (final dynamic raw in story) {
    if (raw is Map) {
      final String video = raw['video']?.toString() ?? '';
      if (video.isNotEmpty) return video;
    }
  }
  return '';
}

/// story 是否「没有真实内容」（对应 `wo.tt.is_autocontent`）：
/// 空数组，或所有段落都只有 `_autocontent` 而没有 text/image/video/audio/file/link。
bool isAutocontent(List<dynamic>? story) {
  if (story == null || story.isEmpty) return true;
  for (final dynamic raw in story) {
    if (raw is! Map) continue;
    final bool hasContent = (raw['text']?.toString() ?? '').isNotEmpty ||
        (raw['textIpfs']?.toString() ?? '').isNotEmpty ||
        raw['image'] != null ||
        raw['video'] != null ||
        raw['audio'] != null ||
        raw['file'] != null ||
        raw['link'] != null ||
        raw['linkTarget'] != null;
    if (hasContent) return false;
  }
  return true;
}

/// 按点分路径取嵌套值（对应 `wo.tt.read_varchain`），任一层缺失返回 [emptyValue]。
Object? readVarchain(String path, Object? root, [Object? emptyValue]) {
  Object? parent = root;
  for (final String key in path.split('.')) {
    if (parent == null) return emptyValue;
    if (parent is Map) {
      parent = parent[key];
    } else {
      return emptyValue;
    }
  }
  return parent ?? emptyValue;
}

/// 取 story 的文字摘要作为标题（对应 `wo.tt.extract_story_title`）：
/// 各段文字去换行后以空格拼接，最多 140 字。
///
/// 段落的 `text` 既可能是字符串，也可能是语言字典（`{zhCN: ..., enUS: ...}`）。
String extractStoryTitle(List<dynamic>? story, {String lang = 'enUS'}) {
  if (story == null || story.isEmpty) return '';
  final List<String> parts = <String>[];
  for (final dynamic raw in story) {
    if (raw is! Map) continue;
    final Object? text = raw['text'];
    final String value = switch (text) {
      final String it => it,
      final Map it => (it[lang] ?? it['enUS'])?.toString() ?? '',
      _ => '',
    };
    final String trimmed = value.trim().replaceAll(RegExp(r'\n+'), ' ');
    if (trimmed.isNotEmpty) parts.add(trimmed);
  }
  final String joined = parts.join(' ').trim();
  return joined.length <= 140 ? joined : joined.substring(0, 140);
}

/// 取文件扩展名（不含点，小写）。
String fileExtOf(String filename) {
  final int index = filename.lastIndexOf('.');
  if (index <= 0 || index == filename.length - 1) return '';
  return filename.substring(index + 1).toLowerCase();
}
