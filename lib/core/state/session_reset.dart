/// 会话内缓存重置，对应源项目 vuex 的 `reset_all`（`App.data.js`）。
///
/// 源项目 `reset_all` 会重置：AI 对话、创作列表、创作者列表、交易流水、待编辑草稿。
/// 其中 **AI 对话与交易流水的页面尚未迁移**，等迁移时在此补上；
/// 这样「重启应用」（`menuUzone`）与「注销账号」（`umyAccountTerminate`）都不会漏。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'creation_draft_provider.dart';
import 'creation_provider.dart';
import 'creator_provider.dart';

/// 清空已迁移业务域的会话内缓存。
void resetSessionCaches(WidgetRef ref) {
  ref.invalidate(creationProvider);
  ref.invalidate(creatorProvider);
  ref.invalidate(creationDraftProvider);
}
