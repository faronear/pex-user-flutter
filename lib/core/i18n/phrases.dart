/// 跨模块共用的词条（对应源项目中散落的通用文案）。
///
/// 页面/组件专属词条就近定义在各自文件里，与源项目同构；此处只放多处复用的。
library;

import 'lang_text.dart';

class Phrases {
  const Phrases._();

  static const LangText connect = LangText(
    zhCN: '连接中... ',
    enUS: 'Connecting... ',
    jaJP: '接続中... ',
  );

  static const LangText loginToContinue = LangText(
    zhCN: '请先登录，即可解锁功能',
    enUS: 'Login to Continue',
    jaJP: '続行するにはログインしてください',
    deDE: 'Bitte anmelden, um fortzufahren',
  );

  static const LangText signupOrLogin = LangText(
    zhCN: '登录',
    enUS: 'Signup or Login',
    jaJP: '登録',
    deDE: 'Anmelden',
  );

  static const LangText somethingWentWrong = LangText(
    zhCN: '系统出错了，请稍后再试，或请向客服投诉。',
    enUS: 'Something went wrong. Please try again later or report to customer service.',
    jaJP: 'エラーが発生しました。後でもう一度お試しいただくか、カスタマーサービスにお問い合わせください。',
  );

  static const LangText lowBalance = LangText(
    zhCN: '余额不足，请先充值',
    enUS: 'Top up your balance',
    jaJP: '残高が不足しています。チャージしてください。',
  );
}
