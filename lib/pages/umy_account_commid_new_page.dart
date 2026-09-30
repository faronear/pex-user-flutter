/// 设置新账号，对应源项目 `pages/umyAccountCommidNew.vue`：
/// 选国家区号 → 填新的手机号或邮箱 → 给新账号发验证码 → 校验通过即成为新的登录账号。
///
/// 进入本页的前提是上一页（`umyAccountCommid`）已通过「验证当前账号」，
/// 即 `identProvider.verifyExpireAt` 尚未过期；过期时后端会返回
/// `OLD_VERIFY_EXPIRED` 并带出原因文案（源项目在客户端先做同样判断）。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_router.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../core/state/ident_provider.dart';
import '../core/state/region_provider.dart';
import '../core/util/feedback.dart';
import '../core/util/pex_toolkit.dart';
import '../core/i18n/lands.dart';
import '../theme/app_theme.dart';
import '../widgets/part_feedback.dart';
import '../widgets/part_ident_input.dart';
import '../widgets/part_land_table.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_passcode_verify.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_window_layout.dart';

const LangText _kNavTitle = LangText(zhCN: '设置新账号', enUS: 'Setup New ID');

const LangText _kPlaceholder = LangText(
  zhCN: '新的手机号或邮箱',
  enUS: 'Your new phone number or email address',
);

const LangText _kMalformed = LangText(
  zhCN: '手机号或邮箱的格式错误',
  enUS: 'The phone or email is malformed',
);

const LangText _kSameAsOld = LangText(
  zhCN: '新的登录账号不能和原有的相同',
  enUS: 'The new login must be different than the old one',
);

const LangText _kReadyTitle = LangText(
  zhCN: '您的新账号已生效',
  enUS: 'Your new ID is ready',
);

class UmyAccountCommidNewPage extends ConsumerStatefulWidget {
  const UmyAccountCommidNewPage({super.key});

  @override
  ConsumerState<UmyAccountCommidNewPage> createState() =>
      _UmyAccountCommidNewPageState();
}

class _UmyAccountCommidNewPageState
    extends ConsumerState<UmyAccountCommidNewPage> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  /// 已解析出的新账号（`+区号-号码` 或小写邮箱）；为空表示尚未填写/格式不合法。
  String _commid = '';
  LangText? _error;

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  /// 解析输入（对应源项目表单里的 `validateFunction`）：
  /// 邮箱直接用；纯数字按「区号-号码」或「当前区号 + 号码」拼装。
  (String, LangText?) _resolve(String value, LandItem land, String phone, String email) {
    final String text = value.trim();
    if (text.isEmpty) return ('', null);

    String commid;
    if (validateEmail(text)) {
      commid = text.toLowerCase();
    } else {
      final List<String> parts =
          RegExp(r'\d+').allMatches(text).map((RegExpMatch m) => m.group(0)!).toList();
      if (parts.isEmpty || parts.length > 2) return ('', _kMalformed);
      commid = parts.length == 2
          ? '+${parts[0].replaceFirst(RegExp(r'^0+'), '')}-${parts[1]}'
          : '+${land.itc}-$text';
      if (!validatePhone(commid)) return ('', _kMalformed);
    }
    if (commid == phone || commid == email) return ('', _kSameAsOld);
    return (commid, null);
  }

  Future<void> _pickLand() async {
    final LandItem? picked = await showModalBottomSheet<LandItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          minWidth: 320,
        ),
        child: PartLandTable(
          landCodeNow: ref.read(phoneLandProvider).iso2,
          onPick: (LandItem land) => Navigator.of(context).pop(land),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    ref.read(phoneLandProvider.notifier).set(picked);
    _recompute();
    _inputFocus.requestFocus();
  }

  /// 重新解析输入（源项目在 `pick_land` 后同样会重新聚焦）。
  void _recompute() {
    final Map<String, dynamic> user = ref.read(onlineUserProvider);
    final (String, LangText?) resolved = _resolve(
      _input.text,
      ref.read(phoneLandProvider),
      user['phone']?.toString() ?? '',
      user['email']?.toString() ?? '',
    );
    setState(() {
      _commid = resolved.$1;
      _error = resolved.$2;
    });
  }

  Future<void> _verified() async {
    ref.read(appStartupProvider.notifier).mergeOnlineUser(
          _commid.contains('@') ? <String, dynamic>{'email': _commid} : <String, dynamic>{'phone': _commid},
        );
    await showPexModal(
      context,
      ref,
      title: _kReadyTitle,
      content: LangText.from(_commid),
    );
    if (!mounted) return;
    // 源项目 `uni.switchTab({ url: 'menuUzone' })`。
    context.go('/${AppRoutes.menuUzone}');
  }

  @override
  Widget build(BuildContext context) {
    final AppStartupState startup = ref.watch(appStartupProvider);
    final DeviceInfo device = DeviceInfo.of(context);
    final String lang = ref.watch(languageProvider);
    final LandItem land = ref.watch(phoneLandProvider);
    final Map<String, dynamic> user = ref.watch(onlineUserProvider);
    final String usid = user['usid']?.toString() ?? '';

    return PartWindowLayout(
      pageName: AppRoutes.umyAccountCommidNew,
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
                          title: _kNavTitle,
                          pageName: AppRoutes.umyAccountCommidNew,
                        ),
                        PartPasscodeVerify(
                          passcodeType: 'CHECK_NEW',
                          commid: _commid,
                          usid: usid,
                          sendDisabled: _commid.isEmpty,
                          onVerified: _verified,
                          // 每次给新账号发验证码，就延长本页操作的有效期（对齐源项目）。
                          onPasscodeSent: (int expireAt) {
                            final IdentState ident = ref.read(identProvider);
                            if (expireAt > ident.verifyExpireAt) {
                              ref
                                  .read(identProvider.notifier)
                                  .setVerifyExpireAt(expireAt);
                            }
                          },
                          header: Column(
                            children: <Widget>[
                              Center(child: _landPicker(lang, land)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: PartIdentInput(
                                  controller: _input,
                                  focusNode: _inputFocus,
                                  placeholder: _kPlaceholder,
                                  autofocus: true,
                                  hasError: _error != null,
                                  keyboardType: TextInputType.emailAddress,
                                  inputFormatters: <TextInputFormatter>[
                                    // 源项目 `omit_space_key`：不允许空格。
                                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                  ],
                                  onChanged: (String value) => _recompute(),
                                ),
                              ),
                              PartFeedback(bad: _error),
                            ],
                          ),
                        ),
                        SizedBox(height: device.inPc ? 30 : 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  /// 区号选择行（源项目：emoji 或国旗图 + 区号 + 下拉箭头）。
  Widget _landPicker(String lang, LandItem land) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _pickLand,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(land.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 10),
            Text(
              '+${land.itc}',
              style: const TextStyle(fontSize: 24, letterSpacing: 4),
            ),
            const SizedBox(width: 20),
            PexIcon.uni('bottom', size: 20, color: PexColors.grey3),
          ],
        ),
      ),
    );
  }
}
