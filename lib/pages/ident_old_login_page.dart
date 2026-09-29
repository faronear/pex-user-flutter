/// 老用户密码登录，对应源项目 `pages/identOldLogin.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/router/app_router.dart';
import '../core/state/app_providers.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/ident_provider.dart';
import '../core/util/pex_toolkit.dart';
import '../widgets/part_button_submit.dart';
import '../widgets/part_feedback.dart';
import '../widgets/part_ident_commid.dart';
import '../widgets/part_ident_input.dart';
import '../widgets/part_window_layout_ident.dart';

const LangText _kPasswordPlaceholder = LangText(
  zhCN: '请输入您的密码',
  enUS: 'Enter your password',
  jaJP: 'パスワードを入力してください',
);

const LangText _kLogin = LangText(zhCN: '登 录', enUS: 'Submit', jaJP: 'ログイン');

const LangText _kResetPassword = LangText(
  zhCN: '重设密码',
  enUS: 'Reset password',
  deDE: 'Passwort zurücksetzen',
  jaJP: 'パスワードをリセットする',
);

const LangText _kWrongPassword = LangText(
  zhCN: '密码错误，请重新输入',
  enUS: 'Password unmatched',
  jaJP: 'パスワードが一致しません',
);

const LangText _kUserNotExist = LangText(
  zhCN: '该用户不存在',
  enUS: 'User not exist',
  jaJP: 'ユーザーが存在しません',
);

const LangText _kLoginFailed = LangText(
  zhCN: '登录失败',
  enUS: 'Login failed',
  jaJP: 'ログインに失敗しました',
);

const LangText _kServerError = LangText(
  zhCN: '后台错误',
  enUS: 'Server response error',
  jaJP: 'サーバーレスポンスエラー',
);

/// PC 二级导航栏标题（源项目页面 `data.i18nPageTitle`）。
const LangText _kNavTitle = LangText(
  zhCN: '登录',
  enUS: 'Login',
  jaJP: 'ログイン',
);

class IdentOldLoginPage extends ConsumerStatefulWidget {
  const IdentOldLoginPage({super.key});

  @override
  ConsumerState<IdentOldLoginPage> createState() => _IdentOldLoginPageState();
}

class _IdentOldLoginPageState extends ConsumerState<IdentOldLoginPage> {
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  LangText? _feedback;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _feedback = null;
      _loading = true;
    });

    final IdentState ident = ref.read(identProvider);
    final Map<String, dynamic> data = await ref.read(apiClientProvider).callBase(
          apiWho: 'User',
          apiTodo: 'login_user',
          apiWhat: <String, dynamic>{
            'commid': ident.commid,
            'passwordClient': hashStable(_password.text + ident.usid),
          },
        );
    if (!mounted) return;
    setState(() => _loading = false);

    final String state = data['_state']?.toString() ?? '';
    if (bok(state)) {
      final Map<String, dynamic> onlineUser =
          (data['onlineUser'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      ref.read(appStartupProvider.notifier).setOnlineUser(onlineUser);
      if (onlineUser['lang'] != null) {
        ref.read(languageProvider.notifier).set(onlineUser['lang'].toString());
      }
      if (mounted) {
        context.go(AppRoutes.path(ref.read(brandProvider).appLandPage));
      }
    } else if (state == 'LOGIN_FAILED_WRONG_PASSWORD') {
      setState(() => _feedback = _kWrongPassword);
    } else if (state == 'LOGIN_FAILED_USER_NOTEXIST') {
      setState(() => _feedback = _kUserNotExist);
    } else if (state == 'LOGIN_FAILED') {
      setState(() => _feedback = _kLoginFailed);
    } else {
      setState(() {
        _feedback = data['_msg'] == null
            ? _kServerError
            : LangText.fromMap(data['_msg']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final IdentState ident = ref.watch(identProvider);

    return PartWindowLayoutIdent(
      pageName: AppRoutes.identOldLogin,
      navTitle: _kNavTitle,
      child: Column(
        children: <Widget>[
          const PartIdentCommid(),
          PartIdentInput(
            controller: _password,
            placeholder: _kPasswordPlaceholder,
            obscure: true,
            enabled: !_loading,
            onChanged: (_) => setState(() {}),
            onSubmitted: _login,
          ),
          const PartFeedback(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: PartButtonSubmit(
              disabled: _loading || _password.text.isEmpty || ident.commid.isEmpty,
              loading: _loading,
              onPressed: _login,
              children: <Widget>[
                if (!_loading)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PexIcon.uni('auth', size: 22, color: Colors.white),
                  ),
                Text(ll(lang, _kLogin)),
              ],
            ),
          ),
          PartFeedback(bad: _feedback),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(AppRoutes.path(AppRoutes.identOldPasscode)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    ll(lang, _kResetPassword),
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF2979FF),
                      fontSize: 14,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: PexIcon.uni('right', size: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
