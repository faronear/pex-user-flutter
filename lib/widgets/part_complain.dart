/// 举报弹窗，对应源项目 `parts/partComplain.vue`：
/// 标题 + 理由输入（512 字）+ 取消/举报；提交 `User/report_complain`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/user_api.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/util/feedback.dart';
import '../core/util/online_guard.dart';
import '../theme/app_theme.dart';
import 'part_texts.dart';

const LangText _kTitle = LangText(
  zhCN: '投诉举报',
  enUS: 'Report Complaint',
  jaJP: '苦情を報告',
  deDE: 'Beschwerde melden',
);

const LangText _kReasonHint = LangText(
  zhCN: '请说明您的举报理由。提交成功后，服务团队将在24小时内进行处理。感谢您的举报！',
  enUS:
      'Enter the reason of your complaints and then submit. The service team will act on your report within 24 hours. Thank you for your report!',
);

const LangText _kReport = LangText(
  zhCN: '举报',
  enUS: 'Report',
  jaJP: '報告',
  deDE: 'Melden',
);

const LangText _kSubmitted = LangText(
  zhCN: '您的举报已成功提交',
  enUS: 'Your report has been submitted successfully',
  jaJP: '報告が正常に送信されました',
  deDE: 'Ihre Meldung wurde erfolgreich übermittelt',
);

const LangText _kFailed = LangText(
  zhCN: '举报提交失败，请稍后再试一次',
  enUS: 'Failed to submit report, please try again later',
  jaJP: '報告の送信に失敗しました。後でもう一度お試しください',
  deDE: 'Fehler beim Senden der Meldung. Bitte versuchen Sie es später erneut',
);

/// 打开举报弹窗。[reportTargetType] 如 `CREATION` / `USER`。
Future<void> showComplainSheet(
  BuildContext context,
  WidgetRef ref, {
  required String reportTargetId,
  required String reportTargetType,
  LangText? reportTitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
    ),
    builder: (BuildContext context) => _Complain(
      reportTargetId: reportTargetId,
      reportTargetType: reportTargetType,
      reportTitle: reportTitle,
    ),
  );
}

class _Complain extends ConsumerStatefulWidget {
  const _Complain({
    required this.reportTargetId,
    required this.reportTargetType,
    this.reportTitle,
  });

  final String reportTargetId;
  final String reportTargetType;
  final LangText? reportTitle;

  @override
  ConsumerState<_Complain> createState() => _ComplainState();
}

class _ComplainState extends ConsumerState<_Complain> {
  final TextEditingController _reason = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _empty => _reason.text.trim().isEmpty;

  Future<void> _submit() async {
    if (_empty || _loading) return;
    if (!await checkOnline(context, ref)) return;
    if (!mounted) return;
    setState(() => _loading = true);
    final Map<String, dynamic> data = await ref.read(userApiProvider).reportComplain(
          reportTargetId: widget.reportTargetId,
          reportTargetType: widget.reportTargetType,
          reportReason: _reason.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (bok(data['_state']?.toString())) {
      Navigator.of(context).pop();
      if (context.mounted) {
        await showPexModal(context, ref, title: _kSubmitted);
      }
      return;
    }
    final LangText message = LangText.fromMap(data['_msg']);
    await showPexModal(context, ref, title: message.isEmpty ? _kFailed : message);
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        minWidth: 320,
        maxWidth: 600,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: Text(
                ll(lang, widget.reportTitle ?? _kTitle),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
              child: TextField(
                controller: _reason,
                maxLines: 5,
                maxLength: 512,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: ll(lang, _kReasonHint),
                  hintStyle: const TextStyle(fontSize: 13, color: PexColors.greyA),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: PexColors.border),
                  ),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: PexColors.grey9,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(),
                      ),
                      icon: PexIcon.uni('closeempty', size: 20, color: Colors.white),
                      label: Text(ll(lang, PartTexts.cancel), style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: TextButton.icon(
                      onPressed: _empty || _loading ? null : _submit,
                      style: TextButton.styleFrom(
                        backgroundColor: PexColors.redMy,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: PexColors.redMy.withValues(alpha: 0.3),
                        shape: const RoundedRectangleBorder(),
                      ),
                      icon: PexIcon.uni('hand-down', size: 20, color: Colors.white),
                      label: Text(ll(lang, _kReport), style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
