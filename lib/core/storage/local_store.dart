/// 本地键值存储封装，替代源项目的 `uni.getStorageSync / setStorageSync`。
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  /// 源项目使用过的存储键（保持一致，便于对照）。
  static const String keyPasstoken = '_passtoken';
  static const String keyMylang = 'mylang';
  static const String keyUserlandCode = 'userlandCode';

  /// 用户在「我的设置」里选定的法币 / 加密币代码。
  ///
  /// 源项目只改内存、不落地（`umyConfig` 里写着「todo: 通知后台修改」），
  /// 刷新即丢；迁移版**存本地**，这是老板 2026-09-30 确认的有意改进。
  static const String keyBankcoinCode = 'bankcoinCode';
  static const String keyCryptocoinCode = 'cryptocoinCode';

  /// 上一次成功拉取的 `first_touch.envarBase`（JSON 字符串）。
  /// 断线时用它兜底，使首屏仍显示**上次真实**的新闻/文案（方案 E 的轻量缓存层）。
  static const String keyEnvarCache = 'envarCache';

  static Future<LocalStore> open() async =>
      LocalStore(await SharedPreferences.getInstance());

  String getString(String key, [String fallback = '']) =>
      _prefs.getString(key) ?? fallback;

  int getInt(String key, [int fallback = 0]) => _prefs.getInt(key) ?? fallback;

  bool getBool(String key, [bool fallback = false]) =>
      _prefs.getBool(key) ?? fallback;

  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  /// `_passtoken`：自动登录凭据。
  String get passtoken => getString(keyPasstoken);

  Future<void> setPasstoken(String value) => setString(keyPasstoken, value);

  Future<void> clearPasstoken() => remove(keyPasstoken);

  /// 读取缓存的配置（无则返回空 Map）。
  Map<String, dynamic> get envarCache {
    final String raw = getString(keyEnvarCache);
    if (raw.isEmpty) return <String, dynamic>{};
    try {
      final Object? decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, dynamic>() : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> setEnvarCache(Map<String, dynamic> envar) =>
      setString(keyEnvarCache, jsonEncode(envar));
}
