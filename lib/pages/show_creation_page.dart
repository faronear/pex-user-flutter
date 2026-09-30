/// 作品详情，对应源项目 `pages/showCreation.vue`（2227 行，全项目最大页）。
///
/// **分批迁移**：本轮为 **2A 只读骨架**，包含
/// 页面框架 / 「未找到作品」态（含编号搜索）/ 标题与日期 / 上下架提示 /
/// 封面（全部禁用态遮罩、内容渲染、加密封面）/ 作者头像 / 右栏周边（作者、IPFS、NFT、pact 只读信息）。
///
/// 尚未迁移（后续分片）：
/// 2B 评论与互动按钮、2C 付费解密/持有/收购与充值弹窗、2D 各类用户名单、
/// 2E 修改/上下架/删除、2F 分享与举报、2G 资源页。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/api_client.dart';
import '../core/api/creation_api.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_router.dart';
import '../core/state/creation_provider.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/creation_show_provider.dart';
import '../core/state/envar_provider.dart';
import '../core/state/region_provider.dart';
import '../core/util/feedback.dart';
import '../core/util/online_guard.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../data/creation.dart';
import '../theme/app_theme.dart';
import '../widgets/part_load_more.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_pay_sheet.dart';
import '../widgets/part_pexdata_summary.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_story_editor.dart';
import '../widgets/part_story_reader.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_user_list_sheet.dart';
import '../widgets/part_window_layout.dart';

class ShowCreationTexts {
  const ShowCreationTexts._();

  static const LangText pageTitle = LangText(
    zhCN: '作品秀',
    enUS: 'Creation Show',
    jaJP: '创作品詳細',
    deDE: 'Kreation Anzeigen',
  );

  static const LangText notFound = LangText(
    zhCN: '没有找到您指定的创作品！',
    enUS: 'Cannot find this creation!',
    jaJP: '创作品が見つかりません！',
    deDE: 'Kreation konnte nicht gefunden werden!',
  );

  static const LangText canSearch = LangText(
    zhCN: '您可以继续搜索',
    enUS: 'You can continue to search',
    deDE: 'Sie können weiter suchen',
    jaJP: '検索を続けることができます',
  );

  static const LangText creationId = LangText(
    zhCN: '创作品编号',
    enUS: 'Creation ID',
    jaJP: '创作品番号',
    deDE: 'Kreation-ID',
  );

  static const LangText unlistedByMe = LangText(
    zhCN: '您已下架了这个创作品',
    enUS: 'You have unlisted this creation',
  );

  static const LangText unlistedNotice = LangText(
    zhCN: '当前创作品已被下架',
    enUS: 'This creation was unlisted',
  );

  static const LangText refused = LangText(
    zhCN: '当前创作品已被拒绝服务',
    enUS: 'This creation was refused to serve',
  );

  static const LangText deletedByMe = LangText(
    zhCN: '当前创作品已被您彻底删除',
    enUS: 'This creation was permanently deleted by you',
  );

  static const LangText hiddenByMe = LangText(
    zhCN: '当前创作品已被您隐藏',
    enUS: 'This creation was hidden by you',
  );

  static const LangText blockedByMe = LangText(
    zhCN: '当前创作品的主人已被您屏蔽',
    enUS: "This creation's creator was blocked by you",
  );

  static const LangText unlistedMask = LangText(
    zhCN: '当前创作品已下架',
    enUS: 'This creation was unlisted from exhibition',
  );

  static const LangText censoring = LangText(
    zhCN: '尊敬的中国地区用户，\n由于中国当地法规，\n每个资源都要通过审查，\n请您耐心等候，\n或者请从海外进行访问。',
    enUS:
        'Dear users in China, according to your government policy requirements, each resource must be censored. Please wait for a few hours, or visit this page from any oversea location.',
  );

  static const LangText noContent = LangText(zhCN: '没有内容', enUS: 'No Content');

  static const LangText actionComment =
      LangText(zhCN: '评论', enUS: 'Comment', jaJP: 'コメント', deDE: 'Kommentieren');

  static const LangText commentEmpty = LangText(
    zhCN: '评论是空的。请先写点儿什么！',
    enUS: 'Comment is empty. Please write something!',
    jaJP: 'コメントが空です。何か書いてください！',
    deDE: 'Kommentar ist leer. Bitte schreiben Sie etwas!',
  );

  static const LangText commentPublished = LangText(
    zhCN: '您的评论已发表。',
    enUS: 'Your comment is published.',
    jaJP: 'あなたのコメントは公開されました。',
    deDE: 'Ihr Kommentar wurde veröffentlicht.',
  );

  static const LangText refreshComments = LangText(
    zhCN: '刷新评论列表',
    enUS: 'Refresh Comments',
  );

  static const LangText deleteCommentTitle = LangText(
    zhCN: '删除这个评论吗？',
    enUS: 'Delete this comment?',
    jaJP: 'このコメントを削除しますか？',
    deDE: 'Diesen Kommentar löschen?',
  );

  static const LangText deleteConfirm =
      LangText(zhCN: '删除', enUS: 'Delete', jaJP: '削除', deDE: 'Löschen');

  static const LangText commentDeleted = LangText(
    zhCN: '已成功删除',
    enUS: 'Deleted successfully',
    jaJP: '削除しました',
    deDE: 'Erfolgreich gelöscht',
  );

  static const LangText commentDeleteFailed = LangText(
    zhCN: '发生故障，没有删除',
    enUS: 'Something malfunctioned, this comment is not deleted',
    jaJP: 'エラーが発生し、削除できませんでした',
    deDE: 'Es ist ein Fehler aufgetreten, dieser Kommentar wurde nicht gelöscht',
  );

  static const LangText decrypt = LangText(
    zhCN: '解 密',
    enUS: 'Decrypt',
    jaJP: '解読',
    deDE: 'Entschlüsseln',
  );

  static const LangText decrypted = LangText(
    zhCN: '您已成功解密当前创作品！',
    enUS: 'You have decrypted this creation!',
  );

  static const LangText held = LangText(
    zhCN: '您已成功获得这个创作品！',
    enUS: 'You have obtained this creation!',
  );

  static const LangText owned = LangText(
    zhCN: '您已成功收购了这个创作品！',
    enUS: 'You have owned this creation!',
  );

  static const LangText fueled = LangText(zhCN: '已成功为它赞赏', enUS: 'Fueled');

  static const LangText buy = LangText(zhCN: '购 买', enUS: 'Buy', jaJP: '購入');

  static const LangText acquire =
      LangText(zhCN: '收 购', enUS: 'Acquire', jaJP: '買収');

  static const LangText fuelAction = LangText(zhCN: '赞赏', enUS: 'Fuel', jaJP: '燃料');

  static const LangText fuelPrompt = LangText(
    zhCN: '请输入赞赏金额',
    enUS: 'Enter the amount to fuel',
    jaJP: '入金額を入力してください',
    deDE: 'Geben Sie den Betrag zum Tanken ein',
  );

  static const LangText fuelTitle = LangText(
    zhCN: '为创作品赞赏',
    enUS: 'Fuel the Creation',
  );

  static const LangText fuelNotes = LangText(
    zhCN: '喜欢它，就为它赞赏！\n您还可以修改赞赏金额，表达您的强烈支持。\n请注意，赞赏后无法撤销。',
    enUS:
        'Like it? Fuel it!\nYou can modify the fuel amount to express your strong support. Please be reminded that fueling is irreversible.',
  );
}

/// 页面入口参数（对应源项目 `onLoad` 的 query）。
class ShowCreationPage extends ConsumerStatefulWidget {
  const ShowCreationPage({super.key, this.queryParameters = const <String, String>{}});

  /// `unid` / `csid` / `pexdataCidHash` / `nftToid` / `pexBaseCid` / `mintTxHash`。
  final Map<String, String> queryParameters;

  @override
  ConsumerState<ShowCreationPage> createState() => _ShowCreationPageState();
}

class _ShowCreationPageState extends ConsumerState<ShowCreationPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 50), _load);
  }

  @override
  void didUpdateWidget(covariant ShowCreationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryParameters['unid'] != widget.queryParameters['unid']) {
      _load();
    }
  }

  Future<void> _load() async {
    await ref.read(appStartupProvider.notifier).waitAutologin();
    if (!mounted) return;
    final Map<String, String> query = widget.queryParameters;
    await ref.read(creationShowProvider.notifier).load(
          csid: _pick(query, const <String>['csid', 'unid']),
          pexdataCidHash: _pick(query, const <String>['pexdataCidHash', 'pexdatacidhash']),
          nftToid: _pick(query, const <String>['nftToid', 'nfttoid']),
          pexBaseCid: _pick(query, const <String>['pexBaseCid', 'pexbasecid']),
          mintTxHash: _pick(query, const <String>['mintTxHash', 'minttxhash']),
          unid: _pick(query, const <String>['unid']),
        );
  }

  static String? _pick(Map<String, String> query, List<String> keys) {
    for (final String key in keys) {
      final String value = query[key] ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final CreationShowState show = ref.watch(creationShowProvider);
    final DeviceInfo device = DeviceInfo.of(context);
    final Envar envar = ref.watch(envarProvider);
    final double width = MediaQuery.sizeOf(context).width;
    final bool twoCol =
        envar.boolOf('responsive', true) && !device.inPhone && width > 800;

    return PartWindowLayout(
      pageName: AppRoutes.showCreation,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: twoCol ? 1600 : 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 10),
                if (device.inPc)
                  PartNavibarPcFixed(
                    title: ShowCreationTexts.pageTitle,
                    backToPage: AppRoutes.menuCreation,
                    pageName: AppRoutes.showCreation,
                  ),
                if (!show.readyShow)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: PartShowLoading(),
                  )
                else if (!show.found)
                  const _NotFoundView()
                else
                  _FoundView(twoCol: twoCol),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 未找到作品
// ---------------------------------------------------------------------------

class _NotFoundView extends ConsumerStatefulWidget {
  const _NotFoundView();

  @override
  ConsumerState<_NotFoundView> createState() => _NotFoundViewState();
}

class _NotFoundViewState extends ConsumerState<_NotFoundView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final String unid = _controller.text.trim();
    if (unid.isEmpty) return;
    ref.read(creationShowProvider.notifier).clear();
    context.pushReplacement('/${AppRoutes.showCreation}?unid=$unid');
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final TextEditingController controller = _controller;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 20),
          Text(
            ll(lang, ShowCreationTexts.notFound),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 2),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 5),
            child: Text(
              ll(lang, ShowCreationTexts.canSearch),
              style: const TextStyle(fontSize: 14, color: PexColors.subtext),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: ll(lang, ShowCreationTexts.creationId),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: PexColors.border),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _search,
                child: Container(
                  height: 40,
                  width: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF007BFF),
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                  ),
                  child: Center(
                    child: PexIcon.uni('search', size: 22, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 找到作品
// ---------------------------------------------------------------------------

class _FoundView extends ConsumerWidget {
  const _FoundView({required this.twoCol});

  final bool twoCol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CreationShowState show = ref.watch(creationShowProvider);
    final Creation creation = show.creation;
    final String lang = ref.watch(languageProvider);
    final String usid = ref.watch(onlineUserProvider)['usid']?.toString() ?? '';

    final bool unlistedByMe = creation.unlistedByMe(usid);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Text(
                creation.displayTitle(lang),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
            child: Text(
              formatDate(creation.createTimeUnix, 'yyyy-mm-dd'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: PexColors.subtext),
            ),
          ),
          if (!creation.bannedBySystem)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _unlistedNotice(creation, lang, unlistedByMe),
              ),
            ),
          if (twoCol)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 6, child: _LeftColumn(creation: creation, twoCol: true)),
                const SizedBox(width: 15),
                Expanded(
                  flex: 4,
                  child: _SurroundingsPanel(creation: creation, twoCol: true),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _LeftColumn(creation: creation, twoCol: false),
                const SizedBox(height: 30),
                _SurroundingsPanel(creation: creation, twoCol: false),
              ],
            ),
        ],
      ),
    );
  }

  Widget _unlistedNotice(Creation creation, String lang, bool unlistedByMe) {
    final LangText? text = unlistedByMe
        ? ShowCreationTexts.unlistedByMe
        : (creation.unlistedByOwner && creation.linkedByMe
            ? ShowCreationTexts.unlistedNotice
            : null);
    if (text == null) return const SizedBox.shrink();
    return Text(
      ll(lang, text),
      textAlign: TextAlign.center,
      style: const TextStyle(color: PexColors.redMy, fontSize: 14),
    );
  }
}

/// 左栏：封面 + 手机端作者头像（源项目「创作品自身」）。
class _LeftColumn extends StatelessWidget {
  const _LeftColumn({required this.creation, required this.twoCol});

  final Creation creation;
  final bool twoCol;

  @override
  Widget build(BuildContext context) {
    final bool showAvatar = !twoCol && creation.creatorUsid.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        _CoverPanel(creation: creation),
        if (showAvatar)
          Positioned(
            right: 10,
            bottom: -35,
            child: _AuthorAvatar(creation: creation, size: 70, iconSize: 30),
          ),
      ],
    );
  }
}

/// 封面（含全部禁用态遮罩）。
class _CoverPanel extends ConsumerWidget {
  const _CoverPanel({required this.creation});

  final Creation creation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final String usid = ref.watch(onlineUserProvider)['usid']?.toString() ?? '';
    final String userlandCode = ref.watch(userlandCodeProvider);
    final List<String> banChina = (envar.raw['banChina'] as List?)
            ?.map((dynamic e) => e.toString())
            .toList() ??
        const <String>[];

    final ShowCoverKind kind = creation.showCoverKind(
      usid: usid,
      userlandCode: userlandCode,
      banChina: banChina,
    );

    return switch (kind) {
      ShowCoverKind.refused =>
        _DisabledPanel(text: ll(lang, ShowCreationTexts.refused)),
      ShowCoverKind.deletedByMe =>
        _DisabledPanel(text: ll(lang, ShowCreationTexts.deletedByMe)),
      ShowCoverKind.hidden =>
        _DisabledPanel(text: ll(lang, ShowCreationTexts.hiddenByMe)),
      ShowCoverKind.blocked =>
        _DisabledPanel(text: ll(lang, ShowCreationTexts.blockedByMe)),
      ShowCoverKind.unlisted =>
        _DisabledPanel(text: ll(lang, ShowCreationTexts.unlistedMask)),
      ShowCoverKind.censoring =>
        _DisabledPanel(text: ll(lang, ShowCreationTexts.censoring)),
      ShowCoverKind.content => _contentCover(lang),
      ShowCoverKind.locked => _lockedCover(context, ref),
    };
  }

  /// 有内容：可选封面图 + 内容（story）或「没有内容」。
  Widget _contentCover(String lang) {
    return Stack(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (creation.openCover.isNotEmpty)
              ServerImage(creation.openCover, fit: BoxFit.fitWidth, width: double.infinity),
            if (creation.autocontent)
              Container(
                height: 40,
                alignment: Alignment.center,
                child: Text(
                  ll(lang, ShowCreationTexts.noContent),
                  style: const TextStyle(fontSize: 14, color: PexColors.subtext),
                ),
              )
            else
              PartStoryReader(story: creation.story),
          ],
        ),
        if (creation.unlistedByOwner)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x80000000),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    );
  }

  /// 已加密：方形容器 + 封条文字 + 半透明遮罩（摘要 + 解密按钮）。
  ///
  /// 背景优先用封面图，否则用 `static/matrix7.jpg`（与源项目一致，绿色封条文字才可见）。
  Widget _lockedCover(BuildContext context, WidgetRef ref) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (creation.openCover.isNotEmpty)
              ServerImage(creation.openCover, fit: BoxFit.cover)
            else
              Image.asset(
                'assets/static/matrix7.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(color: PexColors.greenMy),
              ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: Text(
                creation.openCover.isEmpty ? creation.sealText : '',
                style: const TextStyle(
                  color: PexColors.greenMy,
                  fontSize: 16,
                  letterSpacing: 20,
                  height: 1.9,
                ),
              ),
            ),
            if (!creation.viewerPact.forbidden)
              ColoredBox(
                color: const Color(0x99000000),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // 源项目的解密按钮就在这个遮罩里（2C 才真正可用）。
                      InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () => payToViewAction(context, ref, creation),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              PexIcon.uni('eye', size: 22, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                ll(ref.watch(languageProvider),
                                    ShowCreationTexts.decrypt),
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PartPexdataSummary(pexdataSum: creation.pexdataSum),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 方形深色遮罩 + 红色居中说明（源项目 `.locDisabledPanel` / `.locDisabledCover`）。
class _DisabledPanel extends StatelessWidget {
  const _DisabledPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x33000000), blurRadius: 5),
          ],
        ),
        padding: const EdgeInsets.all(5),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: PexColors.redMy, fontSize: 16, height: 1.9),
        ),
      ),
    );
  }
}

/// 作者头像（点击进入创作者主页）。
class _AuthorAvatar extends ConsumerWidget {
  const _AuthorAvatar({required this.creation, required this.size, required this.iconSize});

  final Creation creation;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/showCreator?unid=${creation.creatorUsid}'),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0xB3000000), blurRadius: 10, offset: Offset(2, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: creation.portrait.isEmpty
            ? Center(
                child: PexIcon.uni('person', size: iconSize, color: const Color(0xFFD3D3D3)),
              )
            : ServerImage(creation.portrait, fit: BoxFit.cover),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 右栏：创作品周边
// ---------------------------------------------------------------------------

class _SurroundingsPanel extends ConsumerWidget {
  const _SurroundingsPanel({required this.creation, required this.twoCol});

  final Creation creation;
  final bool twoCol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (creation.pexBaseCidRoot.isEmpty) return const SizedBox.shrink();
    final Map<String, dynamic> pactDict =
        (ref.watch(envarProvider).raw['pactDict'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final String usid = ref.watch(onlineUserProvider)['usid']?.toString() ?? '';
    // 源项目：被彻底删除或被拒绝服务的作品不再显示互动区。
    final bool interactable =
        !creation.bannedBySystem && !creation.deletedByMe(usid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.fromLTRB(0, 2, 0, 10),
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: PexColors.bg,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x33000000), blurRadius: 5)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (creation.creatorUsid.isNotEmpty)
                _AuthorRow(creation: creation, twoCol: twoCol),
              _IpfsRow(creation: creation),
              if (_urlNft(ref, creation).isNotEmpty) _NftRow(creation: creation),
              if (pactDict['TVIEW'] != null)
                _PactRow(
                  creation: creation,
                  pactKey: 'TVIEW',
                  pact: creation.viewerPact,
                  onPay: () => payToViewAction(context, ref, creation),
                  onShowList: creation.belongToMe(usid)
                      ? () => showViewerListAction(context, ref, creation)
                      : null,
                ),
              if (pactDict['THOLD'] != null)
                _PactRow(
                  creation: creation,
                  pactKey: 'THOLD',
                  pact: creation.holderPact,
                  onPay: () => payToHoldAction(context, ref, creation),
                  onShowList: creation.belongToMe(usid)
                      ? () => showHolderListAction(context, ref, creation)
                      : null,
                ),
              if (pactDict['TWORK'] != null)
                _PactRow(creation: creation, pactKey: 'TWORK', pact: creation.workerPact),
              if (pactDict['TOWN'] != null)
                _PactRow(
                  creation: creation,
                  pactKey: 'TOWN',
                  pact: creation.ownerPact,
                  onPay: () => payToOwnAction(context, ref, creation),
                ),
            ],
          ),
        ),
        // 互动区（源项目里位于「创作品周边」栏内）：评论发表 + 评论列表。
        if (interactable) _CommentArea(creation: creation),
      ],
    );
  }
}

/// 通用信息行（源项目 `uni-list-item`）。
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.leading, this.body});

  final Widget leading;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PexColors.greyE, width: 0.5)),
      ),
      child: Row(
        children: <Widget>[
          leading,
          if (body != null) Expanded(child: body!),
        ],
      ),
    );
  }
}

class _AuthorRow extends ConsumerWidget {
  const _AuthorRow({required this.creation, required this.twoCol});

  final Creation creation;
  final bool twoCol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!twoCol) {
      return _InfoRow(
        leading: const SizedBox.shrink(),
        body: Align(
          alignment: Alignment.centerRight,
          child: Text(
            creation.nickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PexColors.blueMy,
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return _InfoRow(
      leading: GestureDetector(
        onTap: () => context.push('/showCreator?unid=${creation.creatorUsid}'),
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(right: 5),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(color: Color(0x4D000000), blurRadius: 5, offset: Offset(2, 2)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: creation.portrait.isEmpty
              ? Center(
                  child: PexIcon.uni('person', size: 24, color: const Color(0xFFD3D3D3)),
                )
              : ServerImage(creation.portrait, fit: BoxFit.cover),
        ),
      ),
      body: Text(
        creation.nickname,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: PexColors.blueMy, fontSize: 14),
      ),
    );
  }
}

class _IpfsRow extends ConsumerWidget {
  const _IpfsRow({required this.creation});

  final Creation creation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final String url = _urlIpfs(envar, creation);
    return _InfoRow(
      leading: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Text(
          ll(lang, LangText.fromMap(envar.raw['byxCertName'])),
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: InkWell(
        onTap: url.isEmpty ? null : () => _openUrl(url),
        child: Row(
          children: <Widget>[
            PexIcon.icont('icont-hyperlink', size: 16, color: PexColors.blueMy),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                creation.pexBaseCidNow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: PexColors.blueMy, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NftRow extends ConsumerWidget {
  const _NftRow({required this.creation});

  final Creation creation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final String url = _urlNft(ref, creation);
    return _InfoRow(
      leading: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Text(
          ll(lang, LangText.fromMap(envar.raw['byxTokenName'])),
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: InkWell(
        onTap: url.isEmpty ? null : () => _openUrl(url),
        child: Row(
          children: <Widget>[
            PexIcon.icont('icont-hyperlink', size: 16, color: PexColors.blueMy),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                creation.nftToid,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: PexColors.blueMy, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// pact（合约）只读行：阅览权 / 持有权 / 代理权 / 所有权。
class _PactRow extends ConsumerWidget {
  const _PactRow({
    required this.creation,
    required this.pactKey,
    required this.pact,
    this.onPay,
    this.onShowList,
  });

  final Creation creation;
  final String pactKey;
  final Pact pact;

  /// 点击「可付费」价格时的动作（解密 / 持有 / 收购）。
  final VoidCallback? onPay;

  /// 点击人数计数时的动作（我的作品 → 查看名单）。
  final VoidCallback? onShowList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final String usid = ref.watch(onlineUserProvider)['usid']?.toString() ?? '';
    final Map<String, dynamic> item = _pactItem(envar, pactKey);
    if (item.isEmpty) return const SizedBox.shrink();

    final bool isOwnerPact = pactKey == 'TOWN';
    final bool mine = isOwnerPact
        ? (usid.isNotEmpty && creation.ownerUsid == usid)
        : (creation.belongToMe(usid) || _myAmount(creation, pactKey) != null);
    final bool active = isOwnerPact
        ? mine
        : (creation.belongToMe(usid) ||
            _myAmount(creation, pactKey) != null ||
            (!pact.forbidden && pact.amount == 0));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: active ? PexColors.greenLight : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PexIcon(
                PexIcons.byPrefix(item['iconPrefix']?.toString(), item['iconType']?.toString()),
                size: 20,
                color: PexColors.grey3,
              ),
              const SizedBox(width: 5),
              Text(
                ll(lang, LangText.fromMap(item['pact_tag'])),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          Expanded(child: _pactBody(lang, item)),
          _pactFooter(lang, envar, item, mine),
        ],
      ),
    );
  }

  Widget _pactBody(String lang, Map<String, dynamic> item) {
    if (pactKey == 'TWORK') {
      if (pact.share == 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: PexColors.greyE,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text('%${pact.share}', style: const TextStyle(fontSize: 16)),
        ),
      );
    }

    if (pact.forbidden) return const SizedBox.shrink();
    if (pactKey == 'TVIEW') {
      if (pact.amount == 0) return const SizedBox.shrink();
      return _counter(
        icon: PexIcons.uni('staff'),
        count: creation.countViewer,
      );
    }
    if (pactKey == 'THOLD') {
      final num? stock = creation.stockNumber;
      final String stockText = stock == null
          ? ll(lang, LangText.fromMap(item['HOLD_QUOTA_INFINITE']))
          : numberPrecision(stock).toString();
      return _counter(
        icon: PexIcons.uni('staff'),
        count: creation.countHolder,
        extra: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Text('/', style: _counterStyle),
            ),
            PexIcon.icont('icont-quota', size: 14, color: PexColors.greyA),
            const SizedBox(width: 2),
            Text(stockText, style: _counterStyle),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// 人数计数：传了 [onShowList] 才可点（源项目 `.locCounterActive`）。
  Widget _counter({required PexGlyph? icon, required int count, Widget? extra}) {
    final bool active = onShowList != null && count > 0;
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PexIcon(icon, size: 18, color: active ? PexColors.blueMy : PexColors.greyA),
        const SizedBox(width: 2),
        Text('$count', style: active ? _counterActiveStyle : _counterStyle),
        ?extra,
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: active
          ? InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: onShowList,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: content,
              ),
            )
          : content,
    );
  }

  Widget _pactFooter(
    String lang,
    Envar envar,
    Map<String, dynamic> item,
    bool mine,
  ) {
    final String tucSymbol = envar.tucSymbol;

    // 所有权：无价格即禁止（源项目对老数据强制如此）。
    if (pactKey == 'TOWN' && (pact.type.isEmpty || pact.forbidden || pact.amount == 0)) {
      return _tag(lang, LangText.fromMap(item['OWN_FORBIDDEN']));
    }
    if (pact.forbidden) {
      return _tag(lang, LangText.fromMap(item[_forbiddenKey]));
    }
    if (pact.amount == 0 && pactKey != 'TOWN') {
      return _tag(lang, LangText.fromMap(item[_freeKey]));
    }

    final Widget price = _price(pact.amount, tucSymbol);
    if (mine) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          price,
          Text(
            formatDate(_myTime(creation, pactKey), 'yyyy-mm-dd'),
            style: const TextStyle(fontSize: 12, color: PexColors.greyA),
          ),
        ],
      );
    }
    // 持有权库存为 0 时不再显示价格（无货）。
    if (pactKey == 'THOLD' && creation.stockNumber == 0) {
      return price;
    }
    if (onPay == null) return price;
    return GestureDetector(onTap: onPay, child: _payablePrice(price));
  }

  String get _forbiddenKey => switch (pactKey) {
        'TVIEW' => 'VIEW_FORBIDDEN',
        'THOLD' => 'HOLD_FORBIDDEN',
        'TWORK' => 'WORK_FORBIDDEN',
        'TOWN' => 'OWN_FORBIDDEN',
        _ => 'VIEW_FORBIDDEN',
      };

  String get _freeKey => switch (pactKey) {
        'TVIEW' => 'VIEW_FREE',
        'THOLD' => 'HOLD_FREE',
        'TWORK' => 'WORK_FREE',
        _ => 'VIEW_FREE',
      };
}

const TextStyle _counterStyle = TextStyle(fontSize: 13, color: PexColors.greyA);

const TextStyle _counterActiveStyle =
    TextStyle(fontSize: 13, color: PexColors.blueMy);

Widget _tag(String lang, LangText text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        ll(lang, text),
        style: const TextStyle(color: PexColors.redMy, fontSize: 13),
      ),
    );

Widget _price(num amount, String tucSymbol) => Text(
      '${numberPrecision(amount)}$tucSymbol',
      style: const TextStyle(fontSize: 18),
    );

Widget _payablePrice(Widget price) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: PexColors.blueMy,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        child: price,
      ),
    );

Map<String, dynamic> _pactItem(Envar envar, String key) {
  final Object? dict = envar.raw['pactDict'];
  if (dict is! Map) return <String, dynamic>{};
  final Object? item = dict[key];
  return item is Map ? item.cast<String, dynamic>() : <String, dynamic>{};
}

String _urlIpfs(Envar envar, Creation creation) {
  final String lens = envar.raw['ipfsLens']?.toString() ?? '';
  if (lens.isEmpty || creation.pexBaseCidNow.isEmpty) return '';
  return '${lens.replaceFirst(RegExp(r'/$'), '')}/${creation.pexBaseCidNow}';
}

String _urlNft(WidgetRef ref, Creation creation) {
  final String lens = ref.read(envarProvider).raw['nftLens']?.toString() ?? '';
  if (lens.isEmpty || !creation.hasNft) return '';
  return '${lens.replaceFirst(RegExp(r'/$'), '')}/nft/${creation.nftContract}/${creation.nftToid}';
}

Object? _myAmount(Creation creation, String pactKey) => switch (pactKey) {
      'TVIEW' => creation.raw['mytxView_txAmount'],
      'THOLD' => creation.raw['mytxHold_txAmount'],
      'TWORK' => creation.raw['mytxWork_txAmount'],
      'TOWN' => creation.raw['mytxOwn_txAmount'],
      _ => null,
    };

Object? _myTime(Creation creation, String pactKey) => switch (pactKey) {
      'TVIEW' => creation.raw['mytxView_txTimeUnix'],
      'THOLD' => creation.raw['mytxHold_txTimeUnix'],
      'TWORK' => creation.raw['mytxWork_txTimeUnix'],
      'TOWN' => creation.raw['mytxOwn_txTimeUnix'],
      _ => null,
    };

Future<void> _openUrl(String url) async {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

// ---------------------------------------------------------------------------
// 互动区：评论发表 + 评论列表（源项目 2B 片）
// ---------------------------------------------------------------------------

/// 评论发表与评论列表（源项目 `partStoryEditor` + `partLoadMore` + 评论列表）。
class _CommentArea extends ConsumerStatefulWidget {
  const _CommentArea({required this.creation});

  final Creation creation;

  @override
  ConsumerState<_CommentArea> createState() => _CommentAreaState();
}

class _CommentAreaState extends ConsumerState<_CommentArea> {
  static const int _takeLimit = 10;

  final FocusNode _textFocusNode = FocusNode();
  List<Map<String, dynamic>> _commentStory = <Map<String, dynamic>>[
    <String, dynamic>{'text': ''},
  ];
  bool _publishing = false;
  bool _refreshing = false;
  LoadState _olderState = LoadState.noMore;
  LangText? _feedback;

  @override
  void initState() {
    super.initState();
    final int initial =
        ref.read(creationShowProvider).commentList.length;
    _olderState = initial < _takeLimit ? LoadState.noMore : LoadState.loadUp;
  }

  @override
  void dispose() {
    _textFocusNode.dispose();
    super.dispose();
  }

  Creation get creation => widget.creation;

  /// 发布评论（源项目 `to_comment_creation`）。
  Future<void> _publish() async {
    if (!await checkOnline(context, ref)) return;
    final List<Map<String, dynamic>> story = _commentStory
        .map((Map<String, dynamic> section) =>
            Map<String, dynamic>.from(section))
        .toList();
    for (final Map<String, dynamic> section in story) {
      final String text = section['text']?.toString() ?? '';
      if (text.trim().isEmpty) section.remove('text');
    }
    story.removeWhere((Map<String, dynamic> section) => section.isEmpty);
    if (story.isEmpty) {
      setState(() => _feedback = ShowCreationTexts.commentEmpty);
      return;
    }

    setState(() {
      _publishing = true;
      _feedback = null;
    });
    final Map<String, dynamic> data =
        await ref.read(creationApiProvider).commentCreation(
              commentStory: story,
              commentTarget: creation.pexdataCidHashRoot,
              commentCsid: creation.csid,
            );
    if (!mounted) return;
    setState(() => _publishing = false);

    if (bok(data['_state']?.toString())) {
      final Map<String, dynamic> comment =
          (data['comment'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      final Map<String, dynamic> user = ref.read(onlineUserProvider);
      comment['nickname'] = user['nickname'];
      comment['portrait'] = user['portrait'];
      ref.read(creationShowProvider.notifier).prependComment(comment);
      ref.read(creationShowProvider.notifier).merge(<String, dynamic>{
        'countComment': creation.countComment + 1,
        'myCommentCount': _intOf(creation.raw['myCommentCount']) + 1,
      });
      setState(() {
        _commentStory = <Map<String, dynamic>>[<String, dynamic>{'text': ''}];
      });
      showPexToast(context, ref, ShowCreationTexts.commentPublished);
    } else {
      setState(() {
        _feedback = LangText.fromMap(data['rejectReason'] ?? data['_msg']);
        if (_feedback != null && _feedback!.isEmpty) {
          _feedback = PartTexts.systemDown;
        }
      });
    }
  }

  /// 刷新评论列表（源项目 `to_get_newest_comments`）。
  Future<void> _refreshComments() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final Map<String, dynamic> data =
        await ref.read(creationApiProvider).getCommentList(
              commentTarget: creation.pexdataCidHashRoot,
              commentCsid: creation.csid,
              takeLimit: _takeLimit,
            );
    if (!mounted) return;
    setState(() => _refreshing = false);
    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> list =
          (data['commentList'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];
      ref.read(creationShowProvider.notifier).setComments(list);
      setState(() =>
          _olderState = list.length < _takeLimit ? LoadState.noMore : LoadState.loadUp);
    } else {
      _showError(data);
    }
  }

  /// 加载更早的评论（源项目 `to_get_older_comments`；源实现为整表替换，这里改为追加）。
  Future<void> _olderComments() async {
    if (_olderState == LoadState.loading) return;
    setState(() => _olderState = LoadState.loading);
    final List<Map<String, dynamic>> current =
        ref.read(creationShowProvider).commentList;
    final int? beforeTime = current.isEmpty
        ? null
        : _intOf(current.last['commentTimeUnix']);
    final Map<String, dynamic> data =
        await ref.read(creationApiProvider).getCommentList(
              commentTarget: creation.pexdataCidHashRoot,
              commentCsid: creation.csid,
              beforeTime: beforeTime,
              takeLimit: _takeLimit,
            );
    if (!mounted) return;
    if (bok(data['_state']?.toString())) {
      final List<Map<String, dynamic>> list =
          (data['commentList'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];
      ref.read(creationShowProvider.notifier).appendComments(list);
      setState(() =>
          _olderState = list.length < _takeLimit ? LoadState.noMore : LoadState.loadUp);
    } else {
      setState(() => _olderState = LoadState.loadUp);
      _showError(data);
    }
  }

  /// 删除自己的评论（源项目 `to_delete_comment`）。
  Future<void> _deleteComment(Map<String, dynamic> comment, int index) async {
    if (!await checkOnline(context, ref)) return;
    if (!mounted) return;
    final String fromUsid = comment['commentFromUsid']?.toString() ?? '';
    final String usid = ref.read(onlineUserProvider)['usid']?.toString() ?? '';
    if (fromUsid.isEmpty || usid != fromUsid) return;

    final List<dynamic> story =
        (comment['commentStory'] as List?) ?? <dynamic>[];
    final String content = story.isNotEmpty && story.first is Map
        ? ((story.first as Map).values.isEmpty
            ? ''
            : (story.first as Map).values.first.toString())
        : '';
    final bool confirmed = await showPexModal(
      context,
      ref,
      title: ShowCreationTexts.deleteCommentTitle,
      content: content.isEmpty ? null : LangText.from(content),
      confirmText: ShowCreationTexts.deleteConfirm,
      showCancel: true,
    );
    if (!confirmed || !mounted) return;

    final Map<String, dynamic> data = await ref
        .read(creationApiProvider)
        .deleteComment(comment['commentUuid']?.toString() ?? '');
    if (!mounted) return;
    if (bok(data['_state']?.toString())) {
      ref.read(creationShowProvider.notifier).removeCommentAt(index);
      ref.read(creationShowProvider.notifier).merge(<String, dynamic>{
        'countComment': creation.countComment > 0 ? creation.countComment - 1 : 0,
      });
      showPexToast(context, ref, ShowCreationTexts.commentDeleted);
    } else {
      showPexToast(
        context,
        ref,
        LangText.fromMap(data['_msg']).isEmpty
            ? ShowCreationTexts.commentDeleteFailed
            : LangText.fromMap(data['_msg']),
      );
    }
  }

  void _showError(Map<String, dynamic> data) {
    final LangText message = LangText.fromMap(data['_msg']);
    showPexToast(
      context,
      ref,
      message.isEmpty ? PartTexts.systemDown : message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final List<Map<String, dynamic>> comments =
        ref.watch(creationShowProvider).commentList;
    final Map<String, dynamic> statDict =
        _statDict(ref.watch(envarProvider));
    final Map<String, dynamic> commentIcon =
        (statDict['comment'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final Map<String, dynamic> fuelIcon =
        (statDict['fuel'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final bool commented = creation.raw['myCommentCount'] != null;
    final String usid = ref.watch(onlineUserProvider)['usid']?.toString() ?? '';
    final bool belongToMe = creation.belongToMe(usid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // 操作按钮行：评论 + 赞赏（分享→2F，修改/隐藏/举报→2E；赞赏者名单→2D）。
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _ActionButton(
                icon: PexIcons.uni(
                  commented
                      ? (commentIcon['iconTypeOn']?.toString() ??
                          commentIcon['iconType']?.toString() ??
                          'chat')
                      : (commentIcon['iconType']?.toString() ?? 'chat'),
                ),
                label: creation.countComment > 0
                    ? '${creation.countComment}'
                    : ll(lang, ShowCreationTexts.actionComment),
                onTap: () => _textFocusNode.requestFocus(),
              ),
              // 自己的作品 → 赞赏者名单；他人作品 → 赞赏（源项目同一按钮两种行为）。
              _ActionButton(
                icon: PexIcons.uni(
                  creation.raw['mytxFuel_txAmount'] != null
                      ? (fuelIcon['iconTypeOn']?.toString() ??
                          fuelIcon['iconType']?.toString() ??
                          'heart')
                      : (fuelIcon['iconType']?.toString() ?? 'heart'),
                ),
                label: creation.amountFuel > 0
                    ? numberPrecision(creation.amountFuel).toString()
                    : ll(lang, ShowCreationTexts.fuelAction),
                onTap: () => belongToMe
                    ? showFuelerListAction(context, ref, creation)
                    : payToFuelAction(context, ref, creation),
              ),
              // 自己的作品：上架/下架（原创主或权利主均可）。
              if (belongToMe)
                _ActionButton(
                  icon: PexIcons.uni(
                    creation.unlistedByMe(usid) ? 'upload' : 'download',
                  ),
                  label: creation.unlistedByMe(usid)
                      ? ll(lang, const LangText(zhCN: '上架', enUS: 'List', deDE: 'Auflisten'))
                      : ll(lang, const LangText(zhCN: '下架', enUS: 'Unlist', deDE: 'Entfernen')),
                  onTap: () => toggleCreationListing(context, ref, creation),
                )
              else
                // 他人的作品：隐藏/显示（只对自己生效）。
                _ActionButton(
                  icon: PexIcons.uni(
                    creation.hideState == 'HIDED' ? 'eye' : 'eye-slash',
                  ),
                  label: creation.hideState == 'HIDED'
                      ? ll(lang, const LangText(zhCN: '显示', enUS: 'Show', jaJP: '表示', deDE: 'Anzeigen'))
                      : ll(lang, const LangText(zhCN: '隐藏', enUS: 'Hide', jaJP: '非表示', deDE: 'Ausblenden')),
                  onTap: () => toggleCreationHide(context, ref, creation),
                ),
              // 彻底删除：源项目按「本人下架」或「已隐藏」两种情形分别调用不同接口。
              if (envar.boolOf('ctnDeletable') &&
                  (belongToMe
                      ? creation.unlistedByMe(usid)
                      : creation.hideState == 'HIDED'))
                _ActionButton(
                  icon: PexIcons.uni('trash'),
                  label: ll(lang, const LangText(zhCN: '删除', enUS: 'Delete', jaJP: '削除', deDE: 'Löschen')),
                  onTap: () => deleteCreationAction(
                    context,
                    ref,
                    creation,
                    fromHide: !belongToMe,
                  ),
                ),
            ],
          ),
        ),

        // 评论编辑器（允许类型取自后台 `comment*` 配置）。
        PartStoryEditor(
          story: _commentStory,
          onStoryChanged: (List<Map<String, dynamic>> next) =>
              setState(() => _commentStory = next),
          allowText: envar.boolOf('commentText', true),
          allowImage: envar.boolOf('commentImage'),
          allowVideo: envar.boolOf('commentVideo'),
          allowAudio: envar.boolOf('commentSpeak'),
          allowFile: envar.boolOf('commentFile'),
          allowLink: envar.boolOf('commentLink'),
          maxSections: envar.intOf('commentMaxSections', 2),
          publishing: _publishing,
          onPublish: _publish,
          textFocusNode: _textFocusNode,
        ),
        if (_feedback != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 6, 5, 0),
            child: Text(
              ll(lang, _feedback!),
              style: const TextStyle(fontSize: 12, color: Color(0xFFDD6161)),
            ),
          ),

        // 刷新 + 评论列表 + 更早评论。
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextButton(
            onPressed: _refreshing ? null : _refreshComments,
            child: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    ll(lang, ShowCreationTexts.refreshComments),
                    style: const TextStyle(fontSize: 14),
                  ),
          ),
        ),
        for (int i = 0; i < comments.length; i++)
          _CommentItem(
            comment: comments[i],
            index: i,
            onDelete: () => _deleteComment(comments[i], i),
          ),
        if (comments.isNotEmpty)
          PartLoadMore(loadState: _olderState, onLoad: _olderComments),
        const SizedBox(height: 10),
      ],
    );
  }
}

/// 操作按钮（源项目 `.locActionButton`）。
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  final PexGlyph? icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PexIcon(icon, size: 30),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// 评论条目（源项目评论列表的 `uni-list-item`）。
class _CommentItem extends ConsumerWidget {
  const _CommentItem({
    required this.comment,
    required this.index,
    required this.onDelete,
  });

  final Map<String, dynamic> comment;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String usid = ref.watch(onlineUserProvider)['usid']?.toString() ?? '';
    final String fromUsid = comment['commentFromUsid']?.toString() ?? '';
    final String portrait = comment['portrait']?.toString() ?? '';
    final String nickname = comment['nickname']?.toString() ?? '';
    final List<dynamic> story =
        (comment['commentStory'] as List?) ?? <dynamic>[];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PexColors.greyE, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 作者头像（点击进创作者主页）。
          GestureDetector(
            onTap: () => context.push('/showCreator?unid=$fromUsid'),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 5),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[BoxShadow(color: Color(0x4D000000), blurRadius: 10)],
              ),
              clipBehavior: Clip.antiAlias,
              child: portrait.isEmpty
                  ? Center(
                      child: PexIcon.uni('person', size: 24, color: const Color(0xFFD3D3D3)),
                    )
                  : ServerImage(portrait, fit: BoxFit.cover),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => context.push('/showCreator?unid=$fromUsid'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: PexColors.blueMy,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      formatDate(comment['commentTimeUnix'], 'yyyy-mm-dd HH:MM'),
                      style: const TextStyle(fontSize: 12, color: PexColors.grey9),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: PartStoryReader(story: story),
                      ),
                    ),
                    if (usid.isNotEmpty && usid == fromUsid)
                      IconButton(
                        padding: const EdgeInsets.all(5),
                        constraints: const BoxConstraints(minWidth: 36),
                        icon: PexIcon.uni('trash', size: 20),
                        onPressed: onDelete,
                      ),
                  ],
                ),
              ],
            ),
          ),
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

num _numOf(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

/// 取 `Creation.uiStatDict`（服务端不发，来自本地预置层）。
Map<String, dynamic> _statDict(Envar envar) {
  final Object? creation = envar.raw['Creation'];
  final Object? dict = creation is Map ? creation['uiStatDict'] : null;
  return dict is Map ? dict.cast<String, dynamic>() : <String, dynamic>{};
}

// ---------------------------------------------------------------------------
// 付费动作（源项目 to_pay_to_view / to_pay_to_hold / to_pay_to_own / to_fuel_creation）
// ---------------------------------------------------------------------------

/// 统一的付费结果处理：成功则回写作品状态与余额并提示，失败则返回原因展示在弹窗内。
Future<LangText?> _handlePayResult(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> data,
  Map<String, dynamic> patch,
  LangText success, {
  num spent = 0,
}) {
  if (bok(data['_state']?.toString())) {
    ref.read(creationShowProvider.notifier).merge(patch);
    _syncBalance(ref, data, spent);
    if (context.mounted) showPexToast(context, ref, success);
    return Future<LangText?>.value(null);
  }
  _syncBalance(ref, data, 0);
  final LangText message = LangText.fromMap(data['_msg']);
  return Future<LangText?>.value(
    message.isEmpty ? PartTexts.systemDown : message,
  );
}

/// 后端返回 `balanceTUC` 时以之为准；否则按源项目用「扣减」方式本地估算。
void _syncBalance(WidgetRef ref, Map<String, dynamic> data, num spent) {
  final Object? reported = data['balanceTUC'];
  if (reported != null) {
    ref.read(appStartupProvider.notifier).mergeOnlineUser(
      <String, dynamic>{'balanceTUC': reported},
    );
    return;
  }
  if (spent == 0) return;
  final num now = _numOf(ref.read(onlineUserProvider)['balanceTUC']);
  ref.read(appStartupProvider.notifier).mergeOnlineUser(
    <String, dynamic>{'balanceTUC': now - spent},
  );
}

/// 付费解密。
Future<void> payToViewAction(
  BuildContext context,
  WidgetRef ref,
  Creation creation,
) async {
  if (!await checkOnline(context, ref)) return;
  if (!context.mounted) return;
  final Map<String, dynamic> view = _pactItem(ref.read(envarProvider), 'TVIEW');
  await showPaySheet(
    context,
    ref,
    title: LangText.fromMap(view['VIEW_PAYTITLE']),
    notes: LangText.fromMap(view['VIEW_PAYNOTES']),
    amountInit: creation.viewerPact.amount,
    submitText: ShowCreationTexts.decrypt,
    onSubmit: (num amount) async {
      final Map<String, dynamic> data =
          await ref.read(creationApiProvider).payToView(creation.csid);
      if (!context.mounted) return null;
      return _handlePayResult(
        context,
        ref,
        data,
        <String, dynamic>{
          if (data['pexdataUser'] != null) 'pexdataUser': data['pexdataUser'],
          'countViewer': creation.countViewer + 1,
          'mytxView_txAmount': amount,
          'mytxView_txTimeUnix': DateTime.now().millisecondsSinceEpoch,
        },
        ShowCreationTexts.decrypted,
        spent: amount,
      );
    },
  );
}

/// 付费持有。
Future<void> payToHoldAction(
  BuildContext context,
  WidgetRef ref,
  Creation creation,
) async {
  if (!await checkOnline(context, ref)) return;
  if (!context.mounted) return;
  final Map<String, dynamic> hold = _pactItem(ref.read(envarProvider), 'THOLD');
  await showPaySheet(
    context,
    ref,
    title: LangText.fromMap(hold['HOLD_PAYTITLE']),
    notes: LangText.fromMap(hold['HOLD_PAYNOTES']),
    amountInit: creation.holderPact.amount,
    submitText: ShowCreationTexts.buy,
    onSubmit: (num amount) async {
      final Map<String, dynamic> data =
          await ref.read(creationApiProvider).payToHold(creation.csid);
      if (!context.mounted) return null;
      return _handlePayResult(
        context,
        ref,
        data,
        <String, dynamic>{
          'countHolder': creation.countHolder + 1,
          'mytxHold_txAmount': amount,
          'mytxHold_txTimeUnix': DateTime.now().millisecondsSinceEpoch,
        },
        ShowCreationTexts.held,
        spent: amount,
      );
    },
  );
}

/// 付费收购（后端会把 `ownerUsid` 改为买家）。
Future<void> payToOwnAction(
  BuildContext context,
  WidgetRef ref,
  Creation creation,
) async {
  if (!await checkOnline(context, ref)) return;
  if (!context.mounted) return;
  final Map<String, dynamic> own = _pactItem(ref.read(envarProvider), 'TOWN');
  final String usid = ref.read(onlineUserProvider)['usid']?.toString() ?? '';
  await showPaySheet(
    context,
    ref,
    title: LangText.fromMap(own['OWN_PAYTITLE']),
    notes: LangText.fromMap(own['OWN_PAYNOTES']),
    amountInit: creation.ownerPact.amount,
    submitText: ShowCreationTexts.acquire,
    onSubmit: (num amount) async {
      final Map<String, dynamic> data =
          await ref.read(creationApiProvider).payToOwn(creation.csid);
      if (!context.mounted) return null;
      return _handlePayResult(
        context,
        ref,
        data,
        <String, dynamic>{
          'ownerUsid': usid,
          'mytxOwn_txAmount': amount,
          'mytxOwn_txTimeUnix': DateTime.now().millisecondsSinceEpoch,
        },
        ShowCreationTexts.owned,
        spent: amount,
      );
    },
  );
}

/// 赞赏（金额可改，不得少于 `priceFuelDefault`）。
Future<void> payToFuelAction(
  BuildContext context,
  WidgetRef ref,
  Creation creation,
) async {
  if (!await checkOnline(context, ref)) return;
  if (!context.mounted) return;
  final Envar envar = ref.read(envarProvider);
  final num minAmount = _numOf(envar.raw['priceFuelDefault']);
  final Map<String, dynamic> fuel = _statDict(envar)['fuel'] is Map
      ? (_statDict(envar)['fuel'] as Map).cast<String, dynamic>()
      : <String, dynamic>{};
  await showPaySheet(
    context,
    ref,
    title: ShowCreationTexts.fuelTitle,
    notes: ShowCreationTexts.fuelNotes,
    amountInit: minAmount,
    amountEditable: true,
    amountPrompt: ShowCreationTexts.fuelPrompt,
    submitText: ShowCreationTexts.fuelAction,
    submitIcon: PexIcons.byPrefix(
      fuel['iconPrefix']?.toString(),
      fuel['iconType']?.toString(),
    ),
    onSubmit: (num amount) async {
      if (amount < minAmount) {
        return LangText.from(
          '${ll(ref.read(languageProvider), ShowCreationTexts.fuelPrompt)}'
          ' (>= $minAmount${envar.tucSymbol})',
        );
      }
      final Map<String, dynamic> data =
          await ref.read(creationApiProvider).payToFuel(
                csid: creation.csid,
                amount: amount,
              );
      if (!context.mounted) return null;
      return _handlePayResult(
        context,
        ref,
        data,
        <String, dynamic>{
          'amountFuel': creation.amountFuel + amount,
          'mytxFuel_txAmount': _numOf(creation.raw['mytxFuel_txAmount']) + amount,
        },
        ShowCreationTexts.fueled,
        spent: amount,
      );
    },
  );
}

// ---------------------------------------------------------------------------
// 名单动作（源项目 show_viewer_list / show_holder_list / show_fueler_list）
// ---------------------------------------------------------------------------

/// 解密者名单（仅作品相关人可看）。
Future<void> showViewerListAction(
  BuildContext context,
  WidgetRef ref,
  Creation creation,
) async {
  final Envar envar = ref.read(envarProvider);
  final Map<String, dynamic> item = _pactItem(envar, 'TVIEW');
  await showUserListSheet(
    context,
    ref,
    title: LangText.fromMap(item['VIEWER_LIST']),
    listKey: 'viewerList',
    timeKey: 'txTimeUnix',
    timeIcon: item['iconType']?.toString() ?? '',
    timePrefix: item['iconPrefix']?.toString() ?? '',
    fetch: (int? beforeTime) => ref.read(creationApiProvider).getViewerList(
          csid: creation.csid,
          beforeTime: beforeTime,
        ),
  );
}

/// 持有者名单。
Future<void> showHolderListAction(
  BuildContext context,
  WidgetRef ref,
  Creation creation,
) async {
  final Envar envar = ref.read(envarProvider);
  final Map<String, dynamic> item = _pactItem(envar, 'THOLD');
  await showUserListSheet(
    context,
    ref,
    title: LangText.fromMap(item['HOLDER_LIST']),
    listKey: 'holderList',
    timeKey: 'txTimeUnix',
    timeIcon: item['iconType']?.toString() ?? '',
    timePrefix: item['iconPrefix']?.toString() ?? '',
    fetch: (int? beforeTime) => ref.read(creationApiProvider).getHolderList(
          csid: creation.csid,
          beforeTime: beforeTime,
        ),
  );
}

/// 赞赏者名单。
Future<void> showFuelerListAction(
  BuildContext context,
  WidgetRef ref,
  Creation creation,
) async {
  await showUserListSheet(
    context,
    ref,
    title: const LangText(
      zhCN: '赞赏者',
      enUS: 'Who fueled it',
      deDE: 'Wer hat es getankt',
      jaJP: '誰がこの创作品に燃料を入れましたか',
    ),
    listKey: 'fuelerList',
    timeKey: 'txTimeUnix',
    timeIcon: 'hand-up',
    fetch: (int? beforeTime) => ref.read(creationApiProvider).getFuelerList(
          csid: creation.csid,
          beforeTime: beforeTime,
        ),
  );
}

// ---------------------------------------------------------------------------
// 上下架 / 隐藏 / 删除（源项目 2E 片）
// ---------------------------------------------------------------------------

const LangText _kListTitle = LangText(
  zhCN: '重新上架这个创作品吗？',
  enUS: 'Restore this creation?',
);

const LangText _kListContent = LangText(
  zhCN: '重新上架这个创作品，让其他人能够发现它。',
  enUS: 'Restore this creation to exhibition and everyone will be able to find it.',
);

const LangText _kListConfirm = LangText(zhCN: '上架', enUS: 'List');

const LangText _kListed = LangText(zhCN: '已成功上架。', enUS: 'Listed successfully.');

const LangText _kListFailed = LangText(
  zhCN: '发生了故障，这个创作品没有完成上架。',
  enUS: 'Something malfuntioned, this creation is not listed.',
);

const LangText _kUnlistTitle = LangText(
  zhCN: '下架这个创作品吗？',
  enUS: 'Unlist this creation?',
  deDE: 'Diese Kreation entfernen?',
);

const LangText _kUnlistContent = LangText(
  zhCN: '这个创作品将被下架，其他人将无法浏览它。如果您将来改变了想法，您可以随时重新上架。',
  enUS:
      'This creation will be unlisted from your exhibition. Should you change mind in the future, you can list it again.',
);

const LangText _kUnlistConfirm = LangText(zhCN: '下架', enUS: 'Unlist', deDE: 'Entfernen');

const LangText _kUnlisted = LangText(
  zhCN: '已成功下架。',
  enUS: 'Unlisted successfully.',
);

const LangText _kUnlistFailed = LangText(
  zhCN: '发生故障，没有完成下架.',
  enUS: 'Something malfuntioned, this creation is not unlisted.',
);

const LangText _kHideTitle =
    LangText(zhCN: '隐藏这个创作品吗？', enUS: 'Hide this creation?', jaJP: 'この创作品を非表示にしますか？', deDE: 'Diese Kreation ausblenden?');

const LangText _kHideContent = LangText(
  zhCN: '当前创作品的内容将对您隐藏。',
  enUS: "You will no longer see this creation's content.",
  jaJP: 'この创作品は表示されなくなります。',
  deDE: 'Sie werden den Inhalt dieser Kreation nicht mehr sehen.',
);

const LangText _kHideContentRecallable = LangText(
  zhCN: '如果将来您改变了想法，您可以重新显示它。',
  enUS: ' Should you change mind in the future, you can show it again.',
  jaJP: '気が変わったら、いつでも表示を復元できます。',
  deDE: ' Wenn Sie Ihre Meinung ändern, können Sie sie wieder sichtbar machen.',
);

const LangText _kHideConfirm =
    LangText(zhCN: '隐藏', enUS: 'Hide', jaJP: '非表示', deDE: 'Ausblenden');

const LangText _kHidden = LangText(
  zhCN: '已成功隐藏。',
  enUS: 'Hidden successfully.',
  jaJP: '非表示にしました。',
  deDE: 'Erfolgreich ausgeblendet.',
);

const LangText _kHideFailed = LangText(
  zhCN: '发生了故障，这个创作品没有被隐藏。',
  enUS: 'Something malfuntioned, this creation is not hidden.',
);

const LangText _kShowTitle = LangText(
  zhCN: '重新显示这个创作品吗？',
  enUS: 'Show this creation?',
  jaJP: 'この创作品を表示しますか？',
  deDE: 'Diese Kreation sichtbar machen?',
);

const LangText _kShowContent = LangText(
  zhCN: '您将能够查看这个创作品的内容。如果您将来改变了想法，您可以随时再次隐藏它。',
  enUS:
      "You will be able to see this creation's content. Should you change mind in the future, you can hide it again at any time",
  jaJP: 'この创作品を表示できるようになります。気が変わったら、いつでも非表示にできます',
  deDE:
      'Sie können den Inhalt dieser Kreation sehen. Wenn Sie Ihre Meinung ändern, können Sie sie wieder ausblenden',
);

const LangText _kShowConfirm =
    LangText(zhCN: '显示', enUS: 'Show', jaJP: '表示', deDE: 'Anzeigen');

const LangText _kShowDone = LangText(
  zhCN: '这个创作品已重新显示。',
  enUS: 'This creation is shown successfully.',
);

const LangText _kShowFailed = LangText(
  zhCN: '发生了故障，这个创作品没有被重新显示。',
  enUS: 'Something malfuntioned, this creation is not reset to show.',
);

const LangText _kDeleteTitle = LangText(
  zhCN: '删除这个创作品吗？',
  enUS: 'Delete this creation?',
  jaJP: 'この创作品を完全に削除しますか？',
  deDE: 'Diese Kreation endgültig löschen?',
);

const LangText _kDeleteContent = LangText(
  zhCN: '删除后，这个创作品将从您的列表中消失，您无法再找回它。',
  enUS:
      'After deletion of this creation, it will no longer appear in your collections and you cannot recover it again.',
  jaJP: '完全に削除すると、この创作品はあなたのコレクションから消え、二度と表示できなくなります。',
  deDE:
      'Nach dem Löschen wird diese Kreation aus Ihren Sammlungen verschwinden und kann nicht wiederhergestellt werden.',
);

const LangText _kDeleteConfirm =
    LangText(zhCN: '删除', enUS: 'Delete', jaJP: '削除', deDE: 'Löschen');

const LangText _kDeleted = LangText(
  zhCN: '已成功删除。',
  enUS: 'Deleted successfully.',
  jaJP: '削除しました。',
  deDE: 'Erfolgreich gelöscht.',
);

const LangText _kDeleteFailed = LangText(
  zhCN: '发生了故障，这个创作品没有被删除。',
  enUS: 'Something malfuntioned, this creation is not deleted.',
);

/// 上架 / 下架（源项目 `to_toggle_creation_listing`）。
Future<void> toggleCreationListing(
  BuildContext context,
  WidgetRef ref,
  Creation creation,
) async {
  if (!await checkOnline(context, ref)) return;
  if (!context.mounted) return;
  final String usid = ref.read(onlineUserProvider)['usid']?.toString() ?? '';
  final bool unlisted = creation.unlistedByMe(usid);

  final bool confirmed = await showPexModal(
    context,
    ref,
    title: unlisted ? _kListTitle : _kUnlistTitle,
    content: unlisted ? _kListContent : _kUnlistContent,
    confirmText: unlisted ? _kListConfirm : _kUnlistConfirm,
    showCancel: true,
  );
  if (!confirmed || !context.mounted) return;

  final CreationApi api = ref.read(creationApiProvider);
  final Map<String, dynamic> data = unlisted
      ? await api.listCreation(creation.csid)
      : await api.unlistCreation(creation.csid);
  if (!context.mounted) return;

  if (!bok(data['_state']?.toString())) {
    showPexToast(context, ref, unlisted ? _kListFailed : _kUnlistFailed);
    return;
  }
  final Map<String, dynamic> updated =
      (data['creation'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

  // 源项目：更新 ownerState/creatorState；用户统计由 userUpdated 或本地增减。
  final Map<String, dynamic> patch = <String, dynamic>{
    if (updated['ownerState'] != null) 'ownerState': updated['ownerState'],
    if (updated['creatorState'] != null) 'creatorState': updated['creatorState'],
  };
  ref.read(creationShowProvider.notifier).merge(patch);
  ref.read(creationProvider.notifier).updateItem(creation.csid, patch);

  final Map<String, dynamic> userUpdated =
      (data['userUpdated'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
  if (userUpdated.isNotEmpty) {
    ref.read(appStartupProvider.notifier).mergeOnlineUser(userUpdated);
  } else {
    final Map<String, dynamic> user = ref.read(onlineUserProvider);
    ref.read(appStartupProvider.notifier).mergeOnlineUser(<String, dynamic>{
      'countCtnRemove': _intOf(user['countCtnRemove']) + (unlisted ? -1 : 1),
      'countCtnPublic': _intOf(user['countCtnPublic']) + (unlisted ? 1 : -1),
    });
  }
  showPexToast(context, ref, unlisted ? _kListed : _kUnlisted);
}

/// 隐藏 / 显示（源项目 `to_toggle_hide`）。
Future<void> toggleCreationHide(
  BuildContext context,
  WidgetRef ref,
  Creation creation,
) async {
  if (!await checkOnline(context, ref)) return;
  if (!context.mounted) return;
  final bool hidden = creation.hideState == 'HIDED';
  if (!hidden && creation.hideState == 'HIDE2DEL') {
    showPexToast(
      context,
      ref,
      const LangText(
        zhCN: '不能恢复已被您彻底删除的创作品。',
        enUS: 'Cannot recover a creation that was already deleted by you.',
      ),
    );
    return;
  }

  final bool confirmed = await showPexModal(
    context,
    ref,
    title: hidden ? _kShowTitle : _kHideTitle,
    content: hidden
        ? _kShowContent
        : LangText.from(
            '${ll(ref.read(languageProvider), _kHideContent)}'
            '${creation.linkedByMe ? ll(ref.read(languageProvider), _kHideContentRecallable) : ''}',
          ),
    confirmText: hidden ? _kShowConfirm : _kHideConfirm,
    showCancel: true,
  );
  if (!confirmed || !context.mounted) return;

  final CreationApi api = ref.read(creationApiProvider);
  final Map<String, dynamic> data = hidden
      ? await api.unhideCreation(
          csid: creation.csid,
          hideTarget: creation.pexdataCidHashRoot,
        )
      : await api.hideCreation(
          csid: creation.csid,
          hideTarget: creation.pexdataCidHashRoot,
        );
  if (!context.mounted) return;

  if (!bok(data['_state']?.toString())) {
    showPexToast(context, ref, hidden ? _kShowFailed : _kHideFailed);
    return;
  }
  final Map<String, dynamic> patch = <String, dynamic>{
    'hideState': hidden ? 'UNHIDED' : 'HIDED',
    'countHide': hidden
        ? (creation.raw['countHide'] == null
            ? null
            : _intOf(creation.raw['countHide']) - 1)
        : _intOf(creation.raw['countHide']) + 1,
  }..removeWhere((String key, Object? value) => value == null);
  ref.read(creationShowProvider.notifier).merge(patch);
  ref.read(creationProvider.notifier).updateItem(creation.csid, patch);
  // 源项目：隐藏后该作品不再出现在探索列表里。
  if (!hidden) ref.read(creationProvider.notifier).removeItem(creation.csid);
  showPexToast(context, ref, hidden ? _kShowDone : _kHidden);
}

/// 彻底删除（源项目 `to_delete_creation_from_{hide,remove}`）。
Future<void> deleteCreationAction(
  BuildContext context,
  WidgetRef ref,
  Creation creation, {
  required bool fromHide,
}) async {
  if (!await checkOnline(context, ref)) return;
  if (!context.mounted) return;

  final bool confirmed = await showPexModal(
    context,
    ref,
    title: _kDeleteTitle,
    content: _kDeleteContent,
    confirmText: _kDeleteConfirm,
    showCancel: true,
  );
  if (!confirmed || !context.mounted) return;

  final CreationApi api = ref.read(creationApiProvider);
  final Map<String, dynamic> data = fromHide
      ? await api.deleteCreationFromHide(
          csid: creation.csid,
          hideTarget: creation.pexdataCidHashRoot,
        )
      : await api.deleteCreationFromRemove(creation.csid);
  if (!context.mounted) return;

  if (!bok(data['_state']?.toString())) {
    showPexToast(context, ref, _kDeleteFailed);
    return;
  }
  final Map<String, dynamic> userUpdated =
      (data['userUpdated'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
  if (userUpdated.isNotEmpty) {
    ref.read(appStartupProvider.notifier).mergeOnlineUser(userUpdated);
  }
  ref.read(creationProvider.notifier).removeItem(creation.csid);
  showPexToast(context, ref, _kDeleted);

  // 源项目删除后 `uni.navigateBack()`。
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.path(AppRoutes.menuCreation));
  }
}
