/// 销毁账号，对应源项目 `pages/umyAccountTerminate.vue`：
/// 输入密码 → 二次确认 → `User/terminate_account`（7 天后真正清空，期内重新登录即取消）→ 退出登录。
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
import '../core/state/app_providers.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../core/state/session_reset.dart';
import '../core/util/feedback.dart';
import '../core/util/pex_toolkit.dart';
import '../widgets/part_button_submit.dart';
import '../widgets/part_feedback.dart';
import '../widgets/part_ident_input.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_window_layout.dart';

const LangText _kHeadline = LangText(
  zhCN: '销毁本账号及用户数据',
  enUS: 'Terminate this account and data',
);

const LangText _kEnterPassword = LangText(
  zhCN: '输入您的密码',
  enUS: 'Enter Your Password',
);

const LangText _kEnterOldPassword = LangText(
  zhCN: '请输入原密码',
  enUS: 'Enter your old password',
);

const LangText _kTooShort = LangText(
  zhCN: '密码长度至少为6',
  enUS: 'Minimum password length is 6',
);

const LangText _kTerminate = LangText(
  zhCN: '销毁账号',
  enUS: 'Terminate Account',
);

const LangText _kConfirmTitle = LangText(
  zhCN: '彻底销毁本账号？',
  enUS: 'Terminate this account?',
);

const LangText _kConfirmButton = LangText(zhCN: '销毁账号', enUS: 'Terminate');

const LangText _kWarning = LangText(
  zhCN: '警告：您的账号将于7天后被销毁！',
  enUS: 'Warning: this account will be terminated after 7 days!',
);

const LangText _kStartedTitle = LangText(
  zhCN: '您的账号已进入销毁流程',
  enUS: 'Your account termination is started',
);

const LangText _kStartedContent = LangText(
  zhCN: '您的账号将于7天后被清空。如果在此7天内您改变了意愿，只要重新登录，即可取消账号销毁流程。',
  enUS: 'Your account will be removed after 7 days. Should you change mind in these 7 days, you can login again and the termination process will be canceled.',
);

class UmyAccountTerminatePage extends ConsumerStatefulWidget {
  const UmyAccountTerminatePage({super.key});

  @override
  ConsumerState<UmyAccountTerminatePage> createState() =>
      _UmyAccountTerminatePageState();
}

class _UmyAccountTerminatePageState
    extends ConsumerState<UmyAccountTerminatePage> {
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  LangText? _feedback;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _terminate() async {
    setState(() => _feedback = null);

    final String password = _password.text;
    if (password.isEmpty) {
      setState(() => _feedback = _kEnterOldPassword);
      return;
    }
    if (password.length < 6) {
      setState(() => _feedback = _kTooShort);
      return;
    }

    final Map<String, dynamic> user = ref.read(onlineUserProvider);
    final bool confirmed = await showPexModal(
      context,
      ref,
      title: _kConfirmTitle,
      // 源项目把昵称和警告拼在同一个弹窗正文里（手机端弹窗正文不能为空）。
      content: LangText.from(
        '${user['nickname'] ?? ''}\n\n${_kWarning.resolve(ref.read(languageProvider))}',
      ),
      confirmText: _kConfirmButton,
      showCancel: true,
    );
    if (!confirmed || !mounted) return;

    final String usid = user['usid']?.toString() ?? '';
    setState(() => _loading = true);
    final Map<String, dynamic> data = await ref.read(userApiProvider).terminateAccount(
          passwordClient: hashStable('$password$usid'),
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (!bok(data['_state']?.toString())) {
      setState(() {
        _feedback = data['_msg'] == null
            ? PartTexts.systemDown
            : LangText.fromMap(data['_msg']);
      });
      return;
    }

    await showPexModal(
      context,
      ref,
      title: _kStartedTitle,
      content: _kStartedContent,
    );
    if (!mounted) return;
    // 源项目 `success: wo.tt.logout_local_account`：清凭据 + 清缓存 + 回落地页。
    await ref.read(localStoreProvider).clearPasstoken();
    ref.read(appStartupProvider.notifier).logout();
    resetSessionCaches(ref);
    if (!mounted) return;
    context.go(AppRoutes.path(ref.read(brandProvider).appLandPage));
  }

  @override
  Widget build(BuildContext context) {
    final AppStartupState startup = ref.watch(appStartupProvider);
    final DeviceInfo device = DeviceInfo.of(context);
    final String lang = ref.watch(languageProvider);
    // 源项目 `wo.ss.tTerminate`：品牌自定义的注销说明。**当前后端从未定义过该字段**
    //（`envar-config.js` 里恒为 undefined），因此默认不显示——填了就会显示出来。
    final LangText terminateNote = LangText.fromMap(ref.watch(envarProvider).raw['tTerminate']);
    final bool canSubmit = !_loading && _password.text.isNotEmpty;

    return PartWindowLayout(
      pageName: AppRoutes.umyAccountTerminate,
      child: !startup.afterAutologging
          ? const PartShowLoading()
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        PartNavibarPcFixed(
                          title: pageMetaOf(AppRoutes.umyAccountTerminate)?.i18nPageTitle,
                          pageName: AppRoutes.umyAccountTerminate,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 20, 0, 40),
                          child: Text(
                            ll(lang, _kHeadline),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.8,
                            ),
                          ),
                        ),
                        if (!terminateNote.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Text(ll(lang, terminateNote)),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                ll(lang, _kEnterPassword),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              PartIdentInput(
                                controller: _password,
                                obscure: true,
                                autofocus: device.inPc,
                                hasError: _feedback != null,
                                onChanged: (_) {
                                  if (_feedback != null) setState(() => _feedback = null);
                                  setState(() {});
                                },
                                onSubmitted: _terminate,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: PartButtonSubmit(
                            disabled: !canSubmit,
                            loading: _loading,
                            onPressed: _terminate,
                            children: <Widget>[
                              if (!_loading)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: PexIcon.uni('trash', size: 22, color: Colors.white),
                                ),
                              Text(ll(lang, _kTerminate)),
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
}
