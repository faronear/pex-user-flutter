/// 语言代码常量与多语言文本类型。
///
/// 对应源项目 `wo-core-i18n` 的 `langSet` 与 `wo.ll({ zhCN, enUS, jaJP, deDE })` 用法。
library;

/// 语言代码（与源项目保持一致，避免改名导致的外部引用不一致）。
class LangCode {
  const LangCode._();

  static const String enUS = 'enUS';
  static const String deDE = 'deDE';
  static const String jaJP = 'jaJP';
  static const String zhCN = 'zhCN';

  /// 界面语言选择器的顺序（源项目 App.data.js 的 mylang 初始为 enUS）。
  static const List<String> all = <String>[enUS, deDE, jaJP, zhCN];

  static bool isSupported(String code) => all.contains(code);
}

/// 多语言文本：等价于源项目内联的 `{ zhCN: '...', enUS: '...', jaJP: '...', deDE: '...' }`。
///
/// 用法：`const LangText(zhCN: '出发', enUS: 'Start', jaJP: '出発')`，
/// 通过 [ll] 或 `context.ll(...)` 按当前语言取出字符串。
class LangText {
  const LangText({
    required this.zhCN,
    required this.enUS,
    this.jaJP = '',
    this.deDE = '',
  });

  /// 便捷构造：单语言（只有一种文案时）。
  const LangText.from(String text)
      : zhCN = text,
        enUS = text,
        jaJP = text,
        deDE = text;

  /// 从后端下发的对象构造，如 `{ zhCN: '...', enUS: '...' }`。
  /// 非法输入返回空文本。
  factory LangText.fromMap(Object? value) {
    if (value is LangText) return value;
    if (value is String) return LangText.from(value);
    if (value is Map) {
      String pick(String key) => value[key]?.toString() ?? '';
      return LangText(
        zhCN: pick('zhCN'),
        enUS: pick('enUS'),
        jaJP: pick('jaJP'),
        deDE: pick('deDE'),
      );
    }
    return const LangText(zhCN: '', enUS: '');
  }

  final String zhCN;
  final String enUS;
  final String jaJP;
  final String deDE;

  /// 按语言代码取文本；缺失时回退到英文，再回退到中文。
  String resolve(String langCode) {
    final String value = switch (langCode) {
      LangCode.zhCN => zhCN,
      LangCode.jaJP => jaJP,
      LangCode.deDE => deDE,
      _ => enUS,
    };
    if (value.isNotEmpty) return value;
    if (enUS.isNotEmpty) return enUS;
    return zhCN;
  }

  bool get isEmpty => zhCN.isEmpty && enUS.isEmpty && jaJP.isEmpty && deDE.isEmpty;

  @override
  String toString() => enUS.isNotEmpty ? enUS : zhCN;
}
