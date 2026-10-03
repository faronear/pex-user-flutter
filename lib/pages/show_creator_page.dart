/// 个人展（创作者主页），对应源项目 `pages/showCreator.vue`。
///
/// 两大分支：**没找到**（提示 + 按 Creator ID 搜索 + 去「遇见」）与
/// **找到了**（头像 / 昵称 / 分享 / 统计 / 管理或私信 / 屏蔽 / 举报 / 关注 +
/// 自我介绍展开收起 + 该创作者的创作品列表）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../brands/brand_config.dart';
import '../core/api/api_client.dart';
import '../core/api/creation_api.dart';
import '../core/api/creator_api.dart';
import '../core/api/mia_api.dart';
import '../core/api/user_api.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_routes.dart';
import '../core/state/app_providers.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/creator_provider.dart';
import '../core/state/envar_provider.dart';
import '../core/util/feedback.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../core/util/story_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/part_close_button.dart';
import '../widgets/part_complain.dart';
import '../widgets/part_creation_card_list.dart';
import '../widgets/part_empty_list.dart';
import '../widgets/part_load_more.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_pop_link.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_story_editor.dart';
import '../widgets/part_story_reader.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_user_list.dart';
import '../widgets/part_window_layout.dart';

const LangText _kNotFound = LangText(
  zhCN: '没有找到您指定的原创主！',
  enUS: 'Cannot find this creator!',
  jaJP: '原创主が見つかりません！',
  deDE: 'Ersteller konnte nicht gefunden werden!',
);

const LangText _kKeepSearching = LangText(
  zhCN: '您可以继续搜索',
  enUS: 'You can continue to search',
  deDE: 'Sie können weiter suchen',
  jaJP: '検索を続けることができます',
);

const LangText _kCreatorIdHint = LangText(
  zhCN: '原创主 ID',
  enUS: 'Creator ID',
  jaJP: '原创主',
  deDE: 'Ersteller-ID',
);

const LangText _kOrBrowse = LangText(
  zhCN: '或者到处看看',
  enUS: 'Or browse around',
  deDE: 'Oder stöbern Sie herum',
  jaJP: 'または閲覧する',
);

const LangText _kShare = LangText(
  zhCN: '分享',
  enUS: 'Share',
  deDE: 'Teilen',
  jaJP: '共有',
);

const LangText _kManage = LangText(
  zhCN: '管理',
  enUS: 'Manage',
  deDE: 'Verwalten',
  jaJP: '管理',
);

const LangText _kMessage = LangText(
  zhCN: '私信',
  enUS: 'Message',
  deDE: 'Nachricht',
  jaJP: 'メッセ',
);

const LangText _kMessageTo = LangText(
  zhCN: '私信给 ',
  enUS: 'Message to ',
  deDE: 'Nachricht an ',
  jaJP: 'メッセージ ',
);

const LangText _kBlock = LangText(
  zhCN: '屏蔽',
  enUS: 'Block',
  deDE: 'Blockieren',
  jaJP: 'ブロック',
);

const LangText _kUnblock = LangText(
  zhCN: '解除屏蔽',
  enUS: 'Unblock',
  deDE: 'Entsperren',
  jaJP: 'ブロック解除',
);

const LangText _kReport = LangText(
  zhCN: '举报',
  enUS: 'Report',
  deDE: 'Melden',
  jaJP: '報告する',
);

const LangText _kFollow = LangText(
  zhCN: '加关注',
  enUS: 'Follow',
  deDE: 'Folgen',
  jaJP: 'フォロー',
);

const LangText _kFollowing = LangText(
  zhCN: '已关注',
  enUS: 'Following',
  deDE: 'Folgend',
  jaJP: 'フォロー中',
);

const LangText _kExpand = LangText(
  zhCN: '展开',
  enUS: 'Expand',
  deDE: 'erweitern',
  jaJP: 'を展開',
);

const LangText _kCollapse = LangText(
  zhCN: '收起',
  enUS: 'Collapse',
  deDE: 'einklappen',
  jaJP: 'を折りたたむ',
);

/// 屏蔽确认弹窗的标题与正文（源项目 `tBlockTitle` / `tBlock`，三品牌均未配置 → 用内置文案）。
const LangText _kBlockTitle = LangText(
  zhCN: '屏蔽这个用户吗？',
  enUS: 'Block this user?',
);

const LangText _kBlockContent = LangText(
  zhCN: '屏蔽后，您将不再看到对方的创作品和评论。如果您将来改变了意愿，您可以随时解除屏蔽对方。',
  enUS: "After blocking, you will no longer see this user's creations and comments. Should you change mind in the future, you can unblock this user at any time.",
);

const LangText _kUnblockTitle = LangText(
  zhCN: '解封这个用户吗？',
  enUS: 'Unblock this user?',
);

const LangText _kUnblockContent = LangText(
  zhCN: '解除屏蔽后，您将能够看到对方的创作品和评论。如果您将来改变了意愿，您可以再次屏蔽对方。',
  enUS: "After unblocking, you will be able to see this user's creations and comments. Should you change mind in the future, you can block this user again.",
);

const LangText _kConfirmBlock = LangText(zhCN: '屏蔽', enUS: 'Block');

const LangText _kConfirmUnblock = LangText(zhCN: '解除屏蔽', enUS: 'Unblock');

const LangText _kMiaSent = LangText(
  zhCN: '消息发送成功',
  enUS: 'Message sent successfully',
  deDE: 'Nachrichten erfolgreich gesendet',
  jaJP: 'メッセージが正常に送信されました',
);

const LangText _kBlockedPrompt = LangText(
  zhCN: '该用户已被您屏蔽。',
  enUS: 'This user is blocked by you.',
  deDE: 'Dieser Benutzer wurde von Ihnen blockiert.',
  jaJP: 'このユーザーはあなたにブロックされています。',
);

const LangText _kNoCreations = LangText(
  zhCN: '该用户还没有上架的创作品',
  enUS: 'This user has no creation listing yet',
  deDE: 'Dieser Benutzer hat noch keine Kreation aufgelistet',
  jaJP: 'このユーザーはまだ作品を出品していません',
);

/// 源项目 `wo.pageSet['menuCreator'].i18nPageTitle`（该页名未进生成式 page_meta）。
const LangText _kMenuCreator = LangText(
  zhCN: '遇见',
  enUS: 'Creators',
  deDE: 'Kreation',
  jaJP: '探索',
);

class ShowCreatorPage extends ConsumerStatefulWidget {
  const ShowCreatorPage({
    super.key,
    this.hostUsid = '',
    this.usid = '',
    this.haid = '',
    this.unid = '',
  });

  /// 源项目 `onLoad` 接受 `hostUsid` / `hostusid` / `usid` / `haid` / `unid` 五种参数名，
  /// 这里收敛成四种（路由里 `hostusid` 归一到 [hostUsid]）。
  final String hostUsid;
  final String usid;
  final String haid;
  final String unid;

  @override
  ConsumerState<ShowCreatorPage> createState() => _ShowCreatorPageState();
}

class _ShowCreatorPageState extends ConsumerState<ShowCreatorPage> {
  static const int _takeLimit = 12;

  final TextEditingController _searchUnid = TextEditingController();

  Map<String, dynamic> _hostUser = <String, dynamic>{};
  List<Map<String, dynamic>> _collection = <Map<String, dynamic>>[];

  LoadState _fresh = LoadState.loadFresh;
  LoadState _down = LoadState.loadUp;
  bool _readyShow = false;
  bool _readyList = false;
  bool _storyExpanded = false;

  List<Map<String, dynamic>> _miaStory = <Map<String, dynamic>>[
    <String, dynamic>{'text': ''},
  ];
  bool _miaSending = false;
  LangText? _miaFeedback;

  bool get _hasTarget => (_hostUser['usid']?.toString() ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 100), () async {
      await ref.read(appStartupProvider.notifier).waitAutologin();
      if (!mounted) return;
      await _loadCreator();
    });
  }

  @override
  void dispose() {
    _searchUnid.dispose();
    super.dispose();
  }

  Future<void> _loadCreator() async {
    final String usid = widget.hostUsid.isNotEmpty ? widget.hostUsid : widget.usid;
    final Map<String, dynamic> data =
        await ref.read(creatorApiProvider).getSingleCreator(
              usid: usid.isEmpty ? null : usid,
              haid: widget.haid.isEmpty ? null : widget.haid,
              unid: widget.unid.isEmpty ? null : widget.unid,
              takeLimit: _takeLimit,
            );
    if (!mounted) return;
    if (bok(data['_state']?.toString())) {
      setState(() {
        _hostUser = (data['user'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        _collection = _asList(data['collection']);
        _down = _collection.length < _takeLimit
            ? LoadState.noMore
            : LoadState.loadUp;
      });
    } else {
      setState(() => _hostUser = <String, dynamic>{});
    }
    if (!mounted) return;
    setState(() {
      _readyShow = true;
      _readyList = true;
    });
  }

  static List<Map<String, dynamic>> _asList(Object? value) => value is List
      ? value
          .whereType<Map>()
          .map((Map item) => item.cast<String, dynamic>())
          .toList()
      : <Map<String, dynamic>>[];

  static int _intOf(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  void _toast(Object? message) {
    final LangText text = LangText.fromMap(message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ll(ref.read(languageProvider),
                text.isEmpty ? PartTexts.systemDown : text),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// 本人主页链接（源项目 `urlCreator`）：`https://goto.<域名>/creator/<haid 或 usid>?inhaid=<我的 haid>`。
  String _urlCreator() {
    final String hostHaid = _hostUser['haid']?.toString() ?? '';
    final String hostUsid = _hostUser['usid']?.toString() ?? '';
    final String myHaid =
        ref.read(onlineUserProvider)['haid']?.toString() ?? '';
    final String domain = ref.read(brandProvider).webDomain;
    return 'https://goto.$domain/creator/${hostHaid.isEmpty ? hostUsid : hostHaid}'
        '${myHaid.isEmpty ? '' : '?inhaid=$myHaid'}';
  }

  bool get _isMyself {
    final String mine = ref.read(onlineUserProvider)['usid']?.toString() ?? '';
    final String host = _hostUser['usid']?.toString() ?? '';
    return mine.isNotEmpty && mine == host;
  }

  /// 刷新（源项目 `to_get_newest_user_creations`）。
  Future<void> _reloadCreations() async {
    if (_fresh == LoadState.loading) return;
    setState(() => _fresh = LoadState.loading);
    final Map<String, dynamic> data =
        await ref.read(creationApiProvider).getUserCreations(
              usid: _hostUser['usid']?.toString() ?? '',
              takeLimit: _takeLimit,
            );
    if (!mounted) return;
    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> list = _asList(data['collection']);
      setState(() {
        _collection = list;
        _down = list.length < _takeLimit ? LoadState.noMore : LoadState.loadUp;
      });
    } else {
      _toast(data['_msg']);
    }
    if (mounted) setState(() => _fresh = LoadState.loadFresh);
  }

  /// 加载更多（源项目 `to_get_older_user_creations`）。
  Future<void> _loadOlderCreations() async {
    if (_down == LoadState.loading) return;
    setState(() => _down = LoadState.loading);
    final Map<String, dynamic> data =
        await ref.read(creationApiProvider).getUserCreations(
              usid: _hostUser['usid']?.toString() ?? '',
              takeLimit: _takeLimit,
              beforeTime: _collection.isEmpty
                  ? null
                  : _intOf(_collection.last['createTimeUnix']),
            );
    if (!mounted) return;
    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> list = _asList(data['collection']);
      if (list.isNotEmpty) {
        setState(() => _collection = <Map<String, dynamic>>[
          ..._collection,
          ...list.where((Map<String, dynamic> item) => !_collection.any(
              (Map<String, dynamic> old) =>
                  old['csid']?.toString() == item['csid']?.toString())),
        ]);
      }
      setState(() => _down =
          list.length < _takeLimit ? LoadState.noMore : LoadState.loadUp);
      return;
    }
    _toast(data['_msg']);
    if (mounted) setState(() => _down = LoadState.loadUp);
  }

  /// 关注 / 取消关注（源项目 `toggle_follow_state`）。
  Future<void> _toggleFollow() async {
    final String hostUsid = _hostUser['usid']?.toString() ?? '';
    final bool followed = _hostUser['followState']?.toString() == 'FOLLOWED';
    final Map<String, dynamic> data = followed
        ? await ref.read(userApiProvider).unfollowUser(hostUsid)
        : await ref.read(userApiProvider).followUser(hostUsid);
    if (!mounted) return;
    if (!bok(data['_state']?.toString())) {
      _toast(data['_msg']);
      return;
    }
    final int delta = followed ? -1 : 1;
    final Map<String, dynamic> online = ref.read(onlineUserProvider);
    setState(() => _hostUser = <String, dynamic>{
          ..._hostUser,
          'followState': followed ? 'UNFOLLOWED' : 'FOLLOWED',
          'countFollower': _intOf(_hostUser['countFollower']) + delta,
        });
    ref.read(appStartupProvider.notifier).mergeOnlineUser(<String, dynamic>{
      'countFollowing': _intOf(online['countFollowing']) + delta,
    });
  }

  /// 屏蔽 / 解除屏蔽（源项目 `to_toggle_block`）：先确认，再调接口并同步名单。
  Future<void> _toggleBlock() async {
    final Envar envar = ref.read(envarProvider);
    final String hostUsid = _hostUser['usid']?.toString() ?? '';
    final bool blocked = _hostUser['blockState']?.toString() == 'BLOCKED';

    final bool confirmed = await showPexModal(
      context,
      ref,
      title: (blocked
              ? (envar.tUnblockTitle.isEmpty ? _kUnblockTitle : envar.tUnblockTitle)
              : (envar.tBlockTitle.isEmpty ? _kBlockTitle : envar.tBlockTitle)),
      content: (blocked
          ? (envar.tUnblock.isEmpty ? _kUnblockContent : envar.tUnblock)
          : (envar.tBlock.isEmpty ? _kBlockContent : envar.tBlock)),
      confirmText: blocked ? _kConfirmUnblock : _kConfirmBlock,
      showCancel: true,
    );
    if (!confirmed || !mounted) return;

    final Map<String, dynamic> data = blocked
        ? await ref.read(userApiProvider).unblockUser(hostUsid)
        : await ref.read(userApiProvider).blockUser(hostUsid);
    if (!mounted) return;
    if (!bok(data['_state']?.toString())) {
      _toast(data['_msg']);
      return;
    }

    final int delta = blocked ? -1 : 1;
    final Map<String, dynamic> online = ref.read(onlineUserProvider);
    final String nextState = blocked ? 'UNBLOCKED' : 'BLOCKED';
    setState(() => _hostUser = <String, dynamic>{
          ..._hostUser,
          'blockState': nextState,
          'countBlocked': _intOf(_hostUser['countBlocked']) + delta,
        });
    ref.read(appStartupProvider.notifier).mergeOnlineUser(<String, dynamic>{
      'countBlocking': _intOf(online['countBlocking']) + delta,
    });
    // 源项目在屏蔽后同步更新三个名单，让返回上一页时状态一致。
    ref.read(creatorProvider.notifier).setBlockStateInLists(hostUsid, nextState);
    if (!blocked) ref.read(creatorProvider.notifier).removeFromListAll(hostUsid);
  }

  /// 私信弹窗（源项目 `popMessage`）。
  Future<void> _openMessage() async {
    final Envar envar = ref.read(envarProvider);
    final String lang = ref.read(languageProvider);
    setState(() => _miaFeedback = null);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PexColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setSheet) =>
            Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.75,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    PartCloseButton(onClose: () => Navigator.of(context).pop()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 20),
                      child: Text(
                        '${_kMessageTo.resolve(lang)}${_hostUser['nickname']?.toString() ?? ''}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 2,
                        ),
                      ),
                    ),
                    PartStoryEditor(
                      story: _miaStory,
                      onStoryChanged: (List<Map<String, dynamic>> next) =>
                          setSheet(() => _miaStory = next),
                      allowText: envar.boolOf('miaText', true),
                      allowImage: envar.boolOf('miaImage'),
                      allowVideo: envar.boolOf('miaVideo'),
                      allowFile: envar.boolOf('miaFile'),
                      allowLink: envar.boolOf('miaLink'),
                      allowSpeak: envar.boolOf('miaSpeak'),
                      maxSections: envar.intOf('miaMaxSections', 2),
                      publishing: _miaSending,
                      onPublish: () async {
                        final bool sent = await _sendMia();
                        if (sent && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    if (_miaFeedback != null)
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          _miaFeedback!.resolve(lang),
                          style: const TextStyle(color: PexColors.redMy),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 发私信（源项目 `to_send_mia`）；返回是否发送成功（决定是否关闭弹窗）。
  Future<bool> _sendMia() async {
    setState(() => _miaFeedback = null);
    _miaStory = filterStory(_miaStory).cast<Map<String, dynamic>>();
    if (_miaStory.isEmpty) {
      setState(() {
        _miaStory = <Map<String, dynamic>>[<String, dynamic>{'text': ''}];
        _miaFeedback = const LangText(
          zhCN: '消息是空的。请先写点儿什么！',
          enUS: 'Message is empty. Please write something!',
        );
      });
      return false;
    }
    setState(() => _miaSending = true);
    final Map<String, dynamic> data = await ref.read(miaApiProvider).sendMia(
          miaToUsid: _hostUser['usid']?.toString() ?? '',
          miaToMid: '',
          miaStory: _miaStory,
        );
    if (!mounted) return false;
    setState(() => _miaSending = false);

    if (bok(data['_state']?.toString())) {
      await showPexModal(context, ref, title: _kMiaSent);
      if (!mounted) return false;
      // 源项目：确认后再清空（留在页面上给用户提示）。
      setState(() => _miaStory = <Map<String, dynamic>>[
            <String, dynamic>{'text': ''},
          ]);
      return true;
    }
    final LangText message = LangText.fromMap(data['_msg']);
    setState(() => _miaFeedback =
        message.isEmpty ? PartTexts.systemDown : message);
    return false;
  }

  /// 按 Creator ID 重新搜索（源项目 `search_unid`）。
  void _searchUnidGo() {
    final String keyword = _searchUnid.text.trim();
    if (keyword.isEmpty) return;
    context.go('${AppRoutes.path(AppRoutes.showCreator)}?unid=$keyword');
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final DeviceInfo device = DeviceInfo.of(context);
    final bool inPc = device.inPc;

    return PartWindowLayout(
      pageName: AppRoutes.showCreator,
      child: Column(
        children: <Widget>[
          const PartNavibarPcFixed(),
          Expanded(
            child: !_readyShow
                ? const PartShowLoading()
                : SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: inPc ? 900 : 750),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: _hasTarget
                              ? _body(lang, inPc)
                              : _notFound(lang),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _notFound(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 20),
        Text(
          _kNotFound.resolve(lang),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 2,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 5),
          child: Text(
            _kKeepSearching.resolve(lang),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _searchUnid,
                autofocus: true,
                onSubmitted: (_) => _searchUnidGo(),
                decoration: InputDecoration(
                  hintText: _kCreatorIdHint.resolve(lang),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            InkWell(
              onTap: _searchUnidGo,
              child: Container(
                height: 48,
                width: 48,
                color: const Color(0xFF007BFF),
                child: PexIcon.uni('search', size: 22, color: Colors.white),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(_kOrBrowse.resolve(lang),
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 5),
              InkWell(
                onTap: () => context.go(AppRoutes.path(AppRoutes.menuCreator)),
                child: Container(
                  // 源项目：`linear-gradient(90deg, --YellowMatt, --RedMy)` + 白字。
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFFFCBD71), PexColors.redMy],
                    ),
                    border: Border.all(color: PexColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  height: 44,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PexIcon.uni('navigate', size: 22, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        _kMenuCreator.resolve(lang),
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _body(String lang, bool inPc) {
    final BrandConfig brand = ref.watch(brandProvider);
    final String nickname = _hostUser['nickname']?.toString() ?? '';
    final String portrait = _hostUser['portrait']?.toString() ?? '';
    final bool blocked = _hostUser['blockState']?.toString() == 'BLOCKED';
    final bool followed = _hostUser['followState']?.toString() == 'FOLLOWED';
    final String aboutmeTitle = _aboutmeTitle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: PexColors.greyE,
            borderRadius:
                inPc ? const BorderRadius.vertical(top: Radius.circular(10)) : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: portrait.isEmpty
                    ? const Center(
                        child: Icon(Icons.person,
                            size: 48, color: Color(0xFFD3D3D3)),
                      )
                    : ServerImage(portrait, fit: BoxFit.cover),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.8,
                            ),
                          ),
                        ),
                        _locButton(
                          lang: lang,
                          text: _kShare.resolve(lang),
                          icon: 'redo',
                          onTap: () => showPopLinkSheet(
                            context,
                            ref,
                            shareTitle: nickname,
                            shareUrl: _urlCreator(),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        _stat(
                          icon: kUmyCollectionIcon,
                          color: brand.colorCollect,
                          text: '${countCreationPublic(_hostUser)}',
                        ),
                        const SizedBox(width: 20),
                        _stat(
                          icon: kUmyCircleIcon,
                          color: brand.colorCircle,
                          text:
                              '${_intOf(_hostUser['countFollower']) + _intOf(_hostUser['countFollowing'])}',
                        ),
                        const Spacer(),
                        if (_isMyself)
                          _locButton(
                            lang: lang,
                            text: _kManage.resolve(lang),
                            icon: 'gear',
                            onTap: () =>
                                context.go(AppRoutes.path(AppRoutes.menuUzone)),
                          )
                        else
                          _locButton(
                            lang: lang,
                            text: _kMessage.resolve(lang),
                            icon: 'chat',
                            onTap: _openMessage,
                          ),
                      ],
                    ),
                    if (!_isMyself)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: <Widget>[
                            _locButton(
                              lang: lang,
                              text: blocked
                                  ? _kUnblock.resolve(lang)
                                  : _kBlock.resolve(lang),
                              icon: blocked ? 'eye' : 'eye-slash',
                              color: PexColors.grey6,
                              onTap: _toggleBlock,
                            ),
                            _locButton(
                              lang: lang,
                              text: _kReport.resolve(lang),
                              icon: 'hand-down',
                              color: PexColors.grey6,
                              onTap: () => showComplainSheet(
                                context,
                                ref,
                                reportTargetId:
                                    _hostUser['usid']?.toString() ?? '',
                                reportTargetType: 'USER',
                              ),
                            ),
                            const Spacer(),
                            _locButton(
                              lang: lang,
                              text: followed
                                  ? _kFollowing.resolve(lang)
                                  : _kFollow.resolve(lang),
                              icon: followed ? 'heart-filled' : 'heart',
                              color: followed ? PexColors.redMy : PexColors.blueMy,
                              onTap: _toggleFollow,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (aboutmeTitle.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: PexColors.greyE,
              borderRadius: inPc
                  ? const BorderRadius.vertical(bottom: Radius.circular(10))
                  : null,
            ),
            child: _storyExpanded
                ? Column(
                    children: <Widget>[
                      _expandToggle(lang, false),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: PartStoryReader(
                            story: (_hostUser['aboutme'] as List?) ??
                                <dynamic>[]),
                      ),
                      _expandToggle(lang, false),
                    ],
                  )
                : Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          aboutmeTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _expandToggle(lang, true),
                    ],
                  ),
          ),
        if (blocked)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: PartEmptyList(
              prompt: _kBlockedPrompt,
              aboveIcon: 'eye',
              aboveText: _kUnblock,
              aboveAction: _toggleBlock,
            ),
          )
        else if (!_readyList)
          const PartShowLoading()
        else if (_collection.isEmpty)
          PartEmptyList(
            prompt: _kNoCreations,
            aboveIcon: 'refresh',
            aboveAction: _reloadCreations,
          )
        else
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                PartLoadMore(loadState: _fresh, onLoad: _reloadCreations),
                PartCreationCardList(
                  pexList: _collection,
                  hideAvatar: true,
                  twoColumnOnPhone: true,
                ),
                PartLoadMore(loadState: _down, onLoad: _loadOlderCreations),
              ],
            ),
          ),
        const SizedBox(height: 30),
      ],
    );
  }

  /// 自我介绍折叠时的一行标题（源项目 `aboutmeTitle`）：第一段文字压掉换行，取不到则取 story 摘要。
  String _aboutmeTitle() {
    final Object? aboutme = _hostUser['aboutme'];
    if (aboutme is List && aboutme.isNotEmpty && aboutme.first is Map) {
      final String text =
          (aboutme.first as Map)['text']?.toString().trim() ?? '';
      if (text.isNotEmpty) return text.replaceAll(RegExp(r'\n+'), ' ');
    }
    return extractStoryTitle(aboutme as List<dynamic>?);
  }

  Widget _expandToggle(String lang, bool expand) {
    return InkWell(
      onTap: () => setState(() => _storyExpanded = expand),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              (expand ? _kExpand : _kCollapse).resolve(lang),
              style: const TextStyle(fontSize: 12, color: PexColors.subtext),
            ),
            const SizedBox(width: 4),
            PexIcon.uni(expand ? 'bottom' : 'top',
                size: 16, color: PexColors.subtext),
          ],
        ),
      ),
    );
  }

  Widget _stat({
    required String icon,
    required Color color,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PexIcon.uni(icon, size: 16, color: color),
        const SizedBox(width: 2),
        Text(text, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }

  /// 源项目 `.locButton`：品牌蓝（或指定色）的胶囊小按钮 + 图标。
  Widget _locButton({
    required String lang,
    required String text,
    required String icon,
    required VoidCallback onTap,
    Color color = PexColors.blueMy,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text, style: TextStyle(fontSize: 12, color: color)),
            const SizedBox(width: 2),
            PexIcon.uni(icon, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
