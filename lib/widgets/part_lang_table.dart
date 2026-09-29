/// 语言选择器，对应源项目 `parts/partLangTable.vue`。
///
/// 阶段零简化版：底部入口 + 弹出列表，列出 [LangCode.all] 并可切换当前语言。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';

/// 语言代码 → 母语名（对应源项目 `langSet[*].native`）。
const Map<String, String> kLangNative = <String, String>{
  LangCode.enUS: 'English',
  LangCode.deDE: 'Deutsch',
  LangCode.jaJP: '日本語',
  LangCode.zhCN: '简体中文',
};

class PartLangTable extends ConsumerWidget {
  const PartLangTable({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    return TextButton(
      onPressed: () => _showPicker(context, ref, lang),
      style: TextButton.styleFrom(foregroundColor: color ?? Colors.white),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(kLangNative[lang] ?? lang, style: const TextStyle(fontSize: 14)),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );
  }

  Future<void> _showPicker(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final String code in LangCode.all)
              ListTile(
                title: Text(kLangNative[code] ?? code),
                trailing: code == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(code),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      ref.read(languageProvider.notifier).set(picked);
    }
  }
}
