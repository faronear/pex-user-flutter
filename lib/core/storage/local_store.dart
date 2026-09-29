/// 本地键值存储封装，替代源项目的 `uni.getStorageSync / setStorageSync`。
library;

import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  /// 源项目使用过的存储键（保持一致，便于对照）。
  static const String keyPasstoken = '_passtoken';
  static const String keyMylang = 'mylang';
  static const String keyUserlandCode = 'userlandCode';

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
}
