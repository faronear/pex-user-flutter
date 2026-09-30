/// 修改密码，对应源项目 `pages/umyAccountPassword.vue`：
/// 原密码 + 新密码 + 确认新密码 → `User/changePassword`（两个密码都按 `hash(密码+usid)` 提交）。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/api/user_api.dart';
import '../core/appmeta/page_meta.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_router.dart';
import '../core/state/envar_provider.dart';
import '../core/util/feedback.dart';
import '../core/util/pex_toolkit.dart';
import '../widgets/part_button_submit.dart';
import '../widgets/part_feedback.dart';
import '../widgets/part_ident_input.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_window_layout.dart';

const LangText _kOldPassword = LangText(zhCN: '原密码', enUS: 'Old Password');

const LangText _kNewPassword = LangText(zhCN: '新密码', enUS: 'New Password');

const LangText _kConfirmNewPassword =
    LangText(zhCN: '确认新密码', enUS: 'Confirm New Password');

const LangText _kChangePassword = LangText(zhCN: '更换密码', enUS: 'Change Password');

const LangText _kEnterOld = LangText(zhCN: '请输入原密码', enUS: 'Enter your old password');

const LangText _kEnterNew = LangText(zhCN: '请输入新密码', enUS: 'Enter your new password');

const LangText _kEnterAgain = LangText(
  zhCN: '请再次输入新密码',
  enUS: 'Enter your new password again',
);

const LangText _kTooShort = LangText(
  zhCN: '密码长度至少为6',
  enUS: 'The minimum password length is 6',
);

const LangText _kSameAsOld = LangText(
  zhCN: '新密码不能和原密码相同',
  enUS: 'It must be different than the old password',
);

const LangText _kUnmatched = LangText(
  zhCN: '新密码的两次输入不一致',
  enUS: 'The two entries do not match',
);

const LangText _kChangedTitle = LangText(
  zhCN: '密码已成功修改',
  enUS: 'Password is changed successfully',
);

const LangText _kChangedContent = LangText(
  zhCN: '今后请使用新密码登录',
  enUS: 'Login with the new password from now on',
);

class UmyAccountPasswordPage extends ConsumerStatefulWidget {
  const UmyAccountPasswordPage({super.key});

  @override
  ConsumerState<UmyAccountPasswordPage> createState() =>
      _UmyAccountPasswordPageState();
}

class _UmyAccountPasswordPageState
    extends ConsumerState<UmyAccountPasswordPage> {
  final TextEditingController _old = TextEditingController();
  final TextEditingController _new = TextEditingController();
  final TextEditingController _again = TextEditingController();
  final FocusNode _focusNew = FocusNode();

  bool _loading = false;
  LangText? _feedback;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _again.dispose();
    _focusNew.dispose();
    super.dispose();
  }

  bool get _disabled =>
      _loading ||
      _old.text.isEmpty ||
      _new.text.isEmpty ||
      _again.text.isEmpty;

  /// 提交（源项目 `to_change_password`：先做表单校验，再调后端）。
  Future<void> _submit() async {
    setState(() => _feedback = null);

    final String oldPassword = _old.text;
    final String newPassword = _new.text;
    if (oldPassword.isEmpty) {
      setState(() => _feedback = _kEnterOld);
      return;
    }
    if (oldPassword.length < 6) {
      setState(() => _feedback = _kTooShort);
      return;
    }
    if (newPassword.isEmpty) {
      setState(() => _feedback = _kEnterNew);
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _feedback = _kTooShort);
      return;
    }
    if (newPassword == oldPassword) {
      setState(() => _feedback = _kSameAsOld);
      return;
    }
    if (_again.text.isEmpty) {
      setState(() => _feedback = _kEnterAgain);
      return;
    }
    if (newPassword != _again.text) {
      setState(() => _feedback = _kUnmatched);
      return;
    }

    final String usid = ref.read(onlineUserProvider)['usid']?.toString() ?? '';
    setState(() => _loading = true);
    final Map<String, dynamic> data = await ref.read(userApiProvider).changePassword(
          passwordClient: hashStable('$oldPassword$usid'),
          passwordNewClient: hashStable('$newPassword$usid'),
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (bok(data['_state']?.toString())) {
      _old.clear();
      _new.clear();
      _again.clear();
      await showPexModal(
        context,
        ref,
        title: _kChangedTitle,
        content: _kChangedContent,
      );
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/${AppRoutes.umyAccount}');
      }
      return;
    }
    setState(() {
      _feedback = data['_msg'] == null
          ? PartTexts.systemDown
          : LangText.fromMap(data['_msg']);
    });
    // 源项目失败后把焦点移回「新密码」。
    _focusNew.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final DeviceInfo device = DeviceInfo.of(context);
    final String lang = ref.watch(languageProvider);

    return PartWindowLayout(
      pageName: AppRoutes.umyAccountPassword,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  PartNavibarPcFixed(
                    title: pageMetaOf(AppRoutes.umyAccountPassword)?.i18nPageTitle,
                    pageName: AppRoutes.umyAccountPassword,
                  ),
                  _field(
                    label: _kOldPassword,
                    controller: _old,
                    autofocus: device.inPc,
                  ),
                  _field(label: _kNewPassword, controller: _new, focusNode: _focusNew),
                  _field(label: _kConfirmNewPassword, controller: _again, onSubmitted: _submit),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: PartButtonSubmit(
                      disabled: _disabled,
                      loading: _loading,
                      onPressed: _submit,
                      children: <Widget>[
                        if (!_loading)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: PexIcon.uni('checkmarkempty', size: 22, color: Colors.white),
                          ),
                        Text(ll(lang, _kChangePassword)),
                      ],
                    ),
                  ),
                  PartFeedback(bad: _feedback),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required LangText label,
    required TextEditingController controller,
    FocusNode? focusNode,
    bool autofocus = false,
    VoidCallback? onSubmitted,
  }) {
    final String lang = ref.watch(languageProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label.resolve(lang), style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 2),
          PartIdentInput(
            controller: controller,
            focusNode: focusNode,
            obscure: true,
            autofocus: autofocus,
            hasError: _feedback != null,
            onChanged: (_) {
              if (_feedback != null) setState(() => _feedback = null);
              setState(() {}); // 让提交按钮的可用态跟随输入
            },
            onSubmitted: onSubmitted ?? _submit,
            // 源项目 `wo.tt.omit_space_key`：密码里不允许空格。
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
          ),
        ],
      ),
    );
  }
}
