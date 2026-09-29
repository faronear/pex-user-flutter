/// 密码表单（两次输入 + 可选用户协议），供注册与重设密码复用。
///
/// 对应源项目 `identNewRegister.vue` / `identOldReset.vue` 的表单部分。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/appmeta/page_meta.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/state/envar_provider.dart';
import '../core/util/feedback.dart';
import 'part_button_submit.dart';
import 'part_feedback.dart';
import 'part_ident_input.dart';

const LangText _kRequired = LangText(
  zhCN: '请输入密码',
  enUS: 'Please enter your password',
  jaJP: 'パスワードを入力してください',
);

const LangText _kTooShort = LangText(
  zhCN: '密码长度至少为6',
  enUS: 'The minimum password length is 6',
  jaJP: 'パスワードは最低6文字必要です',
);

const LangText _kUnmatched = LangText(
  zhCN: '两次密码不一致。',
  enUS: 'Passwords unmatched.',
  jaJP: 'パスワードが一致しません。',
);

const LangText _kAcceptAgreement = LangText(
  zhCN: '我同意用户协议 ',
  enUS: 'I Accept User Agreement ',
  jaJP: 'ユーザー契約に同意します ',
);

const LangText _kAgreementTitle = LangText(
  zhCN: '用户协议',
  enUS: 'User Agreement',
  jaJP: 'ユーザー契約',
);

class PartPasswordForm extends ConsumerStatefulWidget {
  const PartPasswordForm({
    super.key,
    required this.placeholder1,
    required this.placeholder2,
    required this.submitText,
    required this.onSubmit,
    this.showAgree = false,
    this.enabled = true,
  });

  final LangText placeholder1;
  final LangText placeholder2;
  final LangText submitText;

  /// 返回后端错误文案（null 表示成功）。
  final Future<LangText?> Function(String password) onSubmit;

  final bool showAgree;
  final bool enabled;

  @override
  ConsumerState<PartPasswordForm> createState() => _PartPasswordFormState();
}

class _PartPasswordFormState extends ConsumerState<PartPasswordForm> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _passwordAgain = TextEditingController();
  bool _agreed = true;
  bool _loading = false;
  LangText? _fieldBad;
  LangText? _remoteBad;

  @override
  void dispose() {
    _password.dispose();
    _passwordAgain.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _fieldBad = null;
      _remoteBad = null;
    });

    if (_password.text.isEmpty || _passwordAgain.text.isEmpty) {
      setState(() => _fieldBad = _kRequired);
      return;
    }
    if (_password.text.length < 6) {
      setState(() => _fieldBad = _kTooShort);
      return;
    }
    if (_password.text != _passwordAgain.text) {
      setState(() => _fieldBad = _kUnmatched);
      return;
    }
    if (widget.showAgree && !_agreed) {
      setState(() => _fieldBad = _kAcceptAgreement);
      return;
    }

    setState(() => _loading = true);
    final LangText? error = await widget.onSubmit(_password.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _remoteBad = error;
    });
  }

  Future<void> _openAgreement() async {
    final String url = ref.read(envarProvider).linkAgreement;
    if (url.isEmpty) return;
    await showPexModal(
      context,
      ref,
      title: _kAgreementTitle,
      content: LangText.from(url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final bool canSubmit = widget.enabled &&
        !_loading &&
        _password.text.isNotEmpty &&
        _passwordAgain.text.isNotEmpty &&
        (!widget.showAgree || _agreed);

    return Column(
      children: <Widget>[
        const SizedBox(height: 10),
        PartIdentInput(
          controller: _password,
          placeholder: widget.placeholder1,
          obscure: true,
          enabled: widget.enabled && !_loading,
          textInputAction: TextInputAction.next,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        PartIdentInput(
          controller: _passwordAgain,
          placeholder: widget.placeholder2,
          obscure: true,
          enabled: widget.enabled && !_loading,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
          onChanged: (_) => setState(() {}),
          onSubmitted: _submit,
        ),
        PartFeedback(bad: _fieldBad, good: null),
        if (widget.showAgree)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Checkbox(
                  value: _agreed,
                  onChanged: (bool? value) => setState(() => _agreed = value ?? false),
                ),
                GestureDetector(
                  onTap: _openAgreement,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        ll(lang, _kAcceptAgreement),
                        style: const TextStyle(color: Color(0xFF2979FF)),
                      ),
                      PexIcon.icont('icont-hyperlink', size: 14, color: const Color(0xFF2979FF)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: PartButtonSubmit(
            disabled: !canSubmit,
            loading: _loading,
            onPressed: _submit,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: PexIcon.uni('auth', size: 22, color: Colors.white),
              ),
              Text(ll(lang, widget.submitText)),
            ],
          ),
        ),
        PartFeedback(bad: _remoteBad),
      ],
    );
  }
}

/// 供页面取用的页面标题（未使用 pageMeta 时兜底）。
LangText? pageTitleOf(String pageName) => pageMetaOf(pageName)?.i18nPageTitle;
