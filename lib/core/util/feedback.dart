/// 统一的提示与弹窗，替代源项目的 `uni.showToast` / `uni.showModal` / `wo.tt.showModal`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/i18n.dart';
import '../i18n/lang_text.dart';

/// 轻提示（底部 SnackBar）。
void showPexToast(
  BuildContext context,
  WidgetRef ref,
  LangText title, {
  int durationMs = 2000,
}) {
  final String text = title.resolve(ref.read(languageProvider));
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(text),
      duration: Duration(milliseconds: durationMs),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// 模态提示框（对应 `uni.showModal`），返回是否点击了确认。
Future<bool> showPexModal(
  BuildContext context,
  WidgetRef ref, {
  LangText? title,
  LangText? content,
  LangText? confirmText,
  LangText? cancelText,
  bool showCancel = false,
}) async {
  final String lang = ref.read(languageProvider);
  String? resolve(LangText? text) => text?.resolve(lang);
  final bool? confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => AlertDialog(
      title: title == null ? null : Text(resolve(title)!),
      content: content == null ? null : Text(resolve(content)!),
      actions: <Widget>[
        if (showCancel)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              resolve(cancelText ?? const LangText(zhCN: '取消', enUS: 'Cancel'))!,
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            resolve(confirmText ?? const LangText(zhCN: '确定', enUS: 'OK'))!,
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
