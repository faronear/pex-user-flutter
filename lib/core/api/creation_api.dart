/// 创作域接口封装，对应源项目 `apiWho: 'Creation'` 的各个 apiTodo。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_providers.dart';
import 'api_client.dart';

/// 「我的收藏」的 5 种身份（对应源项目 `partCreationAs*` 与 `get_creations_as_*`）。
enum CreationRole {
  creator('creator', 'TCREATE'),
  owner('owner', 'TOWN'),
  holder('holder', 'THOLD'),
  viewer('viewer', 'TVIEW'),
  fueler('fueler', 'TFUEL');

  const CreationRole(this.apiRole, this.pactKey);

  /// `get_creations_as_<apiRole>` 的中间段。
  final String apiRole;

  /// 对应的 `pactDict` key（决定图标与文案）。
  final String pactKey;
}

class CreationApi {
  const CreationApi(this._client);

  final ApiClient _client;

  static const String who = 'Creation';

  /// 全部创作品（探索页）。
  Future<Map<String, dynamic>> getCreationList({int takeLimit = 12}) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_creation_list',
        apiWhat: <String, dynamic>{'takeLimit': takeLimit},
      );

  /// 按身份取「我的收藏」。[beforeTime] 为向下翻页游标（最后一条的 createTimeUnix）。
  Future<Map<String, dynamic>> getCreationsAs(
    CreationRole role, {
    int takeLimit = 12,
    int? beforeTime,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_creations_as_${role.apiRole}',
        apiWhat: <String, dynamic>{
          'takeLimit': takeLimit,
          'beforeTime': ?beforeTime,
        },
      );

  /// 取单个作品详情。入口可以是 `csid`（从列表跳转）或链接参数
  /// （`pexdataCidHash` / `nftToid` / `pexBaseCid` / `mintTxHash` / `unid`），
  /// 对应源项目 `showCreation.vue` 的 `onLoad` 两种分支。
  Future<Map<String, dynamic>> getSingleCreation({
    String? csid,
    String? pexdataCidHash,
    String? nftToid,
    String? pexBaseCid,
    String? mintTxHash,
    String? unid,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_single_creation',
        apiWhat: <String, dynamic>{
          'csid': ?_nonEmpty(csid),
          'pexdataCidHash': ?_nonEmpty(pexdataCidHash),
          'nftToid': ?_nonEmpty(nftToid),
          'pexBaseCid': ?_nonEmpty(pexBaseCid),
          'mintTxHash': ?_nonEmpty(mintTxHash),
          'unid': ?_nonEmpty(unid),
        },
      );

  /// 评论列表。[beforeTime] 为向下翻页游标（最后一条的 `commentTimeUnix`）。
  Future<Map<String, dynamic>> getCommentList({
    required String commentTarget,
    required String commentCsid,
    int? beforeTime,
    int takeLimit = 10,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_comment_list',
        apiWhat: <String, dynamic>{
          'commentTarget': commentTarget,
          'commentCsid': commentCsid,
          'beforeTime': ?beforeTime,
          'takeLimit': takeLimit,
        },
      );

  /// 发表评论（源项目 `to_comment_creation`）。
  Future<Map<String, dynamic>> commentCreation({
    required List<Map<String, dynamic>> commentStory,
    required String commentTarget,
    required String commentCsid,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'comment_creation',
        apiWhat: <String, dynamic>{
          'commentStory': commentStory,
          'commentTarget': commentTarget,
          'commentCsid': commentCsid,
        },
      );

  /// 删除自己的评论。
  Future<Map<String, dynamic>> deleteComment(String commentUuid) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'delete_comment',
        apiWhat: <String, dynamic>{'commentUuid': commentUuid},
      );
}

String? _nonEmpty(String? value) =>
    value == null || value.isEmpty ? null : value;

final Provider<CreationApi> creationApiProvider =
    Provider<CreationApi>((ref) => CreationApi(ref.watch(apiClientProvider)));
