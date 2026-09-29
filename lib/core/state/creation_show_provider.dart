/// 详情页（`showCreation`）状态，对应源项目全局的 `wo.ss.Creation.ctnShow`。
///
/// 源项目把它放在 Vuex 全局 store 里，因此从列表页进入时可直接复用已有数据；
/// 这里改为显式 Provider，页面进入时按 `csid` 或链接参数取回单件作品。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/creation.dart';
import '../api/api_client.dart';
import '../api/creation_api.dart';

class CreationShowState {
  const CreationShowState({
    this.raw = const <String, dynamic>{},
    this.commentList = const <Map<String, dynamic>>[],
    this.readyShow = false,
    this.loading = false,
    this.failed = false,
  });

  /// 单件作品原始对象（源项目 `wo.ss.Creation.ctnShow`）。
  final Map<String, dynamic> raw;

  /// 首屏评论（源项目 `commentList`，由 `get_single_creation` 一并返回）。
  final List<Map<String, dynamic>> commentList;

  /// 是否已结束首屏加载（源项目 `readyShow`）——加载完成前显示占位。
  final bool readyShow;

  final bool loading;

  /// 接口调用是否失败（此时 [raw] 为空，页面会显示「未找到」）。
  final bool failed;

  Creation get creation => Creation(raw);

  /// 是否取到了目标作品。
  bool get found => creation.csid.isNotEmpty;
}

class CreationShowNotifier extends Notifier<CreationShowState> {
  @override
  CreationShowState build() => const CreationShowState();

  /// 对应源项目 `onLoad`：按作品编号或外链参数取回单件作品。
  Future<void> load({
    String? csid,
    String? pexdataCidHash,
    String? nftToid,
    String? pexBaseCid,
    String? mintTxHash,
    String? unid,
  }) async {
    state = const CreationShowState(loading: true);

    final Map<String, dynamic> data =
        await ref.read(creationApiProvider).getSingleCreation(
              csid: csid,
              pexdataCidHash: pexdataCidHash,
              nftToid: nftToid,
              pexBaseCid: pexBaseCid,
              mintTxHash: mintTxHash,
              unid: unid,
            );

    if (bok(data['_state']?.toString())) {
      final Map<String, dynamic> creation =
          (data['creation'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      final List<Map<String, dynamic>> comments =
          (data['commentList'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];
      state = CreationShowState(
        raw: creation,
        commentList: comments,
        readyShow: true,
      );
      return;
    }

    // 失败时也进入显示模式（与源项目一致，页面展示「未找到」）。
    state = const CreationShowState(readyShow: true, failed: true);
  }

  /// 局部更新当前作品（如点赞、隐藏后回写状态）。
  void merge(Map<String, dynamic> patch) {
    state = CreationShowState(
      raw: <String, dynamic>{...state.raw, ...patch},
      commentList: state.commentList,
      readyShow: state.readyShow,
      loading: state.loading,
      failed: state.failed,
    );
  }

  void clear() => state = const CreationShowState();
}

final NotifierProvider<CreationShowNotifier, CreationShowState>
    creationShowProvider =
    NotifierProvider<CreationShowNotifier, CreationShowState>(
        CreationShowNotifier.new);
