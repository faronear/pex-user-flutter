/// 验证当前账号，对应源项目 `pages/umyAccountCommid.vue`：
/// 在「当前手机 / 当前邮箱」之间切换 → 给该账号发验证码 → 校验通过后进入「设置新账号」。
///
/// 页面标题源项目写作「验证当前账号 / Verify Current Account」（未走 `pageSet`）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_router.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_passcode_verify.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_window_layout.dart';

const LangText _kNavTitle = LangText(
  zhCN: '验证当前账号',
  enUS: 'Verify Current Account',
);

const LangText _kCurrentPhone = LangText(zhCN: '当前手机', enUS: 'Current Phone');

const LangText _kCurrentEmail = LangText(zhCN: '当前邮箱', enUS: 'Current Email');

class UmyAccountCommidPage extends ConsumerStatefulWidget {
  const UmyAccountCommidPage({super.key});

  @override
  ConsumerState<UmyAccountCommidPage> createState() =>
      _UmyAccountCommidPageState();
}

class _UmyAccountCommidPageState extends ConsumerState<UmyAccountCommidPage> {
  /// 当前选中的 commid（手机或邮箱）。
  String _commid = '';

  @override
  Widget build(BuildContext context) {
    final AppStartupState startup = ref.watch(appStartupProvider);
    final DeviceInfo device = DeviceInfo.of(context);
    final String lang = ref.watch(languageProvider);
    final Map<String, dynamic> user = ref.watch(onlineUserProvider);

    final String phone = user['phone']?.toString() ?? '';
    final String email = user['email']?.toString() ?? '';
    // 源项目按「先手机、后邮箱」的顺序列出，默认选中手机（没有手机则邮箱）。
    final List<(String, LangText)> options = <(String, LangText)>[
      if (phone.isNotEmpty) (phone, _kCurrentPhone),
      if (email.isNotEmpty) (email, _kCurrentEmail),
    ];
    final List<String> commids =
        options.map(((String, LangText) pair) => pair.$1).toList();
    if (!commids.contains(_commid)) {
      _commid = commids.isEmpty ? '' : commids.first;
    }
    final String usid = user['usid']?.toString() ?? '';

    return PartWindowLayout(
      pageName: AppRoutes.umyAccountCommid,
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
                          pageName: AppRoutes.umyAccountCommid,
                        ),
                        PartPasscodeVerify(
                          passcodeType: 'CHECK_OLD',
                          commid: _commid,
                          usid: usid,
                          // 手机和邮箱都没有时不能发验证码（源项目 `isDisabled`）。
                          sendDisabled: _commid.isEmpty,
                          onVerified: () => context.push(
                            '/${AppRoutes.umyAccountCommidNew}',
                          ),
                          header: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                            child: _header(lang, options, commids),
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

  /// 顶栏：分段选择器 + 大字号的当前账号。
  Widget _header(String lang, List<(String, LangText)> options, List<String> commids) {
    return Column(
      children: <Widget>[
        if (options.length > 1)
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: PexColors.blueMy),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int i = 0; i < options.length; i++)
                    InkWell(
                      onTap: () => setState(() => _commid = commids[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        color: commids[i] == _commid ? PexColors.blueMy : null,
                        child: Text(
                          ll(lang, options[i].$2),
                          style: TextStyle(
                            fontSize: 14,
                            color: commids[i] == _commid
                                ? Colors.white
                                : PexColors.blueMy,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
          child: Text(
            _commid,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
