/// 空列表占位，对应源项目 `parts/partEmptyList.vue`：
/// 提示语 + 「刷新」按钮 + 「前往」按钮。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/appmeta/page_meta.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/state/app_providers.dart';
import '../core/icons/pex_icon.dart';
import '../theme/app_theme.dart';

const LangText kReload = LangText(zhCN: '刷新', enUS: 'Reload');

class PartEmptyList extends ConsumerStatefulWidget {
  const PartEmptyList({
    super.key,
    required this.prompt,
    this.aboveText,
    this.aboveIcon = '',
    this.aboveAction,
    this.belowText,
    this.belowIcon = '',
    this.belowAction,
  });

  /// 主要提示语。
  final LangText prompt;
  final LangText? aboveText;

  /// 「刷新」按钮图标（默认 `refresh`）。
  final String aboveIcon;
  final Future<void> Function()? aboveAction;

  /// 「前往」按钮文案（默认品牌名）与图标。
  final LangText? belowText;
  final String belowIcon;
  final VoidCallback? belowAction;

  @override
  ConsumerState<PartEmptyList> createState() => _PartEmptyListState();
}

class _PartEmptyListState extends ConsumerState<PartEmptyList> {
  bool _aboveLoading = false;
  bool _belowLoading = false;

  Future<void> _runAbove() async {
    if (widget.aboveAction == null) return;
    setState(() => _aboveLoading = true);
    await widget.aboveAction!();
    if (mounted) setState(() => _aboveLoading = false);
  }

  Future<void> _runBelow() async {
    if (widget.belowAction == null) return;
    setState(() => _belowLoading = true);
    widget.belowAction!();
    if (mounted) setState(() => _belowLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final String brandName = ref.watch(brandProvider).displayName.resolve(lang);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              widget.prompt.resolve(lang),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, height: 2),
            ),
          ),
          if (widget.aboveAction != null)
            TextButton(
              onPressed: _aboveLoading ? null : _runAbove,
              child: Column(
                children: <Widget>[
                  PexIcon.uni(
                    widget.aboveIcon.isEmpty ? 'refresh' : widget.aboveIcon,
                    size: 30,
                    color: PexColors.grey6,
                  ),
                  Text(
                    (widget.aboveText ?? kReload).resolve(lang),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          if (widget.belowAction != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(
                onPressed: _belowLoading ? null : _runBelow,
                style: FilledButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (widget.belowIcon.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: PexIcon.uni(widget.belowIcon, size: 22, color: Colors.white),
                      ),
                    Text(widget.belowText == null ? brandName : widget.belowText!.resolve(lang)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 仅供页面取用：某页面元数据里的图标类型。
String? pageIconTypeOf(String pageName) => pageMetaOf(pageName)?.gotoIconType;
