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

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_router.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/creation_show_provider.dart';
import '../core/state/envar_provider.dart';
import '../core/state/region_provider.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../data/creation.dart';
import '../theme/app_theme.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_pexdata_summary.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_story_reader.dart';
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
      ShowCoverKind.locked => _lockedCover(),
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

  /// 已加密：方形容器 + 封条文字 + 半透明摘要遮罩。
  ///
  /// 背景优先用封面图，否则用 `static/matrix7.jpg`（与源项目一致，绿色封条文字才可见）。
  /// 源项目在此遮罩内还有「解密」按钮；解密属于 2C（付费），本轮不渲染入口，
  /// 避免出现无实际动作的按钮。
  Widget _lockedCover() {
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
                  child: PartPexdataSummary(pexdataSum: creation.pexdataSum),
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
                _PactRow(creation: creation, pactKey: 'TVIEW', pact: creation.viewerPact),
              if (pactDict['THOLD'] != null)
                _PactRow(creation: creation, pactKey: 'THOLD', pact: creation.holderPact),
              if (pactDict['TWORK'] != null)
                _PactRow(creation: creation, pactKey: 'TWORK', pact: creation.workerPact),
              if (pactDict['TOWN'] != null)
                _PactRow(creation: creation, pactKey: 'TOWN', pact: creation.ownerPact),
            ],
          ),
        ),
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
  const _PactRow({required this.creation, required this.pactKey, required this.pact});

  final Creation creation;
  final String pactKey;
  final Pact pact;

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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            PexIcon.uni('staff', size: 18, color: PexColors.greyA),
            const SizedBox(width: 2),
            Text('${creation.countViewer}', style: _counterStyle),
          ],
        ),
      );
    }
    if (pactKey == 'THOLD') {
      final num? stock = creation.stockNumber;
      final String stockText = stock == null
          ? ll(lang, LangText.fromMap(item['HOLD_QUOTA_INFINITE']))
          : numberPrecision(stock).toString();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            PexIcon.uni('staff', size: 18, color: PexColors.greyA),
            const SizedBox(width: 2),
            Text('${creation.countHolder}', style: _counterStyle),
            const Text('/', style: _counterStyle),
            PexIcon.icont('icont-quota', size: 14, color: PexColors.greyA),
            const SizedBox(width: 2),
            Text(stockText, style: _counterStyle),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
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
    // 付费入口（解密/持有/收购）属于 2C，本轮仅以醒目样式展示价格。
    if (pactKey == 'TVIEW' || pactKey == 'THOLD' || pactKey == 'TOWN') {
      return _payablePrice(price);
    }
    return price;
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
