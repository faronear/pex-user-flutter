/// i18n 便捷访问层。
///
/// 对应源项目 `wo.ll({...})`（快捷取词）。词条本身优先放在各页面/组件文件内
/// （与源项目同构），跨模块共用的词条放 [Phrases]。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lang_text.dart';

/// 当前界面语言（对应源项目 `wo.ss.i18n.mylang`）。
///
/// 默认 enUS（源项目注释：默认使用国际版用户的语言）。
class LanguageNotifier extends Notifier<String> {
  @override
  String build() => LangCode.enUS;

  void set(String langCode) {
    if (langCode == state || !LangCode.isSupported(langCode)) return;
    state = langCode;
  }
}

final NotifierProvider<LanguageNotifier, String> languageProvider =
    NotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);

/// 便捷取词：`ll(lang, const LangText(...))`。
String ll(String langCode, LangText text) => text.resolve(langCode);
