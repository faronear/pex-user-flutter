/// 联系客服，对应源项目 `pages/umyContact.vue`：
/// 邮箱 + 留言 → `System/contact_csr`（后端拼成邮件发给值班邮箱），
/// 另附团队电话 / 邮箱 / 地址。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/api_client.dart';
import '../core/api/system_api.dart';
import '../core/appmeta/page_meta.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_router.dart';
import '../core/state/envar_provider.dart';
import '../core/util/feedback.dart';
import '../core/util/pex_toolkit.dart';
import '../theme/app_theme.dart';
import '../widgets/part_button_submit.dart';
import '../widgets/part_lang_table.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_window_layout.dart';

const LangText _kGreeting = LangText(
  zhCN: '我们期待您的任何消息！',
  enUS: "We'd love to hear from you!",
);

const LangText _kYourEmail = LangText(zhCN: '您的邮箱', enUS: 'Your Email');

const LangText _kEmailPlaceholder = LangText(
  zhCN: '留下您的电子邮箱，以便我们回复您。',
  enUS: 'Leave your email so that we can reply you.',
);

const LangText _kInvalidEmail = LangText(
  zhCN: '请输入有效的邮箱地址',
  enUS: 'Please enter a valid email address',
);

const LangText _kMessage = LangText(zhCN: '留言', enUS: 'Message');

const LangText _kMessagePlaceholder = LangText(
  zhCN: '有任何问题、投诉、建议？或许仅仅说声你好？',
  enUS: 'Do you have anything to ask, complain, or suggest? Maybe just wanna say hello?',
);

const LangText _kEmptyMessage = LangText(
  zhCN: '请写点儿什么，不能全是空白哦',
  enUS: 'Please enter your message',
);

const LangText _kSend = LangText(zhCN: '发 送', enUS: 'Send');

const LangText _kDelivered = LangText(
  zhCN: '您的消息已成功发送',
  enUS: 'Your message is delivered',
);

const LangText _kThanks = LangText(
  zhCN: '感谢您的反馈，我们会尽快与您联系。',
  enUS: 'Thank you for your feedback, we will get back to you as soon as possible.',
);

const LangText _kAlsoContact = LangText(
  zhCN: '您也可以使用以下方式联系我们：',
  enUS: 'You can also contact us through:',
);

class UmyContactPage extends ConsumerStatefulWidget {
  const UmyContactPage({super.key});

  @override
  ConsumerState<UmyContactPage> createState() => _UmyContactPageState();
}

class _UmyContactPageState extends ConsumerState<UmyContactPage> {
  late final TextEditingController _email = TextEditingController(
    text: ref.read(onlineUserProvider)['email']?.toString() ?? '',
  );
  final TextEditingController _message = TextEditingController();

  LangText? _feedbackEmail;
  LangText? _feedbackRemote;
  bool _loadingSubmit = false;

  @override
  void dispose() {
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  /// 发送留言（源项目 `to_send_message`）。
  Future<void> _send() async {
    setState(() => _feedbackEmail = null);
    final String email = _email.text.trim();
    if (!validateEmail(email)) {
      setState(() => _feedbackEmail = _kInvalidEmail);
      return;
    }
    if (_message.text.trim().isEmpty) {
      setState(() => _feedbackRemote = _kEmptyMessage);
      return;
    }

    setState(() {
      _feedbackRemote = null;
      _loadingSubmit = true;
    });
    final Map<String, dynamic> data = await ref
        .read(systemApiProvider)
        .contactCsr(message: _message.text, email: email);
    if (!mounted) return;
    setState(() => _loadingSubmit = false);

    if (bok(data['_state']?.toString())) {
      await showPexModal(context, ref, title: _kDelivered, content: _kThanks);
      if (!mounted) return;
      _message.clear();
      // 源项目发送成功后 `uni.navigateBack()`。
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.path(AppRoutes.menuUzone));
      }
      return;
    }
    final LangText message = LangText.fromMap(data['_msg']);
    setState(() => _feedbackRemote = message.isEmpty ? PartTexts.systemDown : message);
  }

  @override
  Widget build(BuildContext context) {
    final DeviceInfo device = DeviceInfo.of(context);
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final String teamPhone = envar.str('teamPhone');
    final String teamEmail = envar.str('teamEmail');
    final String teamOffice = envar.str('teamOffice');

    return PartWindowLayout(
      pageName: AppRoutes.umyContact,
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
                    title: pageMetaOf(AppRoutes.umyContact)?.i18nPageTitle,
                    pageName: AppRoutes.umyContact,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                    child: Text(
                      ll(lang, _kGreeting),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ll(lang, _kYourEmail),
                    style: const TextStyle(fontSize: 14, color: PexColors.grey3),
                  ),
                  const SizedBox(height: 4),
                  _field(
                    controller: _email,
                    hint: _kEmailPlaceholder,
                    keyboardType: TextInputType.emailAddress,
                    maxLines: 1,
                  ),
                  _feedback(_feedbackEmail),
                  const SizedBox(height: 10),
                  Text(
                    ll(lang, _kMessage),
                    style: const TextStyle(fontSize: 14, color: PexColors.grey3),
                  ),
                  const SizedBox(height: 4),
                  _field(
                    controller: _message,
                    hint: _kMessagePlaceholder,
                    maxLength: 512,
                    minLines: 5,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: PartButtonSubmit(
                      disabled: _message.text.isEmpty || _email.text.isEmpty,
                      loading: _loadingSubmit,
                      height: 60,
                      onPressed: _send,
                      children: <Widget>[
                        if (!_loadingSubmit)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: PexIcon.uni('paperplane-filled', size: 22, color: Colors.white),
                          ),
                        Text(ll(lang, _kSend)),
                      ],
                    ),
                  ),
                  Center(child: _feedback(_feedbackRemote, alignCenter: true)),
                  const SizedBox(height: 30),
                  const Divider(height: 1, color: PexColors.greyE),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                    child: Text(
                      ll(lang, _kAlsoContact),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (teamPhone.isNotEmpty)
                          _contactLink(
                            icon: 'phone-filled',
                            text: teamPhone,
                            onTap: () => _openUrl('tel:$teamPhone'),
                          ),
                        if (teamEmail.isNotEmpty)
                          _contactLink(
                            icon: 'email-filled',
                            text: teamEmail,
                            onTap: () => _openUrl('mailto:$teamEmail'),
                          ),
                        if (teamOffice.isNotEmpty)
                          _contactLink(
                            icon: 'home-filled',
                            text: teamOffice,
                            color: PexColors.grey3,
                          ),
                      ],
                    ),
                  ),
                  if (!device.inPc)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: PartLangTable(color: PexColors.grey3)),
                    )
                  else
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
    required TextEditingController controller,
    required LangText hint,
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    int minLines = 1,
  }) {
    final String lang = ref.watch(languageProvider);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      style: const TextStyle(fontSize: 15),
      onChanged: (_) => setState(() {}), // 让「发送」按钮的可用态跟随输入
      decoration: InputDecoration(
        hintText: ll(lang, hint),
        hintStyle: const TextStyle(color: PexColors.greyA, fontSize: 14),
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.all(8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: PexColors.greyE),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: PexColors.greyE),
        ),
      ),
    );
  }

  Widget _feedback(LangText? text, {bool alignCenter = false}) {
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        ll(ref.watch(languageProvider), text),
        textAlign: alignCenter ? TextAlign.center : TextAlign.start,
        style: const TextStyle(fontSize: 13, color: PexColors.redMy),
      ),
    );
  }

  Widget _contactLink({
    required String icon,
    required String text,
    VoidCallback? onTap,
    Color color = PexColors.blueMy,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PexIcon.uni(icon, size: 22, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(fontSize: 16, color: color, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
