/// 账号入口（输入手机号/邮箱），对应源项目 `pages/identBegin.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lands.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/router/app_router.dart';
import '../core/state/app_providers.dart';
import '../core/state/ident_provider.dart';
import '../core/state/region_provider.dart';
import '../core/util/pex_toolkit.dart';
import '../widgets/part_button_submit.dart';
import '../widgets/part_feedback.dart';
import '../widgets/part_ident_input.dart';
import '../widgets/part_land_table.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_window_layout_ident.dart';

const LangText _kPlaceholder = LangText(
  zhCN: '您的手机号或电子邮箱',
  enUS: 'Enter your phone or email',
  jaJP: '電話番号またはメールアドレスを入力',
  deDE: 'Geben Sie Ihre Telefonnummer oder E-Mail ein',
);

const LangText _kEmpty = LangText(
  zhCN: '请输入您的手机号或电子邮箱',
  enUS: 'Enter your phone number or email address',
  jaJP: '電話番号またはメールアドレスを入力してください',
  deDE: 'Geben Sie Ihre Telefonnummer oder E-Mail ein',
);

const LangText _kBadFormat = LangText(
  zhCN: '手机号或邮箱的格式错误',
  enUS: 'The phone or email is in bad format',
  jaJP: '電話番号またはメールアドレスの形式が正しくありません',
  deDE: 'Die Telefonnummer oder E-Mail-Adresse ist nicht korrekt formatiert',
);

const LangText _kHint = LangText(
  zhCN: '您可以输入“国际区号-手机号码“，例如“44-12345678”，即可快速切换区号。',
  enUS: 'You can quickly switch country by entering "country code - phone number", such as ”44-12345678“.',
);

const LangText _kSubmit = LangText(zhCN: '提 交', enUS: 'Submit', jaJP: '送 信', deDE: 'Absenden');

const LangText _kLookAround = LangText(
  zhCN: '先到处看看',
  enUS: 'Look around first',
  jaJP: 'まず周りを見てください',
  deDE: 'Schauen Sie sich zuerst um',
);

/// PC 二级导航栏标题（源项目页面 `data.i18nPageTitle`）。
const LangText _kNavTitle = LangText(
  zhCN: '账号',
  enUS: 'Account',
  jaJP: 'アカウント',
  deDE: 'Konto',
);

class IdentBeginPage extends ConsumerStatefulWidget {
  const IdentBeginPage({super.key});

  @override
  ConsumerState<IdentBeginPage> createState() => _IdentBeginPageState();
}

class _IdentBeginPageState extends ConsumerState<IdentBeginPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  LangText? _feedback;
  LangText? _feedbackRemote;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 校验并顺带设置 `commid`（对应源项目 `validate_form`）。
  bool _validateForm() {
    setState(() => _feedback = null);
    final String text = _controller.text;
    if (text.isEmpty) {
      setState(() => _feedback = _kEmpty);
      return false;
    }

    if (validateEmail(text)) {
      ref.read(identProvider.notifier).setCommid(text.toLowerCase());
      return true;
    }

    final List<String> parts =
        RegExp(r'\d+').allMatches(text).map((RegExpMatch m) => m.group(0)!).toList();
    if (parts.isNotEmpty) {
      final LandItem land = ref.read(phoneLandProvider);
      String commid = '';
      if (parts.length == 2) {
        commid = '+${parts[0].replaceFirst(RegExp(r'^0+'), '')}-${parts[1]}';
      } else if (parts.length == 1) {
        commid = '+${land.itc}-$text';
      }
      if (commid.isNotEmpty && validatePhone(commid)) {
        ref.read(identProvider.notifier).setCommid(commid);
        return true;
      }
    }

    setState(() => _feedback = _kBadFormat);
    return false;
  }

  Future<void> _submit() async {
    setState(() => _feedbackRemote = null);
    if (!_validateForm()) return;

    final String commid = ref.read(identProvider).commid;
    setState(() => _loading = true);
    final Map<String, dynamic> result = await ref.read(apiClientProvider).callBase(
          apiWho: 'User',
          apiTodo: 'identify_user',
          apiWhat: <String, dynamic>{'commid': commid},
        );
    if (!mounted) return;
    setState(() => _loading = false);

    final String state = result['_state']?.toString() ?? '';
    if (state == 'OLD_USER') {
      ref.read(identProvider.notifier).setUsid(result['usid']?.toString() ?? '');
      if (mounted) context.push(AppRoutes.path(AppRoutes.identOldLogin));
    } else if (state == 'NEW_USER') {
      ref.read(identProvider.notifier).setUsid(result['usid']?.toString() ?? '');
      if (mounted) context.push(AppRoutes.path(AppRoutes.identNewPasscode));
    } else {
      setState(() {
        _feedbackRemote = result['_msg'] == null
            ? PartTexts.systemDown
            : LangText.fromMap(result['_msg']);
      });
    }
  }

  Future<void> _pickLand() async {
    final LandItem current = ref.read(phoneLandProvider);
    final LandItem? picked = await showModalBottomSheet<LandItem>(
      context: context,
      builder: (BuildContext context) => PartLandTable(
        landCodeNow: current.iso2,
        onPick: (LandItem land) => Navigator.of(context).pop(land),
      ),
    );
    if (picked != null) {
      ref.read(phoneLandProvider.notifier).set(picked);
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final LandItem land = ref.watch(phoneLandProvider);

    return PartWindowLayoutIdent(
      pageName: AppRoutes.identBegin,
      navTitle: _kNavTitle,
      child: Column(
        children: <Widget>[
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: _pickLand,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(land.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Text(
                      '+${land.itc}',
                      style: const TextStyle(fontSize: 24, letterSpacing: 2),
                    ),
                    const SizedBox(width: 10),
                    PexIcon.uni('bottom', size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          PartIdentInput(
            controller: _controller,
            focusNode: _focusNode,
            placeholder: _kPlaceholder,
            hasError: _feedback != null,
            onChanged: (_) {
              if (_feedback != null) setState(() => _feedback = null);
              setState(() {}); // 让提交按钮的可用态跟随输入
            },
            onSubmitted: _submit,
            // 源项目 onkeypress="return wo.tt.omit_space_key(event)"：禁止空格。
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
          ),
          const PartFeedback(),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                ll(lang, _feedback ?? _kHint),
                style: TextStyle(
                  fontSize: 12,
                  color: _feedback != null
                      ? const Color(0xFFDD6161)
                      : const Color(0xFF909399),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: PartButtonSubmit(
              disabled: _loading || _controller.text.isEmpty,
              loading: _loading,
              onPressed: _submit,
              children: <Widget>[
                if (!_loading)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PexIcon.uni('checkmarkempty', size: 22, color: Colors.white),
                  ),
                Text(ll(lang, _kSubmit)),
              ],
            ),
          ),
          const PartFeedback(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/menuAipp'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    ll(lang, _kLookAround),
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
          _buildRemoteFeedback(lang),
        ],
      ),
    );
  }

  Widget _buildRemoteFeedback(String lang) {
    if (_feedbackRemote == null) return const SizedBox(height: 22);
    return SizedBox(
      height: 22,
      child: Center(
        child: Text(
          ll(lang, _feedbackRemote!),
          style: const TextStyle(fontSize: 12, color: Color(0xFFDD6161)),
        ),
      ),
    );
  }
}
