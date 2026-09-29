/// 新用户手机验证，对应源项目 `pages/identNewPasscode.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/lang_text.dart';
import '../core/router/app_router.dart';
import '../core/state/ident_provider.dart';
import '../widgets/part_passcode_verify.dart';
import '../widgets/part_window_layout_ident.dart';

/// PC 二级导航栏标题（源项目页面 `data.i18nPageTitle`）。
const LangText _kNavTitle = LangText(
  zhCN: '验证账号',
  enUS: 'Verify Account',
  jaJP: 'アカウント確認',
);

class IdentNewPasscodePage extends ConsumerWidget {
  const IdentNewPasscodePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String inviterHaid = ref.watch(identProvider).inviterHaid;
    return PartWindowLayoutIdent(
      pageName: AppRoutes.identNewPasscode,
      navTitle: _kNavTitle,
      child: PartPasscodeVerify(
        passcodeType: 'REGISTER',
        successRoute: AppRoutes.identNewRegcode,
        extraWhat: <String, dynamic>{'inviterHaid': inviterHaid},
      ),
    );
  }
}
