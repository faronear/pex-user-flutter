/// 当前提交的手机号/邮箱显示，对应源项目 `parts/partIdentCommid.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/router/app_router.dart';
import '../core/state/ident_provider.dart';

/// 「手机号或邮箱不存在」提示（源项目内联文案）。
const LangText _kMissing = LangText(
  zhCN: '手机号或邮箱不存在！\n返回上一页',
  enUS: 'Phone or email is missing!\nClick here to go back.',
  jaJP: '電話番号またはメールアドレスがありません！\n戻るをクリックしてください。',
);

class PartIdentCommid extends ConsumerWidget {
  const PartIdentCommid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String commid = ref.watch(identProvider).commid;
    final String lang = ref.watch(languageProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 32),
      child: Center(
        child: commid.isNotEmpty
            ? Text(
                commid,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              )
            : GestureDetector(
                onTap: () => context.push(AppRoutes.path(AppRoutes.identBegin)),
                child: Text(
                  ll(lang, _kMissing),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFFFA3534),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
      ),
    );
  }
}
