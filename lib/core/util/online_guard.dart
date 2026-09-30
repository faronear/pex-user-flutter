/// 登录守卫，对应源项目 `wo.tt.check_online()`。
///
/// 未登录时弹窗引导跳转 `identBegin`；返回是否已在线。
/// 注意：源项目还会记录 `wo.ss.routeAfterLogin` 以便登录后回到原页，
/// 该机制尚未迁移（当前由返回键回到原页）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../i18n/phrases.dart';
import '../router/app_router.dart';
import '../state/envar_provider.dart';
import 'feedback.dart';

Future<bool> checkOnline(
  BuildContext context,
  WidgetRef ref, {
  bool showCancel = true,
}) async {
  if (ref.read(isOnlineProvider)) return true;
  final bool confirmed = await showPexModal(
    context,
    ref,
    title: Phrases.loginToContinue,
    confirmText: Phrases.signupOrLogin,
    showCancel: showCancel,
  );
  if (confirmed && context.mounted) {
    context.push(AppRoutes.path(AppRoutes.identBegin));
  }
  return false;
}
