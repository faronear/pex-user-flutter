/// 支付确认弹窗，对应源项目 `parts/partDeposit.vue` 的**付费确认**部分。
///
/// 源项目 `partDeposit` 有 1066 行，其中「选择充值渠道 / 钱包地址 / 法币渠道」属于
/// **资金域**（见 `projectPlan.md` 3C）；本组件只实现详情页付费所需的部分：
/// 标题、金额（赞赏可改）、说明、失败反馈、提交按钮、余额不足提示。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/i18n/phrases.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/router/app_routes.dart';
import '../core/state/envar_provider.dart';
import '../core/util/pex_toolkit.dart';
import '../theme/app_theme.dart';
import '../widgets/part_button_submit.dart';

const LangText _kTopUp = LangText(zhCN: '去充值', enUS: 'Top Up');

const LangText _kAmount = LangText(zhCN: '金额', enUS: 'Amount');

/// 弹出付费确认。[onSubmit] 返回 null 表示成功并自动关闭，否则返回失败原因展示在弹窗内。
Future<void> showPaySheet(
  BuildContext context,
  WidgetRef ref, {
  required LangText title,
  LangText? notes,
  required num amountInit,
  bool amountEditable = false,
  LangText? amountPrompt,
  PexGlyph? submitIcon,
  required LangText submitText,
  required Future<LangText?> Function(num amount) onSubmit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
    ),
    builder: (BuildContext context) => _PaySheet(
      title: title,
      notes: notes,
      amountInit: amountInit,
      amountEditable: amountEditable,
      amountPrompt: amountPrompt,
      submitIcon: submitIcon,
      submitText: submitText,
      onSubmit: onSubmit,
    ),
  );
}

class _PaySheet extends ConsumerStatefulWidget {
  const _PaySheet({
    required this.title,
    this.notes,
    required this.amountInit,
    required this.amountEditable,
    this.amountPrompt,
    this.submitIcon,
    required this.submitText,
    required this.onSubmit,
  });

  final LangText title;
  final LangText? notes;
  final num amountInit;
  final bool amountEditable;
  final LangText? amountPrompt;
  final PexGlyph? submitIcon;
  final LangText submitText;
  final Future<LangText?> Function(num amount) onSubmit;

  @override
  ConsumerState<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends ConsumerState<_PaySheet> {
  late final TextEditingController _amountController =
      TextEditingController(text: numberPrecision(widget.amountInit).toString());
  bool _submitting = false;
  LangText? _feedback;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  num get _amount => num.tryParse(_amountController.text.trim()) ?? 0;

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _feedback = null;
    });
    final LangText? error = await widget.onSubmit(_amount);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _feedback = error);
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final num balance = _numOf(ref.watch(onlineUserProvider)['balanceTUC']);
    final bool notEnough = balance < _amount;

    return Padding(
      padding: EdgeInsets.only(
        left: 15,
        right: 15,
        top: 15,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 15,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            ll(lang, widget.title),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (widget.notes != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                ll(lang, widget.notes!),
                style: const TextStyle(fontSize: 13, color: PexColors.grey6),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text('${ll(lang, _kAmount)} ', style: const TextStyle(fontSize: 14)),
              if (widget.amountEditable)
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: widget.amountPrompt == null
                          ? null
                          : ll(lang, widget.amountPrompt!),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                )
              else
                Text(
                  '${numberPrecision(widget.amountInit)}${envar.tucSymbol}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: notEnough ? PexColors.redMy : PexColors.grey3,
                  ),
                ),
            ],
          ),
          if (notEnough)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      ll(lang, Phrases.lowBalance),
                      style: const TextStyle(fontSize: 13, color: PexColors.redMy),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.path(AppRoutes.umyFund));
                    },
                    child: Text(ll(lang, _kTopUp)),
                  ),
                ],
              ),
            ),
          if (_feedback != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                ll(lang, _feedback!),
                style: const TextStyle(fontSize: 13, color: Color(0xFFDD6161)),
              ),
            ),
          const SizedBox(height: 15),
          PartButtonSubmit(
            loading: _submitting,
            onPressed: _submit,
            children: <Widget>[
              if (widget.submitIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: PexIcon(widget.submitIcon, size: 20, color: Colors.white),
                ),
              Text(ll(lang, widget.submitText)),
            ],
          ),
        ],
      ),
    );
  }
}

num _numOf(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
