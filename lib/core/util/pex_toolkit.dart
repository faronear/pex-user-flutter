/// 通用工具函数，对应源项目 `wo.tt`（wo-core-toolkit / wo-core-i18n）的常用部分。
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../i18n/lands.dart';

/// 稳定哈希：SHA-256(utf8) → hex。
///
/// 对应源项目 `wo.tt.hash_stable(data)`（默认 hasher=sha256 / input=utf8 / output=hex）。
/// **必须与源项目逐位一致**，否则存量用户的 `passwordClient` 无法校验通过。
String hashStable(String data) => sha256.convert(utf8.encode(data)).toString();

/// 邮箱校验（对应 `wo.tt.validate_email`）。
bool validateEmail(String email, {String? format}) {
  if (format != null && format.isNotEmpty) {
    try {
      return RegExp(format).hasMatch(email);
    } catch (_) {
      // 忽略非法自定义格式，走默认校验
    }
  }
  final RegExp regex = RegExp(
    r'''^((?:[A-Za-z0-9!#$%&'*+\-/=?^_`{|}~]|(?<=^|\.)"|"(?=$|\.|@)|(?<=".*)[ .](?=.*")|(?<!\.)\.){1,64})(@)((?:[A-Za-z0-9.\-])*(?:[A-Za-z0-9])\.(?:[A-Za-z0-9]){2,})$''',
  );
  return regex.hasMatch(email);
}

/// 手机号校验（对应 `wo.tt.validate_phone`）。
///
/// 期望格式 `+<区号>-<号码>`（如 `+86-13800138000`）。
bool validatePhone(String phone, {String? format}) {
  if (format != null && format.isNotEmpty) {
    try {
      return RegExp(format).hasMatch(phone);
    } catch (_) {
      // 忽略非法自定义格式
    }
  }
  final RegExpMatch? match = RegExp(r'^\+(\d{1,4})-(\d{7,12})$').firstMatch(phone);
  if (match == null) return false;
  final String itc = match.group(1)!;
  final String callnumber = match.group(2)!;
  for (final LandItem land in kLands) {
    if (land.itc != itc) continue;
    final String? regex = land.phoneRegex;
    if (regex != null && regex.isNotEmpty) {
      try {
        return RegExp(regex).hasMatch(callnumber);
      } catch (_) {
        return false;
      }
    }
    final int minLen = land.phoneMinlen ?? 7;
    final int maxLen = land.phoneMaxlen ?? 12;
    return callnumber.length > minLen && callnumber.length < maxLen;
  }
  return false;
}

/// 数字精度裁剪（对应 `wo.tt.number_precision`）：非有限数返回 0。
num numberPrecision(Object? number, [int precision = 4]) {
  final num? value = number is num ? number : num.tryParse(number?.toString() ?? '');
  if (value == null || !value.isFinite) return 0;
  return num.parse(value.toStringAsFixed(precision));
}

/// 判定字符串是否“空”（对应 `wo.tt.is_empty`）。
bool isEmptyValue(Object? value) {
  if (value == null) return true;
  if (value is String) return value.trim().isEmpty;
  if (value is num) return false;
  if (value is Iterable) return value.isEmpty;
  if (value is Map) return value.isEmpty;
  return false;
}
