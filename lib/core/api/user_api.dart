/// 账户域接口封装，对应源项目 `apiWho: 'User'` 中迁移期用到的部分。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_providers.dart';
import 'api_client.dart';

class UserApi {
  const UserApi(this._client);

  final ApiClient _client;

  static const String who = 'User';

  /// 提交举报（源项目 `partComplain.vue` 的 `to_send_complain`）。
  /// [reportTargetType] 如 `CREATION` / `USER`。
  Future<Map<String, dynamic>> reportComplain({
    required String reportTargetId,
    required String reportTargetType,
    required String reportReason,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'report_complain',
        apiWhat: <String, dynamic>{
          'reportTargetId': reportTargetId,
          'reportTargetType': reportTargetType,
          'reportReason': reportReason,
        },
      );

  /// 更换头像（源项目 `menuUzone.vue` 的 `to_update_portrait`）。
  /// [portrait] 为上传后 `chooseUrl` 得到的地址。
  Future<Map<String, dynamic>> updatePortrait(String portrait) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'update_portrait',
        apiWhat: <String, dynamic>{
          'User': <String, dynamic>{'portrait': portrait},
        },
      );

  /// 修改昵称（源项目 `to_update_nickname`）。
  Future<Map<String, dynamic>> updateNickname(String nickname) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'update_nickname',
        apiWhat: <String, dynamic>{'nickname': nickname},
      );

  /// 更新自我介绍（源项目 `to_update_aboutme`；story 数组，已过滤空段落）。
  Future<Map<String, dynamic>> updateAboutme(List<dynamic> aboutme) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'update_aboutme',
        apiWhat: <String, dynamic>{'aboutme': aboutme},
      );

  /// 退出登录（源项目 `to_logout`；服务端注销 socket 并换发一个已登出的凭据）。
  Future<Map<String, dynamic>> logoutUser() =>
      _client.callBase(apiWho: who, apiTodo: 'logout_user');

  /// 修改密码（源项目 `umyAccountPassword` 的 `to_change_password`）。
  /// 两个密码都需先用 `hashStable(密码 + usid)` 处理。
  Future<Map<String, dynamic>> changePassword({
    required String passwordClient,
    required String passwordNewClient,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'changePassword',
        apiWhat: <String, dynamic>{
          'passwordClient': passwordClient,
          'passwordNewClient': passwordNewClient,
        },
      );

  /// 注销账号（源项目 `umyAccountTerminate` 的 `to_terminate_account`）。
  /// 后端只写入 `terminateTimeUnix`，7 天后真正清空；期内重新登录即取消。
  Future<Map<String, dynamic>> terminateAccount({
    required String passwordClient,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'terminate_account',
        apiWhat: <String, dynamic>{'passwordClient': passwordClient},
      );

  /// 发送验证码（源项目 `send_passcode`）。[passcodeType] 见后端注释：
  /// `REGISTER` / `RESETPWD` / `CHECK_OLD`（验证当前账号）/ `CHECK_NEW`（验证新账号）。
  Future<Map<String, dynamic>> sendPasscode({
    required String passcodeType,
    required String commid,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'send_passcode',
        apiWhat: <String, dynamic>{
          'passcodeType': passcodeType,
          'commid': commid,
        },
      );

  /// 校验验证码（源项目 `verify_passcode`）。
  Future<Map<String, dynamic>> verifyPasscode({required String passcode}) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'verify_passcode',
        apiWhat: <String, dynamic>{'passcode': passcode},
      );

  /// 新建提现渠道（源项目 `umyFundChannelCreate` 的 `add_payto_channel`）。
  ///
  /// 成功后返回 `channelUuid`（其余字段是后端补的 createdAt / appkey）。
  Future<Map<String, dynamic>> addPaytoChannel(
          Map<String, dynamic> channel) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'add_payto_channel',
        apiWhat: <String, dynamic>{'channel': channel},
      );

  /// 删除提现渠道（源项目 `partFundChannelCard` 的 `delete_payto_channel`）。
  ///
  /// 后端是把 `lifeState` 置为 `DELETED`，并把整份 `paytoChannels` 回传。
  Future<Map<String, dynamic>> deletePaytoChannel(String channelUuid) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'delete_payto_channel',
        apiWhat: <String, dynamic>{'channelUuid': channelUuid},
      );

  /// 申请提现（源项目 `umyFundChannelWithdraw` 的 `request_withdrawal`）。
  Future<Map<String, dynamic>> requestWithdrawal({
    required num withdrawAmount,
    required String channelUuid,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'request_withdrawal',
        apiWhat: <String, dynamic>{
          'withdrawAmount': withdrawAmount,
          'channelUuid': channelUuid,
        },
      );

  /// 查询当前余额（源项目 `partDeposit.vue` 的 `to_refresh_balance`）。
  Future<Map<String, dynamic>> getCurrentBalance({String coin = ''}) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_current_balance',
        apiWhat: <String, dynamic>{'coin': ?coin.isEmpty ? null : coin},
      );

  /// 我的收支明细（源项目 `partTxList.vue` 的 `get_tx_list`）。
  ///
  /// [txTag] 如 `TXG_ALL` / `TXG_RECHARGE` / `TXG_IN_REWARD` / `TXG_IN_PEX` / `TXG_OUT_PEX`；
  /// [beforeTime] 为向下翻页游标，取上一页最后一条的 `txTimeUnix`。
  Future<Map<String, dynamic>> getTxList({
    String txTag = 'TXG_ALL',
    int takeLimit = 10,
    int? beforeTime,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_tx_list',
        apiWhat: <String, dynamic>{
          'txTag': txTag,
          'takeLimit': takeLimit,
          'beforeTime': ?beforeTime,
        },
      );

  /// 关注某人（源项目 `toggle_follow_state` 的关注分支）。
  Future<Map<String, dynamic>> followUser(String followToUsid) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'follow_user',
        apiWhat: <String, dynamic>{'followToUsid': followToUsid},
      );

  /// 取消关注（源项目 `toggle_follow_state` 的取消分支）。
  Future<Map<String, dynamic>> unfollowUser(String followToUsid) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'unfollow_user',
        apiWhat: <String, dynamic>{'followToUsid': followToUsid},
      );

  /// 屏蔽某人（源项目 `to_block_user`）。
  Future<Map<String, dynamic>> blockUser(String blockToUsid) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'block_user',
        apiWhat: <String, dynamic>{'blockToUsid': blockToUsid},
      );

  /// 解除屏蔽（源项目 `to_unblock_user`）。
  Future<Map<String, dynamic>> unblockUser(String blockToUsid) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'unblock_user',
        apiWhat: <String, dynamic>{'blockToUsid': blockToUsid},
      );

  /// 提交实名认证资料（源项目 `update_kyc`）。
  ///
  /// 成功时后端返回 `_state: 'SUBMITTED'`（而不是通用的 `SUCCESS`），
  /// 并会**发一封邮件**给值班邮箱；已提交/已通过时返回 `BER_UNEXPECTED`。
  Future<Map<String, dynamic>> updateKyc(Map<String, dynamic> user) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'update_kyc',
        apiWhat: <String, dynamic>{'User': user},
      );

  /// 我关注的人（源项目 `get_my_followings`）。
  /// [beforeTime] 为向下翻页游标，取上一页最后一条的 `followTimeUnix`。
  Future<Map<String, dynamic>> getMyFollowings({
    int takeLimit = 12,
    int? beforeTime,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_my_followings',
        apiWhat: <String, dynamic>{
          'takeLimit': takeLimit,
          'beforeTime': ?beforeTime,
        },
      );

  /// 关注我的人（源项目 `get_my_followers`）。
  /// 游标字段与「我关注的人」不同，是 `followme_followTimeUnix`。
  Future<Map<String, dynamic>> getMyFollowers({
    int takeLimit = 12,
    int? beforeTime,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_my_followers',
        apiWhat: <String, dynamic>{
          'takeLimit': takeLimit,
          'beforeTime': ?beforeTime,
        },
      );

  /// 我邀请的人（源项目 `get_invitee_list`）。
  ///
  /// 注意：该接口**不支持 `beforeTime` 游标**（后端只认 `order`/`skip`/`take`），
  /// 源项目传的 `beforeTime` 是被忽略的 → 这里改用 `skip` 翻页（这是修好的行为）。
  Future<Map<String, dynamic>> getInviteeList({
    int takeLimit = 10,
    int skip = 0,
  }) =>
      _client.callBase(
        apiWho: who,
        apiTodo: 'get_invitee_list',
        apiWhat: <String, dynamic>{'takeLimit': takeLimit, 'skip': skip},
      );
}

final Provider<UserApi> userApiProvider =
    Provider<UserApi>((ref) => UserApi(ref.watch(apiClientProvider)));
