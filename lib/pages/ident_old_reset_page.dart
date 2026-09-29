/// 重设密码，对应源项目 `pages/identOldReset.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/router/app_router.dart';
import '../core/state/app_providers.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/ident_provider.dart';
import '../core/util/feedback.dart';
import '../core/util/pex_toolkit.dart';
import '../widgets/part_countdown.dart';
import '../widgets/part_ident_commid.dart';
import '../widgets/part_password_form.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_window_layout_ident.dart';

const LangText _kNewPassword = LangText(
  zhCN: '请重设您的密码',
  enUS: 'Reset your password please',
  jaJP: 'パスワードをリセットしてください',
);

const LangText _kPasswordAgain = LangText(
  zhCN: '请再次输入您的密码',
  enUS: 'Enter your password again',
  jaJP: 'パスワードをもう一度入力してください',
);

const LangText _kReset = LangText(zhCN: '重置密码', enUS: 'Reset', jaJP: 'リセット');

const LangText _kResetDone = LangText(
  zhCN: '您的密码已重置成功',
  enUS: 'Your password is reset',
  jaJP: 'パスワードがリセットされました',
);

const LangText _kResetDoneHint = LangText(
  zhCN: '从现在开始，请使用新密码登录！',
  enUS: 'From now on, please Login with your new password!',
  jaJP: 'これからは新しいパスワードでログインしてください！',
);

const LangText _kLogin = LangText(zhCN: '登录', enUS: 'Login', jaJP: 'ログイン');

/// PC 二级导航栏标题（源项目页面 `data.i18nPageTitle`）。
const LangText _kNavTitle = LangText(
  zhCN: '重设密码',
  enUS: 'Reset Password',
  jaJP: 'パスワードのリセット',
);

class IdentOldResetPage extends ConsumerWidget {
  const IdentOldResetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final IdentState ident = ref.watch(identProvider);

    return PartWindowLayoutIdent(
      pageName: AppRoutes.identOldReset,
      navTitle: _kNavTitle,
      child: Column(
        children: <Widget>[
          const PartIdentCommid(),
          PartPasswordForm(
            placeholder1: _kNewPassword,
            placeholder2: _kPasswordAgain,
            submitText: _kReset,
            enabled: ident.commid.isNotEmpty,
            onSubmit: (String password) async {
              final IdentState now = ref.read(identProvider);
              if (now.verifyExpired) {
                if (context.mounted) {
                  await showPexModal(
                    context,
                    ref,
                    title: PartTexts.passcodeExpired,
                    content: PartTexts.passcodeExpiredPlease,
                    showCancel: false,
                  );
                }
                return null;
              }

              final Map<String, dynamic> data =
                  await ref.read(apiClientProvider).callBase(
                        apiWho: 'User',
                        apiTodo: 'reset_password',
                        apiWhat: <String, dynamic>{
                          'commid': now.commid,
                          'passwordClient': hashStable(password + now.usid),
                        },
                      );

              if (!bok(data['_state']?.toString())) {
                return data['_msg'] == null
                    ? PartTexts.systemDown
                    : LangText.fromMap(data['_msg']);
              }

              final Map<String, dynamic> onlineUser =
                  (data['onlineUser'] as Map?)?.cast<String, dynamic>() ??
                      <String, dynamic>{};
              ref.read(appStartupProvider.notifier).setOnlineUser(onlineUser);
              if (onlineUser['lang'] != null) {
                ref.read(languageProvider.notifier).set(onlineUser['lang'].toString());
              }
              if (context.mounted) {
                await showPexModal(
                  context,
                  ref,
                  title: _kResetDone,
                  content: _kResetDoneHint,
                  confirmText: _kLogin,
                  showCancel: false,
                );
                if (context.mounted) {
                  context.go(AppRoutes.path(ref.read(brandProvider).appLandPage));
                }
              }
              return null;
            },
          ),
          PartCountdown(expireAt: ident.verifyExpireAt),
        ],
      ),
    );
  }
}
