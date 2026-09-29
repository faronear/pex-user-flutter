/// 媒体选择器：跨端（Web / 原生）统一返回「文件名 + 字节」。
///
/// 对应源项目 `uni.chooseImage / chooseVideo / chooseFile` 系列；
/// 统一取 bytes 是为了让上传逻辑在 Web 与原生共用一套代码。
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class PickedMedia {
  const PickedMedia({
    required this.filename,
    required this.bytes,
  });

  final String filename;
  final Uint8List bytes;

  int get size => bytes.length;
}

/// 选择媒体文件。[mediaType] 取 `image` / `video` / `audio` / `file`。
/// 返回 null 表示用户取消（或该平台无法提供字节流）。
Future<PickedMedia?> pickMedia({
  required String mediaType,
  List<String>? allowedExtensions,
}) async {
  switch (mediaType) {
    case 'image':
      final XFile? image =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return null;
      return PickedMedia(filename: image.name, bytes: await image.readAsBytes());
    case 'video':
      final XFile? video =
          await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (video == null) return null;
      return PickedMedia(filename: video.name, bytes: await video.readAsBytes());
    default:
      final List<String>? extensions =
          allowedExtensions == null || allowedExtensions.isEmpty
              ? null
              : allowedExtensions
                  .map((String e) => e.replaceFirst(RegExp(r'^\.'), ''))
                  .toList();
      final PlatformFile? file = await FilePicker.pickFile(
        type: extensions == null ? FileType.any : FileType.custom,
        allowedExtensions: extensions,
      );
      if (file == null) return null;
      // file_picker 13 用 readAsBytes()（跨端可用），不再暴露 bytes 字段。
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      return PickedMedia(filename: file.name, bytes: bytes);
  }
}
