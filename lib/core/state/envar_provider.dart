/// 后端下发配置的类型化访问，对应源项目 `wo.ss` / `wo.envar` 的常用字段。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/lang_text.dart';
import 'app_startup_notifier.dart';
import 'app_providers.dart';
import 'client_envar.dart';

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

  /// 邀请/分享链接所用的固定主域名（源项目 `webUrlRoot`）。
  ///
  /// 源项目注释：设为固定的主域名，是为了方便从后台控制。
  String get webUrlRoot => str('webUrlRoot');

  /// 邀请页大标题（源项目 `tInviteTitle`）；未配置时页面回退到 [slogans]。
  LangText get tInviteTitle => LangText.fromMap(raw['tInviteTitle']);

  /// 社区优惠计划链接（源项目 `linkCommunity`）；为空则不显示该入口。
  String get linkCommunity => str('linkCommunity');

  /// 品牌标语（源项目 `slogans`）。
  LangText get slogans => LangText.fromMap(raw['slogans']);

  /// 屏蔽确认弹窗的标题与正文（源项目 `tBlockTitle` / `tBlock`；未配置时页面用内置文案）。
  LangText get tBlockTitle => LangText.fromMap(raw['tBlockTitle']);

  LangText get tBlock => LangText.fromMap(raw['tBlock']);

  LangText get tUnblockTitle => LangText.fromMap(raw['tUnblockTitle']);

  LangText get tUnblock => LangText.fromMap(raw['tUnblock']);

  /// 「我的圈子」三个分类（源项目 `Creator.myCircleDict`）：`FOLLOWING` / `FOLLOWER` / `INVITEE`。
  Map<String, dynamic> get myCircleDict {
    final Object? creator = raw['Creator'];
    if (creator is! Map) return <String, dynamic>{};
    final Object? dict = creator['myCircleDict'];
    return dict is Map ? dict.cast<String, dynamic>() : <String, dynamic>{};
  }

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

  /// 分组节点本身（含 `iName` / `hiddenGroup` / `subtags`）。
  Map<String, dynamic> linkGroup(String group) {
    final Object? value = linkTree[group];
    return value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
  }

  /// 分组是否被后台隐藏（源项目 `hiddenGroup`）。
  bool isLinkGroupHidden(String group) => _isTrue(linkGroup(group)['hiddenGroup']);

  static bool _isTrue(Object? value) =>
      value == true || value?.toString() == 'true';
}

/// 当前生效配置：**本地预置层 → 后端下发层覆盖**（方案 E）。
///
/// 预置层提供「服务端永不下发的客户端专属块」与「首屏默认值」；
/// 后端层兑现「后台随时改文案/设置」——它一旦开始下发某个块，就会自动覆盖预置值。
final Provider<Envar> envarProvider = Provider<Envar>((ref) {
  final Map<String, dynamic> preset = ref.watch(clientEnvarPresetProvider);
  // 缓存层：上次成功拉取的配置。断线时让首屏仍显示**上次真实**的新闻/文案。
  final Map<String, dynamic> cached = ref.watch(localStoreProvider).envarCache;
  final Map<String, dynamic> server = ref.watch(appStartupProvider).envar;
  return Envar(<String, dynamic>{...preset, ...cached, ...server});
});

/// 当前登录用户（源项目 `wo.ss.User.onlineUser`）。
final Provider<Map<String, dynamic>> onlineUserProvider =
    Provider<Map<String, dynamic>>((ref) => ref.watch(appStartupProvider).onlineUser);

/// 是否已登录。
final Provider<bool> isOnlineProvider = Provider<bool>(
  (ref) => (ref.watch(onlineUserProvider)['usid']?.toString() ?? '').isNotEmpty,
);
