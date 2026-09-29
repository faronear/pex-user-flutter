/// 验证码发送 + 校验的通用块，供「新用户注册验证」与「老用户重设密码验证」复用。
///
/// 对应源项目 `pages/identNewPasscode.vue` 与 `pages/identOldPasscode.vue` 的共同逻辑。
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/i18n/lang_text.dart';
import '../core/router/app_router.dart';
import '../core/state/app_providers.dart';
import '../core/state/envar_provider.dart';
import '../core/state/ident_provider.dart';
import '../core/util/feedback.dart';
import '../core/util/pex_toolkit.dart';
import 'part_button_passcode.dart';
import 'part_countdown.dart';
import 'part_feedback.dart';
import 'part_ident_commid.dart';
import 'part_passcode_input.dart';
import 'part_texts.dart';

const LangText _kUnknownUser = LangText(
  zhCN: '未知用户不能发送验证码！',
  enUS: 'Unknown users cannot send passcode!',
  jaJP: '不明なユーザーは認証コードを送信できません！',
);

const LangText _kPasscodeSent = LangText(
  zhCN: '验证码已成功发送，请尽快使用以免失效。',
  enUS: 'Passcode is sent, please use it as soon as possible.',
  jaJP: '認証コードが送信されました，すぐに使用してください。',
  deDE: 'Bestätigungscode wurde gesendet, bitte verwenden Sie ihn so schnell wie möglich.',
);

const LangText _kNeedPasscode = LangText(
  zhCN: '请先获取验证码！',
  enUS: 'Please get a passcode at first!',
  jaJP: '最初に認証コードを取得してください！',
);

const LangText _kBadPasscode = LangText(
  zhCN: '验证码格式错误。',
  enUS: 'Passcode is malformed.',
  jaJP: '認証コードの形式が正しくありません。',
);

const LangText _kExpiredPasscode = LangText(
  zhCN: '验证码已过期。',
  enUS: 'Passcode is expired.',
  jaJP: '認証コードの有効期限が切れています。',
);

const LangText _kMismatchPasscode = LangText(
  zhCN: '验证码不匹配。',
  enUS: 'Passcode is mismatched.',
  jaJP: '認証コードが一致しません。',
);

class PartPasscodeVerify extends ConsumerStatefulWidget {
  const PartPasscodeVerify({
    super.key,
    required this.passcodeType,
    required this.successRoute,
    this.extraWhat = const <String, dynamic>{},
  });

  /// `REGISTER`（新用户）或 `RESETPWD`（重设密码）。
  final String passcodeType;

  /// 校验通过后跳转的路由名。
  final String successRoute;

  /// 校验请求额外参数（如新用户的 `inviterHaid`）。
  final Map<String, dynamic> extraWhat;

  @override
  ConsumerState<PartPasscodeVerify> createState() => _PartPasscodeVerifyState();
}

class _PartPasscodeVerifyState extends ConsumerState<PartPasscodeVerify> {
  bool _sending = false;
  int _remainingSeconds = 0;
  Timer? _timer;

  String _passcode = '';
  String _passcodeHash = '';
  int _passcodeExpireAt = 0;

  LangText? _feedbackBad;
  LangText? _feedbackGood;
  LangText? _feedbackRemote;

  @override
  void initState() {
    super.initState();
    // 源项目在 onLoad 中延迟 100ms 自动发送。
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (mounted && ref.read(identProvider).commid.isNotEmpty) _sendPasscode();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _remainingSeconds = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendPasscode() async {
    setState(() {
      _passcode = '';
      _feedbackBad = null;
      _feedbackGood = null;
      _feedbackRemote = null;
    });

    final String commid = ref.read(identProvider).commid;
    if (ref.read(identProvider).usid.isEmpty) {
      setState(() => _feedbackBad = _kUnknownUser);
      return;
    }

    setState(() => _sending = true);
    final Map<String, dynamic> data = await ref.read(apiClientProvider).callBase(
          apiWho: 'User',
          apiTodo: 'send_passcode',
          apiWhat: <String, dynamic>{
            'passcodeType': widget.passcodeType,
            'commid': commid,
          },
        );
    if (!mounted) return;
    setState(() => _sending = false);

    _startCountdown(ref.read(envarProvider).waitingSeconds);

    if (data['_state']?.toString() == 'PASSCODE_SENT') {
      setState(() {
        _passcodeHash = data['passcodeHash']?.toString() ?? '';
        _passcodeExpireAt = int.tryParse('${data['passcodeExpireAt']}') ?? 0;
        _feedbackGood = data['_msg'] == null
            ? _kPasscodeSent
            : LangText.fromMap(data['_msg']);
      });
      // 开发环境后端直接下发验证码。
      if (!kReleaseMode && data['passcode'] != null) {
        showPexToast(
          context,
          ref,
          LangText(
            zhCN: '开发环境短信验证码：${data['passcode']}',
            enUS: 'Dev Passcode: ${data['passcode']}',
            jaJP: '開発環境SMS認証コード：${data['passcode']}',
          ),
          durationMs: 30000,
        );
      }
    } else {
      setState(() {
        _feedbackBad = data['_msg'] == null
            ? PartTexts.systemDown
            : LangText.fromMap(data['_msg']);
      });
    }
  }

  Future<void> _verify() async {
    final String commid = ref.read(identProvider).commid;
    final String usid = ref.read(identProvider).usid;

    if (_passcodeHash.isEmpty) {
      setState(() => _feedbackRemote = _kNeedPasscode);
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(_passcode)) {
      setState(() => _feedbackRemote = _kBadPasscode);
      return;
    }
    if (_passcodeExpireAt > 0 &&
        DateTime.now().millisecondsSinceEpoch > _passcodeExpireAt) {
      setState(() {
        _feedbackRemote = _kExpiredPasscode;
        _passcode = '';
        _passcodeHash = '';
        _passcodeExpireAt = 0;
      });
      return;
    }
    if (hashStable('$_passcode$commid$usid') != _passcodeHash) {
      setState(() {
        _feedbackRemote = _kMismatchPasscode;
        _passcode = '';
      });
      return;
    }

    setState(() => _feedbackRemote = null);
    final Map<String, dynamic> data = await ref.read(apiClientProvider).callBase(
          apiWho: 'User',
          apiTodo: 'verify_passcode',
          apiWhat: <String, dynamic>{
            'passcode': _passcode,
            ...widget.extraWhat,
          },
        );
    if (!mounted) return;

    if (bok(data['_state']?.toString())) {
      ref
          .read(identProvider.notifier)
          .setVerifyExpireAt(int.tryParse('${data['verifyExpireAt']}') ?? 0);
      context.push(AppRoutes.path(widget.successRoute));
    } else {
      setState(() {
        _feedbackRemote = data['_msg'] == null
            ? PartTexts.systemDown
            : LangText.fromMap(data['_msg']);
      });
    }
    // 无论成功失败，只要做了后台校验就清空验证码（对齐源项目注释）。
    setState(() {
      _passcode = '';
      _passcodeHash = '';
      _passcodeExpireAt = 0;
      _feedbackGood = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const PartIdentCommid(),
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Center(
            child: PartButtonPasscode(
              onPressed: _sendPasscode,
              loading: _sending,
              remainingSeconds: _remainingSeconds,
            ),
          ),
        ),
        PartFeedback(bad: _feedbackBad, good: _feedbackGood),
        const SizedBox(height: 16),
        PartPasscodeInput(
          value: _passcode,
          enabled: _passcodeHash.isNotEmpty,
          onChanged: (String value) => setState(() => _passcode = value),
          onFinish: _verify,
        ),
        PartFeedback(bad: _feedbackRemote),
        if (_feedbackGood != null) PartCountdown(expireAt: _passcodeExpireAt),
      ],
    );
  }
}
