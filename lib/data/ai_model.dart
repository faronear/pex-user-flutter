/// AI 模型 / Aibot 的统一视图，对应源项目 `wo.ss.aiModelSet[*]` 与 `wo.ss.AI.aintNow`。
library;

import '../core/i18n/lang_text.dart';

class AiModel {
  const AiModel(this.raw);

  final Map<String, dynamic> raw;

  static AiModel? of(Object? value) =>
      value is Map ? AiModel(value.cast<String, dynamic>()) : null;

  String get aicode => raw['aicode']?.toString() ?? '';

  /// 所属基础模型编码（Aibot 才有）。
  String get aicodeModel => raw['aicodeModel']?.toString() ?? '';

  LangText get ainame => LangText.fromMap(raw['ainame']);

  LangText get ainote => LangText.fromMap(raw['ainote']);

  LangText get aiprice => LangText.fromMap(raw['aiprice']);

  LangText get aiprovider =>
      LangText.fromMap(raw['aiprovider'] ?? const <String, String>{'zhCN': '基础模型', 'enUS': 'Base Model'});

  String get aiavatar => raw['aiavatar']?.toString() ?? '';

  bool get hiddenModel => raw['hiddenModel'] == true;

  bool get isTextChat => raw['AIT_TEXT_CHAT'] == true;

  bool get isImageChat => raw['AIT_IMAGE_CHAT'] == true;

  /// 收藏状态：`PICKED` / 其它（对应源项目 `pickState`）。
  String get pickState => raw['pickState']?.toString() ?? '';

  bool get isPicked => pickState == 'PICKED';

  num get aiu2tuc {
    final Object? value = raw['aiu2tuc'];
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? get createdTime {
    final Object? value = raw['createdTimeUnix'];
    if (value == null) return null;
    final int? ms = int.tryParse(value.toString());
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// 是否 Aibot（`asst_` 前缀），对应源项目 `/^asst_/` 判断。
  bool get isAibot => aicode.startsWith('asst_');
}
