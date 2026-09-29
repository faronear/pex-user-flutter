/// AI 模型 / Aibot 列表项（共享样式），供 Models / Shared / Picked 三个列表复用。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../data/ai_model.dart';

class AiModelTile extends ConsumerWidget {
  const AiModelTile({
    super.key,
    required this.model,
    this.selected = false,
    this.onTap,
    this.trailing,
  });

  final AiModel model;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final String note = model.ainote.resolve(lang).replaceAll('\n', '');
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? const Color(0xFFDBF1E1) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: ServerImage(
                  model.aiavatar,
                  fit: BoxFit.cover,
                  placeholder: const Icon(Icons.smart_toy_outlined, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    model.ainame.resolve(lang),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  if (note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF909399)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      model.aiprice.resolve(lang),
                      style: TextStyle(
                        fontSize: 16,
                        color: model.aiu2tuc <= 0
                            ? const Color(0xFFFA3534)
                            : const Color(0xFF303133),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        model.aiprovider.resolve(lang),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}

/// 列表上方的说明文字（源项目各列表的引导语）。
class AiListHeader extends StatelessWidget {
  const AiListHeader({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: Color(0xFF909399)),
      ),
    );
  }
}

/// 取模型主键（供列表 key 使用）。
String aiModelKey(AiModel model) => model.aicode.isNotEmpty ? model.aicode : model.ainame.enUS;

/// 供列表按时间格式化（复用 toolkit）。
String aiModelTime(AiModel model) => formatDate(model.createdTime);
