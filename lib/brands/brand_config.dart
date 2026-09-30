/// 品牌配置抽象。
///
/// 承载三品牌（Agidin / Babelyx / TRYAPP）的差异：[appkey]、域名、包名、
/// 应用名、主色、logo、落地页等。业务代码只读本配置，**不判 appkey**。
///
/// 对应源项目 `appenv.json` + `AK*/framework/App.theme.scss` + `envar-config.js`
/// 中的品牌专属字段。
library;

import 'package:flutter/material.dart';

import '../core/i18n/lang_text.dart';
import 'brand_features.dart';

abstract class BrandConfig {
  const BrandConfig();

  /// 品牌标识，如 `AKAGIDIN`（与后端 appkey 一致）。
  String get appkey;

  /// 文件/资源前缀，如 `agidin`（对应源项目 `filekey`）。
  String get filekey;

  /// 应用标识名（三品牌共用 `pex`，用于推导 API/链端口）。
  String get idname => 'pex';

  /// 主域名，如 `agidin.com`。
  String get webDomain;

  /// Cloudflare Pages 项目名。
  String get cfpWebapp;
  String get cfpWebstore;

  /// 面向用户的站点根，如 `https://agidin.com`。
  String get cacheWebapp;
  String get cacheWebstore;

  /// 应用显示名。
  LangText get displayName;

  /// 启动页/门户背景色。
  Color get mainColor;

  /// 全局浅灰背景（源项目 `--Grey3` 用于 Agidin 门户底色）。
  Color get portalBackgroundColor => const Color(0xFF303133);

  /// 应用 logo 资源。
  String get logoAsset;

  /// 门户背景图资源（运行时会被后端 envar 覆盖）。
  String get portalImageAsset;

  /// 「出发」后进入的落地页路由名（源项目 `pagesJson.appLandPage`）。
  String get appLandPage;

  /// 手机端 TabBar 中间按钮目标页路由名（源项目 `tabBar.midButton.midPage`）。
  String get midPage;

  /// 手机端 TabBar 中间按钮图标（源项目 `tabBar.midButton.iconType`）。
  String get midButtonIcon => 'chatboxes';

  /// 中间按钮选中态图标（`iconTypeOn`）。
  String get midButtonIconOn => 'chatboxes-filled';

  /// 中间按钮文案（`i18nText`）。
  LangText get midButtonText => const LangText(
        zhCN: '对话',
        enUS: 'Chat',
        jaJP: 'チャット',
        deDE: 'Chat',
      );

  /// 品牌功能开关（决定注册哪些业务域路由，配合入口级裁剪）。
  BrandFeatures get features;

  /// 是否在 PC 顶栏显示「我的选集/圈子」等创作类快捷入口
  /// （源项目按 `appkey !== 'AKAGIDIN'` 判断；此处改为品牌开关）。
  bool get showCreatorShortcuts => features.enableCreator || features.enableCreation;

  /// 应用内币种代码（源项目 `cryptocoinSet.TUC.coinCode`）。
  String get coinCode;

  /// 应用内币种名称。
  LangText get coinIname;

  /// 原生包名 / Bundle ID。
  String get androidAppId;
  String get iosBundleId;

  /// 选集统计色（源项目品牌主题 `--ColorCollect`；仅 Babelyx 定义，其余品牌沿用之）。
  Color get colorCollect => const Color(0xFF27C2F5);

  /// 圈子统计色（源项目品牌主题 `--ColorCircle`；仅 Babelyx 定义，其余品牌沿用之）。
  Color get colorCircle => const Color(0xFFFE00F1);
}
