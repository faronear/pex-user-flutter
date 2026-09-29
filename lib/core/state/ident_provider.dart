/// 身份流程状态，对应源项目 `wo.ss.Ident`（登录/注册过程中的临时状态）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

class IdentState {
  const IdentState({
    this.commid = '',
    this.usid = '',
    this.inviterHaid = '',
    this.verifyExpireAt = 0,
  });

  /// 手机号（`+86-138...`）或邮箱。
  final String commid;

  /// 后端返回的用户编号（用于 `hash_stable(password + usid)`）。
  final String usid;

  /// 邀请码 / 优惠码。
  final String inviterHaid;

  /// 验证通过后的有效截止时间（毫秒时间戳）。
  final int verifyExpireAt;

  bool get verifyExpired =>
      verifyExpireAt > 0 && verifyExpireAt < DateTime.now().millisecondsSinceEpoch;

  IdentState copyWith({
    String? commid,
    String? usid,
    String? inviterHaid,
    int? verifyExpireAt,
  }) =>
      IdentState(
        commid: commid ?? this.commid,
        usid: usid ?? this.usid,
        inviterHaid: inviterHaid ?? this.inviterHaid,
        verifyExpireAt: verifyExpireAt ?? this.verifyExpireAt,
      );
}

class IdentNotifier extends Notifier<IdentState> {
  @override
  IdentState build() => const IdentState();

  void setCommid(String value) => state = state.copyWith(commid: value);

  void setUsid(String value) => state = state.copyWith(usid: value);

  void setInviterHaid(String value) => state = state.copyWith(inviterHaid: value);

  void setVerifyExpireAt(int value) =>
      state = state.copyWith(verifyExpireAt: value);

  void reset() => state = const IdentState();
}

final NotifierProvider<IdentNotifier, IdentState> identProvider =
    NotifierProvider<IdentNotifier, IdentState>(IdentNotifier.new);
