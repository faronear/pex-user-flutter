/// 后端下发配置的类型化访问，对应源项目 `wo.ss` / `wo.envar` 的常用字段。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/lang_text.dart';
import 'app_startup_notifier.dart';

class Envar {
  const Envar(this.raw);

  final Map<String, dynamic> raw;

  static const Envar empty = Envar(<String, dynamic>{});

  String str(String key, [String fallback = '']) =>
      raw[key]?.toString() ?? fallback;

  int intOf(String key, [int fallback = 0]) {
    final Object? value = raw[key];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  bool boolOf(String key, [bool fallback = false]) {
    final Object? value = raw[key];
    if (value is bool) return value;
    return fallback;
  }

  /// 应用内币种符号（如 `¢`）。
  String get tucSymbol => str('tucSymbol');

  /// 注册奖励金（币数）。
  int get registerReward => intOf('registerReward');

  /// 邀请奖励金（币数）。
  int get inviteeReward => intOf('inviteeReward');

  /// 验证码发送间隔秒数（源项目生产 60 / 开发 5）。
  int get waitingSeconds {
    final int value = intOf('waitingSeconds');
    return value > 0 ? value : 60;
  }

  /// 应用称谓（如「爱奇点」/「Agidin」）。
  LangText get callnames => LangText.fromMap(raw['callnames']);

  String get linkAgreement => str('linkAgreement');

  String get linkNews => str('linkNews');

  String get linkSlogan => str('linkSlogan');

  /// 短信服务类型（源项目 `baseTypeSms`）。
  String get baseTypeSms => str('baseTypeSms', 'SERVER');

  /// 后端服务地址（源项目 `servUrl`）。
  String get servUrl => str('servUrl');

  Map<String, dynamic> get linkTree =>
      (raw['linkTree'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

  /// 取 linkTree 分组下的子项，如 `subtag('apps', 'ios')`。
  Map<String, dynamic>? subtag(String group, String key) {
    final Object? groupValue = linkTree[group];
    if (groupValue is! Map) return null;
    final Object? subtags = groupValue['subtags'];
    if (subtags is! Map) return null;
    final Object? item = subtags[key];
    return item is Map ? item.cast<String, dynamic>() : null;
  }

  /// 某分组下全部子项。
  Map<String, dynamic> subtags(String group) {
    final Object? groupValue = linkTree[group];
    if (groupValue is! Map) return <String, dynamic>{};
    final Object? subtags = groupValue['subtags'];
    return subtags is Map ? subtags.cast<String, dynamic>() : <String, dynamic>{};
  }
}

/// 当前后端配置。
final Provider<Envar> envarProvider =
    Provider<Envar>((ref) => Envar(ref.watch(appStartupProvider).envar));

/// 当前登录用户（源项目 `wo.ss.User.onlineUser`）。
final Provider<Map<String, dynamic>> onlineUserProvider =
    Provider<Map<String, dynamic>>((ref) => ref.watch(appStartupProvider).onlineUser);

/// 是否已登录。
final Provider<bool> isOnlineProvider = Provider<bool>(
  (ref) => (ref.watch(onlineUserProvider)['usid']?.toString() ?? '').isNotEmpty,
);
