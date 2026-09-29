/// 故事文本段渲染，对应源项目 `parts/partTextReader.vue`。
///
/// 若 `text` 为空但存在 `textIpfs`，则按 URL 拉取文本（对应源项目 `uni.request` + `dataType:'text'`）。
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/state/envar_provider.dart';
import '../core/util/server_url.dart';
import 'part_breathing_opacity.dart';

const LangText _kLoading = LangText(zhCN: '加载中...', enUS: 'Loading...');

const LangText _kFailed = LangText(zhCN: '加载失败。', enUS: 'Failed to load text.');

const LangText _kError = LangText(
  zhCN: '加载异常。',
  enUS: 'Exception happened at loading text',
);

class PartTextReader extends ConsumerStatefulWidget {
  const PartTextReader({super.key, required this.section});

  final Map<String, dynamic> section;

  @override
  ConsumerState<PartTextReader> createState() => _PartTextReaderState();
}

class _PartTextReaderState extends ConsumerState<PartTextReader> {
  static final Dio _dio = Dio();

  bool _loading = false;
  LangText? _warning;
  String _fetched = '';

  @override
  void initState() {
    super.initState();
    _fetchIfNeeded();
  }

  @override
  void didUpdateWidget(covariant PartTextReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section['textIpfs'] != widget.section['textIpfs']) {
      _fetched = '';
      _fetchIfNeeded();
    }
  }

  Future<void> _fetchIfNeeded() async {
    final String text = widget.section['text']?.toString() ?? '';
    final String textIpfs = widget.section['textIpfs']?.toString() ?? '';
    if (text.isNotEmpty || textIpfs.isEmpty) return;

    final String url = makeServerUrl(textIpfs, ref.read(envarProvider));
    setState(() {
      _loading = true;
      _warning = _kLoading;
    });
    try {
      final Response<String> response = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      if (!mounted) return;
      setState(() {
        if (response.statusCode == 200) {
          _fetched = response.data ?? '';
          _loading = false;
          _warning = null;
        } else {
          _warning = _kFailed;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _warning = _kError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    if (_loading) {
      return PartBreathingOpacity(
        isBreathing: true,
        child: Text(
          ll(lang, _warning ?? _kLoading),
          style: const TextStyle(fontSize: 14),
        ),
      );
    }
    final String text = _fetched.isNotEmpty
        ? _fetched
        : widget.section['text']?.toString() ?? '';
    final String autocontent = widget.section['_autocontent']?.toString() ?? '';
    final String shown = text.isNotEmpty ? text : autocontent;
    return SelectableText(
      shown,
      style: const TextStyle(fontSize: 15, height: 1.5),
    );
  }
}
