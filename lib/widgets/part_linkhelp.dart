/// 帮助链接，对应源项目 `parts/partLinkhelp.vue`。
///
/// 蓝色小字 + 问号图标，点击用外部浏览器打开（源项目在 App 内也走 `open_url`，
/// 以避免 webview 里没有返回按钮）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../theme/app_theme.dart';

const LangText _kHelp = LangText(
  zhCN: '帮助',
  enUS: 'Help',
  jaJP: 'ヘルプ',
  deDE: 'Hilfe',
);

class PartLinkhelp extends ConsumerWidget {
  const PartLinkhelp({super.key, required this.helpLink, this.helpPrompt});

  final String helpLink;
  final LangText? helpPrompt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (helpLink.isEmpty) return const SizedBox.shrink();
    final String lang = ref.watch(languageProvider);
    return Align(
      alignment: Alignment.center,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () async {
          final Uri? uri = Uri.tryParse(helpLink);
          if (uri == null) return;
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                ll(lang, helpPrompt ?? _kHelp),
                style: const TextStyle(fontSize: 13, color: PexColors.blueMy),
              ),
              PexIcon.uni('help', size: 18, color: PexColors.blueMy),
            ],
          ),
        ),
      ),
    );
  }
}
