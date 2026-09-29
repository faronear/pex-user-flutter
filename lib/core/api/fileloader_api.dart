/// 文件上传接口，对应源项目 `wo.tt.pickupFile2Server`（`api/Fileloader/receiveFile`）。
///
/// 契约：`POST {servUrl}/api/Fileloader/receiveFile`，multipart/form-data，
/// 文件字段名 `file`，另附 `_passtoken` 与 `filenameOriginal`；
/// 响应 `{ _state: 'SUCCESS', path, destination, filename, cid?, ipfsUrl?, baseUrl?, ... }`。
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/lang_text.dart';
import '../state/app_providers.dart';
import '../state/envar_provider.dart';
import '../storage/local_store.dart';
import '../util/file_utils.dart';
import '../util/server_url.dart';

/// 上传结果。
class FileUploadResult {
  const FileUploadResult({
    required this.state,
    this.message,
    this.fileInfo = const <String, dynamic>{},
  });

  final String state;
  final LangText? message;

  /// `{ path, cid, ipfsUrl, originalname, size, ... }`
  final Map<String, dynamic> fileInfo;

  bool get ok => state == 'SUCCESS';

  /// 用户取消选择（源项目 `CER_FAIL_CHOOSE`），调用方应静默处理。
  bool get cancelled => state == 'CER_FAIL_CHOOSE';

  String get originalname => fileInfo['originalname']?.toString() ?? '';

  String get fileUrl => fileInfo['fileUrl']?.toString() ?? '';
}

const LangText _kEmptyFile = LangText(
  zhCN: '文件为空，无法上传。',
  enUS: 'Empty files cannot be uploaded.',
);

const LangText _kFailUpload = LangText(
  zhCN: '文件上传失败。请稍后再试，或向客服报告。',
  enUS: 'File upload failed. Please try again, or report to customer service.',
);

const LangText _kBadResponse = LangText(
  zhCN: '文件上传失败。请稍后再试，或向客服报告。',
  enUS: 'File upload failed. Please try again, or report to customer service.',
);

class FileloaderApi {
  FileloaderApi({
    required this.baseUrl,
    required this.store,
    required this.envar,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(minutes: 5),
            receiveTimeout: const Duration(minutes: 5),
            validateStatus: (_) => true,
          ),
        );

  final String baseUrl;
  final LocalStore store;
  final Envar envar;
  final Dio _dio;

  /// 上传文件（跨端统一走 bytes，Web 与原生皆可用）。
  Future<FileUploadResult> uploadFile({
    required String filename,
    required List<int> bytes,
  }) async {
    if (bytes.isEmpty) {
      return const FileUploadResult(state: 'CER_EMPTY_FILE', message: _kEmptyFile);
    }

    final FormData form = FormData.fromMap(<String, dynamic>{
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      '_passtoken': store.passtoken,
      // 源项目为解决 multer 拿到随机文件名的问题，主动回传原始文件名。
      'filenameOriginal': filename,
    });

    Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        '/api/Fileloader/receiveFile',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (error) {
      return FileUploadResult(
        state: 'BER_FAIL_UPLOAD_FILE',
        message: _kFailUpload,
        fileInfo: <String, dynamic>{'error': error.message},
      );
    }

    dynamic body = response.data;
    if (body is String) {
      try {
        body = jsonDecode(body);
      } catch (_) {
        return const FileUploadResult(
          state: 'BER_FAIL_RESPONSE_JSON_MALFORMED',
          message: _kBadResponse,
        );
      }
    }
    if (body is! Map) {
      return const FileUploadResult(
        state: 'BER_FAIL_RESPONSE_JSON_MALFORMED',
        message: _kBadResponse,
      );
    }

    final Map<String, dynamic> data =
        body.map((dynamic key, dynamic value) => MapEntry(key.toString(), value));
    if (data['_state']?.toString() == 'SUCCESS' && data['path'] != null) {
      final Map<String, dynamic> info = Map<String, dynamic>.from(data)
        ..['fileUrl'] = makeServerUrl(data['path'].toString(), envar);
      return FileUploadResult(state: 'SUCCESS', fileInfo: info);
    }
    return FileUploadResult(
      state: 'BER_FAIL_UPLOAD_FILE',
      message: data['_msg'] == null ? _kFailUpload : LangText.fromMap(data['_msg']),
      fileInfo: data,
    );
  }

  /// 客户端侧校验（对齐源项目 `pickupFile2Server` 的检查顺序）。
  LangText? validate({
    required String filename,
    required int size,
    String? mediaType,
    List<String>? allowedExtensions,
  }) {
    if (size <= 0) return _kEmptyFile;

    final int limit = fileSizeLimit(envar);
    if (size > limit) {
      final String limitText = '${(limit / 1048576).floor()}MB';
      return LangText(
        zhCN: '文件大于 $limitText，无法上传',
        enUS: 'The file exceeds $limitText and cannot be uploaded',
      );
    }

    if (mediaType == 'image' || mediaType == 'video' || mediaType == 'audio') {
      final bool ok = switch (mediaType) {
        'image' => isImageFile(envar, filename),
        'video' => isVideoFile(envar, filename),
        _ => isAudioFile(envar, filename),
      };
      if (!ok) {
        return LangText(
          zhCN: '不支持的文件类型：\n$filename',
          enUS: 'Unsupported file type:\n$filename',
        );
      }
    } else if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      if (!matchesExtensionList(allowedExtensions, filename)) {
        return LangText(
          zhCN: '不支持的文件类型：\n$filename',
          enUS: 'Unsupported file type:\n$filename',
        );
      }
    }
    return null;
  }
}

final Provider<FileloaderApi> fileloaderApiProvider = Provider<FileloaderApi>((ref) {
  return FileloaderApi(
    baseUrl: ref.watch(apiBaseUrlProvider),
    store: ref.watch(localStoreProvider),
    envar: ref.watch(envarProvider),
  );
});
