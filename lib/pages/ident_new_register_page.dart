/// 新用户设置密码并注册，对应源项目 `pages/identNewRegister.vue`。
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
import '../core/state/envar_provider.dart';
import '../core/state/ident_provider.dart';
import '../core/util/feedback.dart';
import '../core/util/pex_toolkit.dart';
import '../widgets/part_countdown.dart';
import '../widgets/part_ident_commid.dart';
import '../widgets/part_password_form.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_window_layout_ident.dart';

const LangText _kPassword = LangText(
  zhCN: '设置您的密码',
  enUS: 'Enter your password',
  jaJP: 'パスワードを設定してください',
);

const LangText _kPasswordAgain = LangText(
  zhCN: '再次输入您的密码',
  enUS: 'Enter your password again',
  jaJP: 'パスワードをもう一度入力してください',
);

const LangText _kRegister = LangText(zhCN: '注 册', enUS: 'Register', jaJP: '登 録');

const LangText _kWelcome = LangText(zhCN: '欢迎加入 ', enUS: 'Welcome to ', jaJP: 'ようこそ ');

const LangText _kRewarded = LangText(
  zhCN: '您已获赠 ',
  enUS: 'You are rewarded ',
  jaJP: 'あなたに贈られた ',
);

const LangText _kStartJourney = LangText(
  zhCN: '开始我的旅程',
  enUS: 'Start My Journey',
  jaJP: '旅を始める',
);

/// PC 二级导航栏标题（源项目页面 `data.i18nPageTitle`）。
const LangText _kNavTitle = LangText(
  zhCN: '注册',
  enUS: 'Register',
  jaJP: '登録',
);

class IdentNewRegisterPage extends ConsumerWidget {
  const IdentNewRegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final IdentState ident = ref.watch(identProvider);
    final Envar envar = ref.watch(envarProvider);
    final String lang = ref.watch(languageProvider);

    return PartWindowLayoutIdent(
      pageName: AppRoutes.identNewRegister,
      navTitle: _kNavTitle,
      child: Column(
        children: <Widget>[
          const PartIdentCommid(),
          PartPasswordForm(
            placeholder1: _kPassword,
            placeholder2: _kPasswordAgain,
            submitText: _kRegister,
            showAgree: true,
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
                        apiTodo: 'register_new_user',
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

              ref
                  .read(appStartupProvider.notifier)
                  .setOnlineUser((data['onlineUser'] as Map?)?.cast<String, dynamic>() ??
                      <String, dynamic>{});
              final String balance =
                  (data['onlineUser'] as Map?)?['balanceTUC']?.toString() ?? '0';
              if (context.mounted) {
                await showPexModal(
                  context,
                  ref,
                  title: LangText.from(
                    '${ll(lang, _kWelcome)}${ll(lang, envar.callnames)}！',
                  ),
                  content: LangText.from(
                    '${ll(lang, _kRewarded)}$balance${envar.tucSymbol}',
                  ),
                  confirmText: _kStartJourney,
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
