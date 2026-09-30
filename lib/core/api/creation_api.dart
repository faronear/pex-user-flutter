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

  /// 付费解密（源项目 `to_pay_to_view`）。成功时返回 `pexdataUser`。
  Future<Map<String, dynamic>> payToView(String csid) => _client.callBase(
        apiWho: who,
        apiTodo: 'pay_to_view',
        apiWhat: <String, dynamic>{'viewCsid': csid},
      );

  /// 付费持有（源项目 `to_pay_to_hold`）。
  Future<Map<String, dynamic>> payToHold(String csid) => _client.callBase(
        apiWho: who,
        apiTodo: 'pay_to_hold',
        apiWhat: <String, dynamic>{'holdCsid': csid},
      );

  /// 付费收购（源项目 `to_pay_to_own`）。
  Future<Map<String, dynamic>> payToOwn(String csid) => _client.callBase(
        apiWho: who,
        apiTodo: 'pay_to_own',
        apiWhat: <String, dynamic>{'ownCsid': csid},
      );

  /// 赞赏（源项目 `to_fuel_creation`）。
  Future<Map<String, dynamic>> payToFuel({
    required String csid,
    required num amount,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'pay_to_fuel',
        apiWhat: <String, dynamic>{'fuelCsid': csid, 'priceToFuel': amount},
      );

  /// 重新上架（源项目 `to_list_creation`）。
  Future<Map<String, dynamic>> listCreation(String csid) => _client.callBase(
        apiWho: who,
        apiTodo: 'list_creation',
        apiWhat: <String, dynamic>{'listCsid': csid},
      );

  /// 下架（源项目 `to_unlist_creation`）。
  Future<Map<String, dynamic>> unlistCreation(String csid) => _client.callBase(
        apiWho: who,
        apiTodo: 'unlist_creation',
        apiWhat: <String, dynamic>{'unlistCsid': csid},
      );

  /// 隐藏（仅对自己生效，源项目 `to_hide_creation`）。
  Future<Map<String, dynamic>> hideCreation({
    required String csid,
    required String hideTarget,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'hide_creation',
        apiWhat: <String, dynamic>{'hideTarget': hideTarget, 'hideCsid': csid},
      );

  /// 取消隐藏（源项目 `to_unhide_creation`）。
  Future<Map<String, dynamic>> unhideCreation({
    required String csid,
    required String hideTarget,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'unhide_creation',
        apiWhat: <String, dynamic>{'hideTarget': hideTarget, 'hideCsid': csid},
      );

  /// 从「已隐藏」里彻底删除（源项目 `to_delete_creation_from_hide`）。
  Future<Map<String, dynamic>> deleteCreationFromHide({
    required String csid,
    required String hideTarget,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'delete_creation_from_hide',
        apiWhat: <String, dynamic>{'hideTarget': hideTarget, 'hideCsid': csid},
      );

  /// 从「已下架」里彻底删除（源项目 `to_delete_creation_from_remove`）。
  Future<Map<String, dynamic>> deleteCreationFromRemove(String csid) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'delete_creation_from_remove',
        apiWhat: <String, dynamic>{'delCsid': csid},
      );

  /// 解密者名单。[beforeTime] 为向下翻页游标。
  Future<Map<String, dynamic>> getViewerList({
    required String csid,
    int? beforeTime,
    int takeLimit = 10,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_viewer_list',
        apiWhat: <String, dynamic>{
          'viewCsid': csid,
          'beforeTime': ?beforeTime,
          'takeLimit': takeLimit,
        },
      );

  /// 持有者名单。
  Future<Map<String, dynamic>> getHolderList({
    required String csid,
    int? beforeTime,
    int takeLimit = 10,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_holder_list',
        apiWhat: <String, dynamic>{
          'holdCsid': csid,
          'beforeTime': ?beforeTime,
          'takeLimit': takeLimit,
        },
      );

  /// 赞赏者名单。
  Future<Map<String, dynamic>> getFuelerList({
    required String csid,
    int? beforeTime,
    int takeLimit = 10,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_fueler_list',
        apiWhat: <String, dynamic>{
          'fuelCsid': csid,
          'beforeTime': ?beforeTime,
          'takeLimit': takeLimit,
        },
      );

  /// 点赞者名单。
  Future<Map<String, dynamic>> getLikerList({
    required String csid,
    int? beforeTime,
    int takeLimit = 10,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_liker_list',
        apiWhat: <String, dynamic>{
          'likeCsid': csid,
          'beforeTime': ?beforeTime,
          'takeLimit': takeLimit,
        },
      );
}

String? _nonEmpty(String? value) =>
    value == null || value.isEmpty ? null : value;

final Provider<CreationApi> creationApiProvider =
    Provider<CreationApi>((ref) => CreationApi(ref.watch(apiClientProvider)));
