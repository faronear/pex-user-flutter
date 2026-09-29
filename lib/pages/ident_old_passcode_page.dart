/// 老用户重设密码前的手机验证，对应源项目 `pages/identOldPasscode.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/lang_text.dart';
import '../core/router/app_router.dart';
import '../widgets/part_passcode_verify.dart';
import '../widgets/part_window_layout_ident.dart';

/// PC 二级导航栏标题（源项目页面 `data.i18nPageTitle`）。
const LangText _kNavTitle = LangText(
  zhCN: '验证账号',
  enUS: 'Verify Identify',
  jaJP: 'アカウント認証',
);

class IdentOldPasscodePage extends ConsumerWidget {
  const IdentOldPasscodePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PartWindowLayoutIdent(
      pageName: AppRoutes.identOldPasscode,
      navTitle: _kNavTitle,
      child: PartPasscodeVerify(
        passcodeType: 'RESETPWD',
        successRoute: AppRoutes.identOldReset,
      ),
    );
  }
}
