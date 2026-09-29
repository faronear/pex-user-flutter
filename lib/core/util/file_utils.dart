/// 文件相关工具，对应源项目 `wo.tt` 的 `is_*_file` / `get_file_ext` / `simplify_file` / `choose_url`。
library;

import '../state/envar_provider.dart';

/// 取文件扩展名（小写，不含点）；对应 `wo.tt.get_file_ext`。
String getFileExt(String filename) {
  final List<String> parts = filename.split('.');
  if (parts.length >= 2) return parts.last.toLowerCase();
  return '';
}

List<String> _extList(Envar envar, String key) {
  final Object? value = envar.raw[key];
  return value is List ? value.map((dynamic e) => e.toString()).toList() : <String>[];
}

bool _isFileOfKind(Envar envar, String key, String fileName) {
  final String ext = getFileExt(fileName);
  if (ext.isEmpty) return false;
  return _extList(envar, key).contains(ext);
}

bool isImageFile(Envar envar, String fileName) =>
    _isFileOfKind(envar, 'imageExtensionList', fileName);

bool isVideoFile(Envar envar, String fileName) =>
    _isFileOfKind(envar, 'videoExtensionList', fileName);

bool isAudioFile(Envar envar, String fileName) =>
    _isFileOfKind(envar, 'audioExtensionList', fileName);

/// 允许上传的最大字节数（默认 10MB，与源项目一致）。
int fileSizeLimit(Envar envar) {
  final Object? value = envar.raw['fileSizeLimit'];
  if (value is num) return value.toInt();
  return 10485760;
}

/// 去掉非必要字段（对应 `wo.tt.simplify_file`）。
Map<String, dynamic> simplifyFile(Map<String, dynamic> file) {
  final Map<String, dynamic> result = Map<String, dynamic>.from(file);
  for (final String key in <String>[
    'baseUrl',
    'fileUrl',
    'ipfsUrl',
    'fieldname',
    'filename',
    'destination',
  ]) {
    result.remove(key);
  }
  return result;
}

/// 选用哪个地址写入 story（对应源项目 `wo.tt.choose_url`）。
///
/// `prefer='url'`：`path → fileUrl → baseUrl → cid → ipfsUrl`；
/// 否则：`cid → ipfsUrl → path → fileUrl → baseUrl`。
String chooseUrl(Map<String, dynamic> file, {String prefer = ''}) {
  String pick(List<String> keys) {
    for (final String key in keys) {
      final String value = file[key]?.toString() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  if (prefer == 'url') {
    return pick(<String>['path', 'fileUrl', 'baseUrl', 'cid', 'ipfsUrl']);
  }
  return pick(<String>['cid', 'ipfsUrl', 'path', 'fileUrl', 'baseUrl']);
}

/// 判断给定扩展名列表是否允许该文件（对应 `mediaType` 为扩展名数组的情况）。
bool matchesExtensionList(List<String> allowed, String fileName) {
  final String ext = getFileExt(fileName);
  if (ext.isEmpty) return false;
  return allowed.map((String e) => e.toLowerCase()).contains('.$ext');
}
