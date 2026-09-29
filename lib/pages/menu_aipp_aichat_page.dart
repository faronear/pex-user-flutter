/// 单独打开某个 Aibot 的对话页，对应源项目 `pages/menuAippAichat.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../widgets/part_aichat.dart';
import '../widgets/part_window_layout.dart';

/// PC 二级导航栏标题。
const LangText _kNavTitle = LangText(
  zhCN: 'AI对话',
  enUS: 'AI Chat',
  deDE: 'KI-Chat',
  jaJP: 'AIチャット',
);

class MenuAippAichatPage extends ConsumerWidget {
  const MenuAippAichatPage({super.key, this.aicode});

  final String? aicode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PartWindowLayout(
      pageName: 'menuAippAichat',
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _kNavTitle.resolve(ref.watch(languageProvider)),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: PartAichat(aicode: aicode)),
        ],
      ),
    );
  }
}
