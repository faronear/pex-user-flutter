/// 我的空间，对应源项目 `pages/menuUzone.vue`。
///
/// 三品牌共有的 tabBar 页（`pages.json` 的 `tabBar.list` 最后一项）。
/// 结构：未登录态（注册引导）/ 已登录态（头像·昵称·自我介绍·余额徽标·语言表
/// + 8 行清单 + 退出/资源/重启）。
///
/// **关于清单里指向未迁移页面的行**：老板 2026-09-30 确认「全部渲染，跳现有占位页」——
/// 复用 `app_router.dart` 的兜底路由，占位页会明确显示「XX 尚未迁移」，
/// 等对应页面迁移后自动生效，无需回改本页。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/api/fileloader_api.dart';
import '../core/api/user_api.dart';
import '../core/appmeta/page_meta.dart';
import '../brands/brand_config.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_router.dart';
import '../core/state/app_providers.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/creation_draft_provider.dart';
import '../core/state/creation_provider.dart';
import '../core/state/creator_provider.dart';
import '../core/state/envar_provider.dart';
import '../core/util/feedback.dart';
import '../core/util/file_utils.dart';
import '../core/util/pex_file_picker.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../core/util/story_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/part_close_button.dart';
import '../widgets/part_icontext_copy.dart';
import '../widgets/part_lang_table.dart';
import '../widgets/part_pop_link.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_story_editor.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_user_list.dart';
import '../widgets/part_window_layout.dart';

// ---------------------------------------------------------------------------
// 文案（源项目均为内联 `wo.ll({...})`，此处集中声明以免散落）
// ---------------------------------------------------------------------------

const LangText _kChangeAvatar = LangText(zhCN: '更换头像', enUS: 'Change Avatar');

const LangText _kChangeAvatarPc = LangText(
  zhCN: '拖拽或点击换头像',
  enUS: 'Drag or Click to set avatar',
);

const LangText _kAvatarUploading = LangText(
  zhCN: '头像正在上传中，请稍后再试',
  enUS: 'Avatar is uploading, try again later please.',
);

const LangText _kAvatarFailed = LangText(
  zhCN: '头像更换没有成功，请稍后再试',
  enUS: 'Failed to change the avatar. Try again later please.',
);

const LangText _kShare = LangText(zhCN: '分享', enUS: 'Share');

const LangText _kIntroduce = LangText(
  zhCN: '做个自我介绍吧',
  enUS: 'Introduce yourself to everyone',
);

const LangText _kSelfIntro = LangText(zhCN: '自我介绍', enUS: 'Self-Introduction');

const LangText _kSubmit = LangText(
  zhCN: '提交',
  enUS: 'Submit',
  deDE: 'Absenden',
  jaJP: '送信',
);

const LangText _kSubmittingAboutme = LangText(
  zhCN: '自我介绍正在提交中，请稍后再试',
  enUS: 'Self-introduction is submitting, try again later please.',
);

const LangText _kUpdateFailed = LangText(
  zhCN: '更新没有成功，请稍后再试',
  enUS: 'Failed to update. Try again later please.',
);

const LangText _kChangeNickname = LangText(
  zhCN: '修改昵称',
  enUS: 'Change Nickname',
  deDE: 'Ändern Sie den Spitznamen',
  jaJP: 'ニックネームを変更する',
);

const LangText _kEnterNickname = LangText(
  zhCN: '输入您的昵称',
  enUS: 'Enter your nickname',
  deDE: 'Geben Sie den Spitznamen ein',
  jaJP: 'ニックネームを入力してください',
);

const LangText _kConfirm = LangText(
  zhCN: '确认',
  enUS: 'Confirm',
  deDE: 'Bestätigen',
  jaJP: '確認',
);

const LangText _kNicknameFailed = LangText(
  zhCN: '昵称修改没有成功，请稍后再试',
  enUS: 'Failed to change the nickname. Try again later please.',
);

const LangText _kWaitingKyc = LangText(zhCN: '等待实名', enUS: 'Waiting KYC');

const LangText _kDeposit = LangText(zhCN: ' | 充值', enUS: ' | Deposit');

const LangText _kCashout = LangText(zhCN: ' | 提现', enUS: ' | Cashout');

const LangText _kUnread = LangText(
  zhCN: ' 未读',
  enUS: ' unread',
  jaJP: ' 未読',
  deDE: ' ungelesen',
);

const LangText _kInvited = LangText(zhCN: '已邀请', enUS: 'Invited');

const LangText _kUsers = LangText(zhCN: '人', enUS: 'Users');

const LangText _kLogoutTitle = LangText(
  zhCN: '退出这个账号吗？',
  enUS: 'Log out this account?',
  deDE: 'Dieses Konto abmelden?',
  jaJP: 'このアカウントをログアウトしますか？',
);

const LangText _kLogoutConfirm = LangText(
  zhCN: '退出',
  enUS: 'Logout',
  deDE: 'Abmelden',
  jaJP: 'ログアウト',
);

const LangText _kLogout = LangText(
  zhCN: '退出账号',
  enUS: 'Logout',
  deDE: 'Abmelden',
  jaJP: 'ログアウト',
);

const LangText _kRestart = LangText(
  zhCN: '重启应用',
  enUS: 'Restart',
  deDE: 'Neustarten',
  jaJP: '再起動',
);

const LangText _kRegisterReward = LangText(
  zhCN: '今日注册，赠送 ',
  enUS: 'Register Now & Get Rewards ',
);

const LangText _kSignupLogin = LangText(
  zhCN: '注册登录',
  enUS: 'Signup or Login',
);

// ---------------------------------------------------------------------------
// 页面
// ---------------------------------------------------------------------------

class MenuUzonePage extends ConsumerStatefulWidget {
  const MenuUzonePage({super.key});

  @override
  ConsumerState<MenuUzonePage> createState() => _MenuUzonePageState();
}

class _MenuUzonePageState extends ConsumerState<MenuUzonePage> {
  bool _loadingAvatar = false;
  bool _loadingLogout = false;

  /// 换头像（源项目 `to_update_portrait`）：选图 → 上传 → 写回用户资料。
  Future<void> _updatePortrait() async {
    if (_loadingAvatar) {
      showPexToast(context, ref, _kAvatarUploading);
      return;
    }
    final PickedMedia? picked = await pickMedia(mediaType: 'image');
    if (picked == null || !mounted) return; // 用户取消，静默

    final FileloaderApi api = ref.read(fileloaderApiProvider);
    final LangText? invalid = api.validate(
      filename: picked.filename,
      size: picked.size,
      mediaType: 'image',
    );
    if (invalid != null) {
      showPexToast(context, ref, invalid);
      return;
    }

    setState(() => _loadingAvatar = true);
    final FileUploadResult upload =
        await api.uploadFile(filename: picked.filename, bytes: picked.bytes);
    if (!mounted) return;
    if (!upload.ok) {
      setState(() => _loadingAvatar = false);
      if (!upload.cancelled) {
        showPexToast(context, ref, upload.message ?? PartTexts.systemDown);
      }
      return;
    }

    final String portrait = chooseUrl(upload.fileInfo, prefer: 'url');
    final Map<String, dynamic> data =
        await ref.read(userApiProvider).updatePortrait(portrait);
    if (!mounted) return;
    setState(() => _loadingAvatar = false);

    if (bok(data['_state']?.toString())) {
      ref
          .read(appStartupProvider.notifier)
          .mergeOnlineUser(<String, dynamic>{'portrait': portrait});
      return;
    }
    final LangText message = LangText.fromMap(data['_msg']);
    showPexToast(context, ref, message.isEmpty ? _kAvatarFailed : message);
  }

  /// 改昵称（源项目 `to_update_nickname`）。
  Future<void> _updateNickname(String current) async {
    final String? input = await showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          _RenameDialog(initial: current, title: _kChangeNickname),
    );
    if (input == null || !mounted) return;

    final String nickname = input.trim();
    if (nickname.isEmpty) {
      showPexToast(context, ref, _kEnterNickname);
      return;
    }
    if (nickname == current) return;

    final Map<String, dynamic> data =
        await ref.read(userApiProvider).updateNickname(nickname);
    if (!mounted) return;
    if (bok(data['_state']?.toString())) {
      ref
          .read(appStartupProvider.notifier)
          .mergeOnlineUser(<String, dynamic>{'nickname': nickname});
      return;
    }
    final LangText message = LangText.fromMap(data['_msg']);
    showPexToast(context, ref, message.isEmpty ? _kNicknameFailed : message);
  }

  /// 自我介绍（源项目 `to_update_aboutme`）。
  Future<void> _editAboutme() async {
    final List<dynamic> raw =
        (ref.read(onlineUserProvider)['aboutme'] as List?) ?? <dynamic>[];
    final List<Map<String, dynamic>> story = raw.isEmpty
        ? <Map<String, dynamic>>[<String, dynamic>{'text': ''}]
        : raw
            .map((dynamic section) => section is Map
                ? Map<String, dynamic>.from(section)
                : <String, dynamic>{})
            .toList();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => _AboutmeDialog(story: story),
    );
  }

  /// 退出账号（源项目 `to_logout` → `logout_local_account`）。
  Future<void> _logout(Map<String, dynamic> user) async {
    final bool confirmed = await showPexModal(
      context,
      ref,
      title: _kLogoutTitle,
      content: LangText.from(user['nickname']?.toString() ?? ' '),
      confirmText: _kLogoutConfirm,
      showCancel: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _loadingLogout = true);
    await ref.read(userApiProvider).logoutUser();
    if (!mounted) return;
    setState(() => _loadingLogout = false);

    // 源项目 `logout_local_account`：清本地凭据 + 清缓存 + 不再自动登录 + 回落地页。
    await ref.read(localStoreProvider).clearPasstoken();
    ref.read(appStartupProvider.notifier).logout();
    _resetDomainCaches();
    if (!mounted) return;
    context.go(
      AppRoutes.path(ref.read(brandProvider).appLandPage),
    );
  }

  /// 重启应用（源项目 `reset_all` + `reLaunch(homePortal)`）。
  Future<void> _restart() async {
    _resetDomainCaches();
    await ref.read(appStartupProvider.notifier).restart();
    if (!mounted) return;
    context.go(AppRoutes.path(AppRoutes.homePortal));
  }

  /// 清空各业务域的会话内缓存。
  ///
  /// 源项目 `reset_all` 还会重置 AI 对话与交易流水；这两域的页面尚未迁移，
  /// 待迁移时一并补上（见 `aimemo/projectPlan.md`）。
  void _resetDomainCaches() {
    ref.invalidate(creationProvider);
    ref.invalidate(creatorProvider);
    ref.invalidate(creationDraftProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AppStartupState startup = ref.watch(appStartupProvider);
    final DeviceInfo device = DeviceInfo.of(context);
    final String lang = ref.watch(languageProvider);
    final Map<String, dynamic> user = ref.watch(onlineUserProvider);

    return PartWindowLayout(
      pageName: AppRoutes.menuUzone,
      showTabBar: true,
      child: !startup.afterAutologging
          ? const PartShowLoading()
          : (user['usid']?.toString() ?? '').isEmpty
              ? _guestView(device, lang)
              : _memberView(device, lang, user),
    );
  }

  // -------------------------------------------------------------------------
  // 未登录（源项目 `partWindowLayoutUser` 的未登录分支）
  // -------------------------------------------------------------------------

  Widget _guestView(DeviceInfo device, String lang) {
    final Envar envar = ref.watch(envarProvider);
    final int reward = envar.registerReward + envar.inviteeReward;

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: <Widget>[
                Text(
                  ll(lang, LangText.fromMap(envar.raw['slogans'])),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 2,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  '${ll(lang, _kRegisterReward)}$reward${envar.tucSymbol}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.path(AppRoutes.identBegin)),
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                  ),
                  icon: PexIcon.uni('auth', size: 22),
                  label: Text(ll(lang, _kSignupLogin)),
                ),
                const SizedBox(height: 40),
                _resourceCircle(lang),
                if (!device.inPc) ...<Widget>[
                  const SizedBox(height: 40),
                  _outlineButton(
                    icon: 'refresh',
                    color: PexColors.greenMy,
                    label: _kRestart,
                    onTap: _restart,
                  ),
                  const SizedBox(height: 12),
                  PartLangTable(color: PexColors.grey8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 已登录（源项目 `menuUzone.vue` 主体）
  // -------------------------------------------------------------------------

  Widget _memberView(DeviceInfo device, String lang, Map<String, dynamic> user) {
    return Column(
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _headbar(device, lang, user),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: device.inPc ? 0 : 5),
                  child: Column(
                    children: <Widget>[
                      _listCard(lang, user),
                      _bottomActions(lang),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 顶栏：头像 + 昵称/分享 + 徽标 + 语言 + 自我介绍。
  Widget _headbar(DeviceInfo device, String lang, Map<String, dynamic> user) {
    final String portrait = user['portrait']?.toString() ?? '';
    final String nickname = user['nickname']?.toString() ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: PexColors.bg,
        boxShadow: <BoxShadow>[
          BoxShadow(color: Color(0x22000000), blurRadius: 5),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 头像（点击/拖拽更换）
          GestureDetector(
            onTap: _updatePortrait,
            child: SizedBox(
              width: 80,
              child: Column(
                children: <Widget>[
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: portrait.isEmpty
                          ? Border.all(color: PexColors.blueMatt)
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _loadingAvatar
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : portrait.isEmpty
                            ? Center(
                                child: PexIcon.uni(
                                  'plusempty',
                                  size: 40,
                                  color: PexColors.blueMatt,
                                ),
                              )
                            : ServerImage(portrait, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    ll(lang, device.inPc ? _kChangeAvatarPc : _kChangeAvatar),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, color: PexColors.blueMy),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _updateNickname(nickname),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  nickname,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              PexIcon.uni('compose', size: 21, color: PexColors.blueMy),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    _shareButton(lang, user),
                  ],
                ),
                const SizedBox(height: 2),
                _countersRow(lang, user),
                const SizedBox(height: 3),
                _aboutmeRow(lang, user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shareButton(String lang, Map<String, dynamic> user) {
    return OutlinedButton(
      onPressed: () => showPopLinkSheet(
        context,
        ref,
        shareTitle: user['nickname']?.toString() ?? '',
        shareUrl: _urlMyself(ref.read(brandProvider).webDomain, user),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: PexColors.grey8,
        side: const BorderSide(color: Colors.black12),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(ll(lang, _kShare)),
          const SizedBox(width: 2),
          PexIcon(iconPopGlyph(), size: 20),
        ],
      ),
    );
  }

  /// 余额 / 消息 / 选集 / 圈子 徽标 + 语言选择器。
  Widget _countersRow(String lang, Map<String, dynamic> user) {
    final Envar envar = ref.watch(envarProvider);
    final BrandConfig brand = ref.watch(brandProvider);
    final bool showCreation = brand.showCreatorShortcuts;

    return Row(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _badge(
                  color: PexColors.colorFund,
                  icon: PexIcons.byPrefix(
                    pageMetaOf('umyFund')?.gotoIconPrefix,
                    pageMetaOf('umyFund')?.gotoIconType,
                  ),
                  text: '${numberPrecision(user['balanceTUC'], 0)}${envar.tucSymbol}',
                  onTap: () => context.push('/${AppRoutes.umyFund}'),
                ),
                _badge(
                  color: PexColors.colorMia,
                  icon: PexIcons.byPrefix(
                    pageMetaOf('umyMia')?.gotoIconPrefix,
                    pageMetaOf('umyMia')?.gotoIconType,
                  ),
                  text: '${_intOf(user['countMiaUnread'])}',
                  onTap: () => context.push('/${AppRoutes.umyMia}'),
                ),
                if (showCreation) ...<Widget>[
                  _badge(
                    color: brand.colorCollect,
                    icon: PexIcons.uni(kUmyCollectionIcon),
                    text: '${countCreationPublic(user)}',
                    onTap: () => context.push(
                      '/${AppRoutes.umyCollection}?tagnow=TCREATE',
                    ),
                  ),
                  _badge(
                    color: brand.colorCircle,
                    icon: PexIcons.uni(kUmyCircleIcon),
                    text:
                        '${_intOf(user['countFollower']) + _intOf(user['countFollowing'])}',
                    onTap: () => context.push(
                      '/${AppRoutes.umyCircle}?tagnow=FOLLOWING',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        PartLangTable(color: PexColors.grey8),
      ],
    );
  }

  Widget _badge({
    required Color color,
    required PexGlyph? icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PexIcon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutmeRow(String lang, Map<String, dynamic> user) {
    final String title = _aboutmeTitle(user);
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: _editAboutme,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  title.isEmpty ? ll(lang, _kIntroduce) : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: title.isEmpty ? PexColors.subtext : null,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              PexIcon.uni('compose', size: 20, color: PexColors.blueMy),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 清单
  // -------------------------------------------------------------------------

  Widget _listCard(String lang, Map<String, dynamic> user) {
    final Envar envar = ref.watch(envarProvider);
    final bool showCreation = ref.watch(brandProvider).showCreatorShortcuts;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x1A000000), blurRadius: 10),
        ],
      ),
      child: Column(
        children: <Widget>[
          _listRow(
            icon: PexIcons.uni('bars'),
            title: pageMetaOf('umyAccount')?.i18nListTitle,
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(user['haid']?.toString() ?? ''),
                Text(user['phone']?.toString() ?? ''),
                Text(user['email']?.toString() ?? ''),
              ],
            ),
            onTap: () => context.push('/${AppRoutes.umyAccount}'),
          ),
          _listRow(
            icon: PexIcons.uni('auth'),
            title: pageMetaOf('umyKyc')?.i18nListTitle,
            footer: Text(_kycLabel(lang, envar, user)),
            onTap: () => context.push('/${AppRoutes.umyKyc}'),
          ),
          _listRow(
            icon: PexIcons.byPrefix(
              pageMetaOf('umyFund')?.gotoIconPrefix,
              pageMetaOf('umyFund')?.gotoIconType,
            ),
            title: pageMetaOf('umyFund')?.i18nListTitle,
            footer: Text(
              '${numberPrecision(user['balanceTUC'], 0)}${envar.tucSymbol}'
              '${ll(lang, _kDeposit)}'
              '${_boolOf(envar.raw['hideCashoutButton']) ? '' : ll(lang, _kCashout)}',
            ),
            onTap: () => context.push('/${AppRoutes.umyFund}'),
          ),
          _listRow(
            icon: PexIcons.byPrefix(
              pageMetaOf('umyMia')?.gotoIconPrefix,
              pageMetaOf('umyMia')?.gotoIconType,
            ),
            title: pageMetaOf('umyMia')?.i18nListTitle,
            footer: Text('${_intOf(user['countMiaUnread'])}${ll(lang, _kUnread)}'),
            onTap: () => context.push('/${AppRoutes.umyMia}'),
          ),
          if (showCreation)
            _listRow(
              icon: PexIcons.uni(kUmyCollectionIcon),
              title: pageMetaOf('umyCollection')?.i18nListTitle ??
                  const LangText(zhCN: '我的选集', enUS: 'My Collections'),
              footer: _pactCounters(envar, user),
              onTap: () => context.push('/${AppRoutes.umyCollection}'),
            ),
          if (showCreation)
            _listRow(
              icon: PexIcons.uni(kUmyCircleIcon),
              title: pageMetaOf('umyCircle')?.i18nListTitle ??
                  const LangText(zhCN: '我的圈子', enUS: 'My Circles'),
              footer: _circleCounters(lang, envar, user),
              onTap: () => context.push('/${AppRoutes.umyCircle}'),
            )
          else
            _listRow(
              icon: PexIcons.uni('gift'),
              title: pageMetaOf('umyInvite')?.i18nListTitle,
              footer: Text(
                '${ll(lang, _kInvited)} ${_intOf(user['countInvitee'])} ${ll(lang, _kUsers)}',
              ),
              onTap: () => context.push('/${AppRoutes.umyInvite}'),
            ),
          _listRow(
            icon: PexIcons.uni('gear'),
            title: pageMetaOf('umyConfig')?.i18nListTitle,
            // 源项目还有法币 / 加密币代码，但那属于 `umyConfig`（设置）域，尚未迁移。
            footer: Text('${kLangNative[lang] ?? lang} | ${ref.watch(brandProvider).coinCode}'),
            onTap: () => context.push('/${AppRoutes.umyConfig}'),
          ),
          _listRow(
            icon: PexIcons.byPrefix(
              pageMetaOf('umyContact')?.gotoIconPrefix,
              pageMetaOf('umyContact')?.gotoIconType,
            ),
            title: pageMetaOf('umyContact')?.i18nListTitle,
            footer: Text(ll(lang, pageMetaOf('umyContact')?.i18nGotoTitle ?? const LangText.from(''))),
            onTap: () => context.push('/${AppRoutes.umyContact}'),
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _listRow({
    required PexGlyph? icon,
    required LangText? title,
    required Widget footer,
    required VoidCallback onTap,
    bool last = false,
  }) {
    final String lang = ref.watch(languageProvider);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: PexColors.bg, width: 1),
                ),
        ),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PexIcon(icon, size: 22, color: PexColors.grey3),
            ),
            Text(
              ll(lang, title ?? const LangText.from('')),
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontSize: 13, color: PexColors.grey9),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: footer,
                ),
              ),
            ),
            const SizedBox(width: 4),
            PexIcon.uni('forward', size: 18, color: PexColors.greyC),
          ],
        ),
      ),
    );
  }

  /// 选集行的各身份计数（源项目遍历 `pactDict`）。
  Widget _pactCounters(Envar envar, Map<String, dynamic> user) {
    final Object? pact = envar.raw['pactDict'];
    if (pact is! Map) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final MapEntry<dynamic, dynamic> entry in pact.entries)
          if (entry.value is Map)
            _miniCounter(
              value: '${_intOf(user[(entry.value as Map)['counter']])}',
              label: LangText.fromMap((entry.value as Map)['pact_tag']),
              onTap: () => context.push(
                '/${AppRoutes.umyCollection}?tagnow=${entry.key}',
              ),
            ),
      ],
    );
  }

  /// 圈子行的三项计数（关注 / 粉丝 / 邀请）。
  Widget _circleCounters(String lang, Envar envar, Map<String, dynamic> user) {
    final Object? creator = envar.raw['Creator'];
    final Object? dict = creator is Map ? creator['myCircleDict'] : null;
    if (dict is! Map) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final MapEntry<dynamic, dynamic> entry in dict.entries)
          if (entry.value is Map)
            _miniCounter(
              value: '${_intOf(user[(entry.value as Map)['counter']])}',
              label: LangText.fromMap(entry.value),
              onTap: () => context.push(
                '/${AppRoutes.umyCircle}?tagnow=${entry.key}',
              ),
            ),
      ],
    );
  }

  Widget _miniCounter({
    required String value,
    required LangText label,
    required VoidCallback onTap,
  }) {
    final String lang = ref.watch(languageProvider);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: PexColors.grey9,
              ),
            ),
            Text(
              ll(lang, label),
              style: const TextStyle(fontSize: 11, color: PexColors.grey9),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 底部动作：退出 + 资源（居中）+ 重启
  // -------------------------------------------------------------------------

  Widget _bottomActions(String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 40),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              _outlineButton(
                icon: 'starhalf',
                color: PexColors.redMy,
                label: _kLogout,
                loading: _loadingLogout,
                onTap: () => _logout(ref.read(onlineUserProvider)),
              ),
              const Spacer(),
              _outlineButton(
                icon: 'refresh',
                color: PexColors.greenMy,
                label: _kRestart,
                onTap: _restart,
              ),
            ],
          ),
          _resourceCircle(lang),
        ],
      ),
    );
  }

  Widget _outlineButton({
    required String icon,
    required Color color,
    required LangText label,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    final String lang = ref.watch(languageProvider);
    return OutlinedButton.icon(
      onPressed: loading ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 40),
        textStyle: const TextStyle(fontSize: 14),
      ),
      icon: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : PexIcon.uni(icon, size: 22),
      label: Text(ll(lang, label)),
    );
  }

  /// 资源入口（源项目底部居中的蓝色圆按钮）。
  Widget _resourceCircle(String lang) {
    final LangText label =
        pageMetaOf('userResource')?.i18nListTitle ?? const LangText.from('');
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => context.push('/${AppRoutes.userResource}'),
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: PexColors.blueMy,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PexIcon.uni('more-filled', size: 24, color: Colors.white),
            Text(
              ll(lang, label),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 弹窗
// ---------------------------------------------------------------------------

/// 改昵称弹窗（源项目 `uni-popup-dialog`）：确认后把新昵称作为结果返回。
class _RenameDialog extends ConsumerStatefulWidget {
  const _RenameDialog({required this.initial, required this.title});

  final String initial;
  final LangText title;

  @override
  ConsumerState<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends ConsumerState<_RenameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    return AlertDialog(
      // 源项目弹窗底色为白色；M3 默认会给 surface 染上品牌色。
      backgroundColor: Colors.white,
      title: Text(ll(lang, widget.title)),
      content: TextField(
        controller: _controller,
        maxLength: 50,
        autofocus: true,
        decoration: InputDecoration(
          hintText: ll(lang, _kEnterNickname),
          counterText: '',
        ),
        onSubmitted: (String value) => Navigator.of(context).pop(value),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(ll(lang, PartTexts.cancel)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(ll(lang, _kConfirm)),
        ),
      ],
    );
  }
}

/// 自我介绍弹窗（源项目 `popAbout`：关闭按钮 + 标题 + story 编辑器 + 提交）。
class _AboutmeDialog extends ConsumerStatefulWidget {
  const _AboutmeDialog({required this.story});

  final List<Map<String, dynamic>> story;

  @override
  ConsumerState<_AboutmeDialog> createState() => _AboutmeDialogState();
}

class _AboutmeDialogState extends ConsumerState<_AboutmeDialog> {
  late List<Map<String, dynamic>> _story = widget.story;
  bool _loading = false;
  LangText? _feedback;

  Future<void> _submit() async {
    if (_loading) {
      showPexToast(context, ref, _kSubmittingAboutme);
      return;
    }
    setState(() {
      _loading = true;
      _feedback = null;
    });
    // 源项目 `wo.tt.filter_story`：去掉空段落（例如未填写的 `{text: ''}`）。
    final List<dynamic> cleaned = filterStory(_story);
    final Map<String, dynamic> data =
        await ref.read(userApiProvider).updateAboutme(cleaned);
    if (!mounted) return;
    setState(() => _loading = false);

    if (bok(data['_state']?.toString())) {
      ref.read(appStartupProvider.notifier).mergeOnlineUser(
            <String, dynamic>{'aboutme': data['aboutme'] ?? cleaned},
          );
      Navigator.of(context).pop();
      return;
    }
    final LangText message = LangText.fromMap(data['_msg']);
    setState(() => _feedback = message.isEmpty ? _kUpdateFailed : message);
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    return Dialog(
      backgroundColor: PexColors.bg,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 320,
          maxWidth: 600,
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PartCloseButton(onClose: () => Navigator.of(context).pop()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: Text(
                ll(lang, _kSelfIntro),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                // 源项目同样只允许编辑既有的那一段文字（不允许再加段落）。
                child: PartStoryEditor(
                  story: _story,
                  onStoryChanged: (List<Map<String, dynamic>> next) =>
                      setState(() => _story = next),
                  maxSections: 1,
                  allowText: false,
                  allowImage: false,
                ),
              ),
            ),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                child: Text(
                  ll(lang, _feedback!),
                  style: const TextStyle(fontSize: 12, color: PexColors.redMy),
                ),
              ),
            TextButton(
              onPressed: _loading ? null : _submit,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 60),
                shape: const RoundedRectangleBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (_loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    PexIcon.uni('paperplane-filled', size: 20),
                  const SizedBox(width: 6),
                  Text(
                    ll(lang, _kSubmit),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 小工具
// ---------------------------------------------------------------------------

/// 本人主页链接（源项目 `urlMyself`）：`https://goto.<域名>/creator/<haid 或 usid>?inhaid=<haid>`。
///
/// 域名取自品牌配置（源项目 `wo.ss.webDomain`），**不是**用户对象上的字段。
String _urlMyself(String webDomain, Map<String, dynamic> user) {
  final String haid = user['haid']?.toString() ?? '';
  final String usid = user['usid']?.toString() ?? '';
  return 'https://goto.$webDomain/creator/${haid.isEmpty ? usid : haid}?inhaid=$haid';
}

/// 自我介绍标题（源项目 `aboutmeTitle`）：取第一段的文字，并压掉换行。
String _aboutmeTitle(Map<String, dynamic> user) {
  final Object? aboutme = user['aboutme'];
  if (aboutme is! List || aboutme.isEmpty || aboutme.first is! Map) return '';
  final Object? text = (aboutme.first as Map)['text'];
  return text?.toString().trim().replaceAll(RegExp(r'\n+'), ' ') ?? '';
}

/// 实名状态短文案（源项目 `kycDict[kycStateL1].short`）。
String _kycLabel(String lang, Envar envar, Map<String, dynamic> user) {
  final Object? dict = envar.raw['kycDict'];
  final String stateL1 = user['kycStateL1']?.toString() ?? '';
  if (dict is Map) {
    final Object? entry = dict[stateL1];
    if (entry is Map && entry['short'] != null) {
      return ll(lang, LangText.fromMap(entry['short']));
    }
  }
  return ll(lang, _kWaitingKyc);
}

int _intOf(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _boolOf(Object? value) => value == true || value?.toString() == 'true';
