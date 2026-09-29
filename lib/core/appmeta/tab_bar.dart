/// 底部/顶部标签栏配置，对应源项目 `pages.json` 的 `tabBar`。
///
/// `pages.json` 为分品牌生成；此处收录与品牌无关的部分，
/// 品牌相关的 `midButton`（图标/文案/落地页）放在 `BrandConfig`。
library;

import '../i18n/lang_text.dart';

class TabItem {
  const TabItem({
    required this.pageName,
    required this.i18nText,
    required this.iconType,
  });

  final String pageName;
  final LangText i18nText;
  final String iconType;
}

const List<TabItem> kTabItems = <TabItem>[
  TabItem(
    pageName: 'menuAipp',
    i18nText: LangText(zhCN: '智能市场', enUS: 'Aibot Market', jaJP: 'Aibot マーケット'),
    iconType: 'calendar',
  ),
  TabItem(
    pageName: 'menuUzone',
    i18nText: LangText(zhCN: '我的空间', enUS: 'My Zone', jaJP: 'マイゾーン'),
    iconType: 'person',
  ),
];
