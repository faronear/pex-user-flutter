/// 名单弹窗：关闭按钮 + 标题 + 用户名单 + 加载更多。
///
/// 对应源项目 `showCreation.vue` 里的四个 `uni-popup`（点赞者 / 赞赏者 / 解密者 / 持有者），
/// 它们的内容结构完全一致，故合并为一个可复用弹窗。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import 'part_close_button.dart';
import 'part_load_more.dart';
import 'part_texts.dart';
import 'part_user_list.dart';

/// 打开名单弹窗。[fetch] 返回后端响应，列表取自 [listKey]；
/// 传入 `null` 表示取首屏（源项目「打开即加载第一页」）。
Future<void> showUserListSheet(
  BuildContext context,
  WidgetRef ref, {
  required LangText title,
  required String listKey,
  String timeKey = '',
  String timeIcon = '',
  String timePrefix = '',
  int takeLimit = 10,
  required Future<Map<String, dynamic>> Function(int? beforeTime) fetch,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
    ),
    builder: (BuildContext context) => _UserListSheet(
      title: title,
      listKey: listKey,
      timeKey: timeKey,
      timeIcon: timeIcon,
      timePrefix: timePrefix,
      takeLimit: takeLimit,
      fetch: fetch,
    ),
  );
}

class _UserListSheet extends ConsumerStatefulWidget {
  const _UserListSheet({
    required this.title,
    required this.listKey,
    required this.timeKey,
    required this.timeIcon,
    required this.timePrefix,
    required this.takeLimit,
    required this.fetch,
  });

  final LangText title;
  final String listKey;
  final String timeKey;
  final String timeIcon;
  final String timePrefix;
  final int takeLimit;
  final Future<Map<String, dynamic>> Function(int? beforeTime) fetch;

  @override
  ConsumerState<_UserListSheet> createState() => _UserListSheetState();
}

class _UserListSheetState extends ConsumerState<_UserListSheet> {
  final List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  bool _busy = false;
  bool _firstLoaded = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  List<Map<String, dynamic>> _listOf(Map<String, dynamic> data) =>
      (data[widget.listKey] as List?)?.cast<Map<String, dynamic>>() ??
      <Map<String, dynamic>>[];

  Future<void> _loadMore() async {
    if (_busy) return;
    setState(() => _busy = true);
    final Map<String, dynamic> data = await widget.fetch(
      _users.isEmpty || widget.timeKey.isEmpty
          ? null
          : _intOf(_users.last[widget.timeKey]),
    );
    if (!mounted) return;

    if (!bok(data['_state']?.toString())) {
      setState(() {
        _busy = false;
        _firstLoaded = true;
      });
      final LangText message = LangText.fromMap(data['_msg']);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              ll(
                ref.read(languageProvider),
                message.isEmpty ? PartTexts.systemDown : message,
              ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final List<Map<String, dynamic>> list = _listOf(data);
    setState(() {
      _busy = false;
      _firstLoaded = true;
      _users.addAll(list);
      _done = list.length < widget.takeLimit;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        minWidth: 320,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PartCloseButton(onClose: () => Navigator.of(context).pop()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              ll(lang, widget.title),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (!_firstLoaded)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...<Widget>[
            Flexible(
              child: SingleChildScrollView(
                child: PartUserList(
                  userList: _users,
                  timeKey: widget.timeKey,
                  timeIcon: widget.timeIcon,
                  timePrefix: widget.timePrefix,
                ),
              ),
            ),
            PartLoadMore(
              loadState: _busy
                  ? LoadState.loading
                  : (_done ? LoadState.noMore : LoadState.loadUp),
              onLoad: _loadMore,
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

int _intOf(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
