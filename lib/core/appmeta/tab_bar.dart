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
    this.iconTypeOn = '',
  });

  final String pageName;
  final LangText i18nText;

  /// 未选中图标（源项目 `tabBar.list[].iconfont.text` 的 `uniui-*` 名）。
  final String iconType;

  /// 选中图标（源项目 `selectedText`）。
  final String iconTypeOn;
}

const List<TabItem> kTabItems = <TabItem>[
  TabItem(
    pageName: 'menuAipp',
    i18nText: LangText(zhCN: '智能市场', enUS: 'Aibot Market', jaJP: 'Aibot マーケット'),
    iconType: 'calendar',
    iconTypeOn: 'calendar-filled',
  ),
  TabItem(
    pageName: 'menuUzone',
    i18nText: LangText(zhCN: '我的空间', enUS: 'My Zone', jaJP: 'マイゾーン'),
    iconType: 'person',
    iconTypeOn: 'person-filled',
  ),
];
