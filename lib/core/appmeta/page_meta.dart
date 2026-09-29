// 由 pex-user-uniapp/pages.json 生成，请勿手工编辑。
// 注意：pages.json 是分品牌生成的（appLogo/appLandPage/midPage 随品牌变化），
// 本文件只收录与品牌无关的页面元数据。
// ignore_for_file: constant_identifier_names

import '../i18n/lang_text.dart';

/// 页面元数据（源项目 `wo.pageSet[pageName]`）。
class PageMeta {
  const PageMeta({this.i18nPageTitle, this.i18nGotoTitle, this.i18nListTitle, this.gotoIconType, this.gotoIconPrefix = '', this.navigationStyle});

  final LangText? i18nPageTitle;
  final LangText? i18nGotoTitle;
  final LangText? i18nListTitle;
  final String? gotoIconType;
  final String gotoIconPrefix;
  /// `custom` 表示全屏无系统导航栏。
  final String? navigationStyle;
}

LangText? _lt(Object? v) {
  if (v is Map) {
    return LangText(zhCN: (v['zhCN'] ?? '').toString(), enUS: (v['enUS'] ?? '').toString(), jaJP: (v['jaJP'] ?? '').toString(), deDE: (v['deDE'] ?? '').toString());
  }
  return null;
}

/// 页面名（不含 `pages/` 前缀）→ 元数据。
final Map<String, PageMeta> kPageSet = <String, PageMeta>{
  'homePortal': PageMeta(navigationStyle: 'custom'),
  'identBegin': PageMeta(),
  'identOldLogin': PageMeta(),
  'identOldPasscode': PageMeta(),
  'identOldReset': PageMeta(),
  'identNewPasscode': PageMeta(),
  'identNewRegcode': PageMeta(),
  'identNewRegister': PageMeta(),
  'showWebview': PageMeta(),
  'midAgidin': PageMeta(i18nPageTitle: _lt({"zhCN":"AI对话","enUS":"AI Chat","deDE":"KI-Chat","jaJP":"AIチャット"}), navigationStyle: 'custom'),
  'midAizoic': PageMeta(navigationStyle: 'custom'),
  'menuAipp': PageMeta(i18nPageTitle: _lt({"zhCN":"智能市场","enUS":"Aibot Market","deDE":"Aibot Markt","jaJP":"Aibot マーケット"}), navigationStyle: 'custom'),
  'menuAippAichat': PageMeta(i18nPageTitle: _lt({"zhCN":"AI对话","enUS":"AI Chat","deDE":"KI-Chat","jaJP":"AIチャット"})),
  'menuAippCreate': PageMeta(i18nPageTitle: _lt({"zhCN":"创建 Aibot","enUS":"Create Aibot","deDE":"Aibot erstellen","jaJP":"Aibot 作成"})),
  'menuAippModify': PageMeta(i18nPageTitle: _lt({"zhCN":"修改 Aibot","enUS":"Modify Aibot","deDE":"Aibot bearbeiten","jaJP":"Aibot 修正"})),
  'menuUzone': PageMeta(i18nPageTitle: _lt({"zhCN":"我的空间","enUS":"My Zone","deDE":"Mein Bereich","jaJP":"マイゾーン"}), navigationStyle: 'custom'),
  'umyAccount': PageMeta(i18nPageTitle: _lt({"zhCN":"我的账号","enUS":"My Account","deDE":"Mein Konto","jaJP":"マイアカウント"}), i18nGotoTitle: _lt({"zhCN":"我的账号","enUS":"My Account","deDE":"Mein Konto","jaJP":"マイアカウント"}), i18nListTitle: _lt({"zhCN":"账号","enUS":"Account","deDE":"Konto","jaJP":"アカウント"})),
  'umyAccountPassword': PageMeta(i18nPageTitle: _lt({"zhCN":"修改密码","enUS":"Change Password","deDE":"Passwort Ändern","jaJP":"パスワードを変更する"})),
  'umyAccountCommid': PageMeta(),
  'umyAccountCommidNew': PageMeta(),
  'umyAccountTerminate': PageMeta(i18nPageTitle: _lt({"zhCN":"销毁我的账号","enUS":"Terminate My Account","deDE":"Mein Konto Löschen","jaJP":"アカウントを削除する"}), i18nListTitle: _lt({"zhCN":"销毁","enUS":"Terminate","deDE":"Löschen","jaJP":"削除"})),
  'umyFund': PageMeta(i18nPageTitle: _lt({"zhCN":"我的资金","enUS":"My Funds","deDE":"Meine Finanzen","jaJP":"マイ資金"}), i18nGotoTitle: _lt({"zhCN":"我的资金","enUS":"My Funds","deDE":"Meine Finanzen","jaJP":"マイ資金"}), i18nListTitle: _lt({"zhCN":"资金","enUS":"Funds","deDE":"Finanzen","jaJP":"資金"}), gotoIconType: 'icont-coins', gotoIconPrefix: 'icont'),
  'umyFundTranx': PageMeta(),
  'umyFundChannel': PageMeta(i18nPageTitle: _lt({"zhCN":"提现渠道","enUS":"Cashout Channels","deDE":"Auszahlungswege","jaJP":"出金ルート"})),
  'umyFundChannelCreate': PageMeta(i18nPageTitle: _lt({"zhCN":"新建提现渠道","enUS":"New Cashout Channel","deDE":"Neuer Auszahlungsweg","jaJP":"新規出金チャネル"}), i18nGotoTitle: _lt({"zhCN":"新建","enUS":"New","deDE":"Neu","jaJP":"新規"})),
  'umyFundChannelWithdraw': PageMeta(i18nPageTitle: _lt({"zhCN":"申请提现","enUS":"Request Cashout","deDE":"Auszahlung beantragen","jaJP":"出金を申し込む"})),
  'umyMia': PageMeta(i18nPageTitle: _lt({"zhCN":"我的消息","enUS":"My Messages","deDE":"Meine Nachrichten","jaJP":"マイメッセージ"}), i18nGotoTitle: _lt({"zhCN":"我的消息","enUS":"My Messages","deDE":"Meine Nachrichten","jaJP":"マイメッセージ"}), i18nListTitle: _lt({"zhCN":"消息","enUS":"Messages","deDE":"Nachrichten","jaJP":"メッセージ"}), gotoIconType: 'chat'),
  'umyMiaDetail': PageMeta(i18nPageTitle: _lt({"zhCN":"阅读消息","enUS":"Read Message","deDE":"Nachricht Lesen","jaJP":"メッセージを読む"})),
  'umyConfig': PageMeta(i18nPageTitle: _lt({"zhCN":"我的设置","enUS":"My Settings","deDE":"Meine Einstellungen","jaJP":"設定"}), i18nGotoTitle: _lt({"zhCN":"我的设置","enUS":"My Settings","deDE":"Meine Einstellungen","jaJP":"設定"}), i18nListTitle: _lt({"zhCN":"设置","enUS":"Settings","deDE":"Einstellungen","jaJP":"設定"})),
  'umyKyc': PageMeta(i18nPageTitle: _lt({"zhCN":"我的实名","enUS":"My Identity","deDE":"Meine Identität","jaJP":"本人確認"}), i18nGotoTitle: _lt({"zhCN":"我的实名","enUS":"My Identity","deDE":"Meine Identität","jaJP":"本人確認"}), i18nListTitle: _lt({"zhCN":"实名","enUS":"Identity","deDE":"Identität","jaJP":"本人確認"})),
  'umyInvite': PageMeta(i18nPageTitle: _lt({"zhCN":"邀请朋友","enUS":"Invite Friends","deDE":"Freunde einladen","jaJP":"友達紹介"}), i18nListTitle: _lt({"zhCN":"邀请","enUS":"Invites","deDE":"Einladen","jaJP":"紹介"})),
  'umyInviteList': PageMeta(i18nPageTitle: _lt({"zhCN":"我邀请的朋友","enUS":"My Invitees","deDE":"Meine Eingeladenen","jaJP":"紹介した友達"})),
  'umyContact': PageMeta(i18nPageTitle: _lt({"zhCN":"联系客服","enUS":"Customer Service","deDE":"Kundendienst","jaJP":"カスタマーサービス"}), i18nGotoTitle: _lt({"zhCN":"联系我们","enUS":"Contact Us","deDE":"Kontaktieren","jaJP":"お問い合わせ"}), i18nListTitle: _lt({"zhCN":"客服","enUS":"Customer Service","deDE":"Kundendienst","jaJP":"カスタマーサービス"}), gotoIconType: 'icont-headphone-fill', gotoIconPrefix: 'icont'),
  'userResource': PageMeta(i18nPageTitle: _lt({"zhCN":"更多资源","enUS":"Links","deDE":"Links","jaJP":"リソースリンク"}), i18nListTitle: _lt({"zhCN":"更多资源","enUS":"Links","deDE":"Links","jaJP":"リンク"})),
  'userResourceDetail': PageMeta(),
};

PageMeta? pageMetaOf(String pageName) => kPageSet[pageName];
