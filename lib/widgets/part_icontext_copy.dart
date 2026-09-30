/// 复制按钮，对应源项目 `parts/partIcontextCopy.vue`。
///
/// 图标取自源项目 `wo.ss.iconCopy`（客户端常量，定义在源项目 `App.data.js`，未进配置下发）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/util/feedback.dart';
import '../theme/app_theme.dart';
import 'part_texts.dart';

const LangText _kCopy = LangText(zhCN: '拷贝', enUS: 'Copy');

/// `wo.ss.iconCopy` = `{ type: 'icont-copy-text-line', prefix: 'icont' }`。
PexGlyph? iconCopyGlyph() => PexIcons.icont('icont-copy-text-line');

/// `wo.ss.iconPop` = `{ type: 'icont-social-line', prefix: 'icont' }`。
PexGlyph? iconPopGlyph() => PexIcons.icont('icont-social-line');

class PartIcontextCopy extends ConsumerWidget {
  const PartIcontextCopy({super.key, required this.onCopy, this.label});

  final Future<void> Function() onCopy;
  final LangText? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _IconTextButton(
      glyph: iconCopyGlyph(),
      label: label ?? _kCopy,
      onTap: () async {
        await onCopy();
        if (context.mounted) {
          showPexToast(context, ref, PartTexts.copied);
        }
      },
    );
  }
}

/// 分享按钮（打开分享弹窗），对应源项目 `parts/partIcontextPop.vue`。
class PartIcontextPop extends StatelessWidget {
  const PartIcontextPop({super.key, required this.onPop, this.label});

  final VoidCallback onPop;
  final LangText? label;

  @override
  Widget build(BuildContext context) {
    return _IconTextButton(
      glyph: iconPopGlyph(),
      label: label ?? const LangText(zhCN: '分享', enUS: 'Share'),
      onTap: onPop,
    );
  }
}

/// 源项目 `wocFlex column center alignCenter`：40×40 的图标 + 10px 文字。
class _IconTextButton extends ConsumerWidget {
  const _IconTextButton({
    required this.glyph,
    required this.label,
    required this.onTap,
  });

  final PexGlyph? glyph;
  final LangText label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PexIcon(glyph, size: 22, color: PexColors.grey6),
            FittedBox(
              child: Text(
                ll(lang, label),
                style: const TextStyle(fontSize: 10, height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
