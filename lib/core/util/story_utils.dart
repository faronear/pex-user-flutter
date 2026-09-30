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

/// 取文件扩展名（不含点，小写）。
String fileExtOf(String filename) {
  final int index = filename.lastIndexOf('.');
  if (index <= 0 || index == filename.length - 1) return '';
  return filename.substring(index + 1).toLowerCase();
}
