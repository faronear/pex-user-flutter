/// 跨组件共用的文案（避免各处重复内联 `LangText`）。
library;

import '../core/i18n/lang_text.dart';

class PartTexts {
  const PartTexts._();

  static const LangText loading = LangText(
    zhCN: '加载中...',
    enUS: 'Loading...',
  );

  static const LangText back = LangText(zhCN: '返回', enUS: 'Back');

  static const LangText copied = LangText(zhCN: '已复制到剪贴板', enUS: 'Copied to clipboard');

  static const LangText cancel = LangText(
    zhCN: '取消',
    enUS: 'Cancel',
    jaJP: 'キャンセル',
    deDE: 'Abbrechen',
  );

  static const LangText forward = LangText(zhCN: '下一步', enUS: 'Next');

  static const LangText sendPasscode =
      LangText(zhCN: '获取验证码', enUS: 'Send passcode');

  static const LangText clockRemaining = LangText(
    zhCN: '剩余有效时间',
    enUS: 'Remaining Seconds',
    jaJP: '残りの時間',
    deDE: 'Verbleibende Sekunden',
  );

  static const LangText systemDown = LangText(
    zhCN: '系统出错了，请稍后再试，或请向客服投诉。',
    enUS: 'Something went wrong. Please try again later or report to customer service.',
    jaJP: 'エラーが発生しました。後でもう一度お試しいただくか、カスタマーサービスにお問い合わせください。',
  );

  static const LangText passcodeExpired = LangText(
    zhCN: '您的验证码已过期',
    enUS: 'Your passcode have expired',
    jaJP: 'アカウントの認証情報が期限切れです',
    deDE: 'Ihre Kontoüberprüfung ist abgelaufen',
  );

  static const LangText passcodeExpiredPlease = LangText(
    zhCN: '请重新验证！',
    enUS: 'Please verify again!',
    jaJP: 'アカウントを再度認証してください！',
    deDE: 'Bitte verifizieren Sie Ihr Konto erneut!',
  );
}
