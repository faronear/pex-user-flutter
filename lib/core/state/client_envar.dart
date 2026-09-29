/// 本地预置配置（方案 E 第 1 层）。
///
/// 定位（老板 2026-09-29 澄清）：
/// 1. **客户端专属块**——服务端**永不**下发（源项目用 `inUniapp` 控制，服务端求值时恒为 false），
///    如 `tucSymbol` / `pactDict` / `Creation` / `Creator` / `Market` / 扩展名列表 / `banChina` / `mia*` 等；
/// 2. **首屏默认值**——首屏在 `first_touch` 返回前就已渲染，需要一份稳定默认值避免空白闪烁。
///
/// **不是**为了「离线可用」：连不上后端时会停在首屏 Connecting 等待。
///
/// 合并顺序：预置（本层）→ 后端 `first_touch.envarBase` 覆盖。
/// 因此若后端将来把某个块翻成"可下发"，它会自动覆盖本层，**前端无需改代码**。
///
/// 内容由 `tool/genClientEnvar.js` 从源项目 `envar-config.js` 生成，**请勿手工编辑**。
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String kClientEnvarAsset = 'assets/clientEnvar.json';

/// 按 appkey 分组的预置配置（在 `runPexApp` 中加载后注入）。
final Provider<Map<String, dynamic>> clientEnvarPresetProvider =
    Provider<Map<String, dynamic>>((ref) => const <String, dynamic>{});

/// 从资源加载预置配置，返回「当前 appkey 对应的那一份」。
Future<Map<String, dynamic>> loadClientEnvarPreset(String appkey) async {
  try {
    final String raw = await rootBundle.loadString(kClientEnvarAsset);
    final Map<String, dynamic> all =
        (jsonDecode(raw) as Map).cast<String, dynamic>();
    final Object? mine = all[appkey];
    return mine is Map ? mine.cast<String, dynamic>() : <String, dynamic>{};
  } catch (_) {
    return <String, dynamic>{};
  }
}
