/// 资源详情，对应源项目 `pages/userResourceDetail.vue`。
///
/// 内容：分组切换条 + 子项切换条 +（安卓）应用市场选择 + 说明标题 + 版本信息 +
/// 二维码 + 可点击/可复制的链接。数据全部来自后端下发的 `linkTree` / `appNews`。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/client_info.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_router.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../core/util/feedback.dart';
import '../theme/app_theme.dart';
import '../widgets/part_lang_table.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_window_layout.dart';

const LangText _kOfficialRelease =
    LangText(zhCN: '官方版本 ', enUS: 'Official Release ');

const LangText _kLocalVersion = LangText(zhCN: '本机版本 ', enUS: 'Local version ');

const LangText _kPleaseUpdate =
    LangText(zhCN: '建议立刻更新！', enUS: 'Update now!');

const LangText _kBestVersion = LangText(
  zhCN: '您已拥有最佳版本!',
  enUS: 'You already have the best version!',
);

const LangText _kStandardApk = LangText(zhCN: '标准安装包', enUS: 'Standard APK');

const LangText _kCopied = LangText(zhCN: '已复制到剪贴板', enUS: 'Copied to clipboard');

/// 源项目 `appMarketNow` 的默认值：直装包（不走应用市场）。
const String kRawApk = 'RAWAPK';

class UserResourceDetailPage extends ConsumerStatefulWidget {
  const UserResourceDetailPage({super.key, this.tagNow = ''});

  /// 链接标签（源项目 `wo.ss.linkTagNow`），由 `/userResourceDetail?tagnow=` 传入。
  final String tagNow;

  @override
  ConsumerState<UserResourceDetailPage> createState() =>
      _UserResourceDetailPageState();
}

class _UserResourceDetailPageState extends ConsumerState<UserResourceDetailPage> {
  bool _resolved = false;
  String _appMarketNow = kRawApk;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 50), () async {
      await ref.read(appStartupProvider.notifier).waitAutologin();
      if (!mounted) return;
      setState(() => _resolved = true);
    });
  }

  @override
  void didUpdateWidget(covariant UserResourceDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tagNow != widget.tagNow) {
      _appMarketNow = kRawApk;
    }
  }

  /// 找出 [tagNow] 所属分组（源项目 `onLoad` 里的循环）。
  String _groupOf(Envar envar) {
    for (final String group in envar.linkTree.keys) {
      if (envar.subtags(group).containsKey(widget.tagNow)) return group;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final DeviceInfo device = DeviceInfo.of(context);
    final Envar envar = ref.watch(envarProvider);
    final String group = _groupOf(envar);

    if (!_resolved) {
      return PartWindowLayout(
        pageName: AppRoutes.userResourceDetail,
        child: const Center(child: PartShowLoading()),
      );
    }
    // 找不到目标（源项目 `uni.redirectTo({ url: 'userResource' })`）。
    if (group.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.path(AppRoutes.userResource));
      });
      return const PartWindowLayout(child: SizedBox.shrink());
    }

    final Map<String, dynamic> subtag =
        (envar.subtags(group)[widget.tagNow] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final String linkUrl = _linkUrl(envar, group, subtag);

    return PartWindowLayout(
      pageName: AppRoutes.userResourceDetail,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 10),
                  if (device.inPc)
                    PartNavibarPcFixed(
                      title: LangText.fromMap(subtag['i18nPageTitle']),
                      backToPage: AppRoutes.userResource,
                    ),
                  _GroupTabs(envar: envar, groupNow: group),
                  _SubtagTabs(envar: envar, groupNow: group, tagNow: widget.tagNow),
                  if (widget.tagNow == 'android')
                    _MarketPicker(
                      subtag: subtag,
                      marketNow: _appMarketNow,
                      onChanged: (String value) =>
                          setState(() => _appMarketNow = value),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 30, 0, 10),
                    child: Text(
                      ll(ref.watch(languageProvider),
                          LangText.fromMap(subtag['infoTitle'])),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _VersionBlock(
                    envar: envar,
                    tagNow: widget.tagNow,
                    device: device,
                    marketNow: _appMarketNow,
                  ),
                  if (linkUrl.isNotEmpty)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.white,
                        child: QrImageView(
                          data: linkUrl,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (linkUrl.isNotEmpty) _LinkRow(linkUrl: linkUrl),
                  if (!device.inPc)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: PartLangTable(color: PexColors.grey9),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _linkUrl(Envar envar, String group, Map<String, dynamic> subtag) {
    if (widget.tagNow == 'android' && _appMarketNow != kRawApk) {
      final Object? market = (subtag['appMarket'] as Map?)?[_appMarketNow];
      if (market is Map) return market['linkUrl']?.toString() ?? '';
    }
    return subtag['linkUrl']?.toString() ?? '';
  }
}

/// 第一层切换条：分组（源项目第一个 `uni-segmented-control`）。
class _GroupTabs extends ConsumerWidget {
  const _GroupTabs({required this.envar, required this.groupNow});

  final Envar envar;
  final String groupNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final List<String> groups = <String>[
      for (final String group in envar.linkTree.keys)
        if (!envar.isLinkGroupHidden(group)) group,
    ];
    if (groups.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (final String group in groups)
              TextButton(
                onPressed: () {
                  final List<String> keys = envar.subtags(group).keys.toList();
                  if (keys.isEmpty) return;
                  context.replace(
                    '/${AppRoutes.userResourceDetail}?tagnow=${keys.first}',
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor:
                      group == groupNow ? PexColors.blueMy : PexColors.grey6,
                ),
                child: Text(
                  ll(lang, LangText.fromMap(envar.linkGroup(group)['iName'])),
                  style: TextStyle(
                    fontWeight: group == groupNow
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 第二层切换条：当前分组下的子项（源项目第二个 `uni-segmented-control`）。
class _SubtagTabs extends ConsumerWidget {
  const _SubtagTabs({
    required this.envar,
    required this.groupNow,
    required this.tagNow,
  });

  final Envar envar;
  final String groupNow;
  final String tagNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final Map<String, dynamic> subtags = envar.subtags(groupNow);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 6,
        children: <Widget>[
          for (final String key in subtags.keys)
            ChoiceChip(
              label: Text(
                ll(
                  lang,
                  LangText.fromMap(
                    (subtags[key] as Map?)?['i18nName'],
                  ),
                ),
              ),
              selected: key == tagNow,
              onSelected: (_) => context.replace(
                '/${AppRoutes.userResourceDetail}?tagnow=$key',
              ),
            ),
        ],
      ),
    );
  }
}

/// 安卓应用市场选择（源项目 `uni-data-select`）。
class _MarketPicker extends ConsumerWidget {
  const _MarketPicker({
    required this.subtag,
    required this.marketNow,
    required this.onChanged,
  });

  final Map<String, dynamic> subtag;
  final String marketNow;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final Map<String, dynamic> markets =
        (subtag['appMarket'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    if (markets.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: DropdownButtonFormField<String>(
        initialValue: marketNow,
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: PexColors.grey9),
          ),
        ),
        items: <DropdownMenuItem<String>>[
          DropdownMenuItem<String>(
            value: kRawApk,
            child: Text(ll(lang, _kStandardApk)),
          ),
          for (final String key in markets.keys)
            DropdownMenuItem<String>(
              value: (markets[key] as Map?)?['linkkey']?.toString() ?? key,
              child: Text(
                ll(lang, LangText.fromMap((markets[key] as Map?)?['i18nName'])),
              ),
            ),
        ],
        onChanged: (String? value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

/// 版本信息（源项目仅 `webapp` / `ios` / `android` 显示，「本机版本」只在 App 内显示）。
class _VersionBlock extends ConsumerWidget {
  const _VersionBlock({
    required this.envar,
    required this.tagNow,
    required this.device,
    required this.marketNow,
  });

  final Envar envar;
  final String tagNow;
  final DeviceInfo device;
  final String marketNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    if (!<String>['webapp', 'ios', 'android'].contains(tagNow)) {
      return const SizedBox.shrink();
    }
    final String remote = _remoteVersion(envar);
    final List<Widget> lines = <Widget>[
      if (remote.isNotEmpty)
        Text('${ll(lang, _kOfficialRelease)}$remote', textAlign: TextAlign.center),
    ];

    // 源项目用 `#ifdef APP` 限制：仅原生 App 内显示本机版本与更新建议。
    if (device.inApp && _isThisApp()) {
      final String local = '$kAppVersionCode';
      lines.add(Text('${ll(lang, _kLocalVersion)}$local',
          textAlign: TextAlign.center));
      final int remoteCode = int.tryParse(remote) ?? 0;
      lines.add(
        Text(
          ll(lang, remoteCode > kAppVersionCode ? _kPleaseUpdate : _kBestVersion),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          for (final Widget line in lines)
            DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 13, color: PexColors.grey9),
              child: line,
            ),
        ],
      ),
    );
  }

  /// 源项目只在「当前系统正好是该平台」时显示本机版本（ios / android）。
  bool _isThisApp() =>
      (tagNow == 'ios' || tagNow == 'android') && tagNow == device.osName;

  String _remoteVersion(Envar envar) {
    final Object? news = envar.raw['appNews'];
    if (news is! Map) return '';
    if (tagNow == 'webapp') return '$kAppVersionCode';
    final Object? group = news[tagNow];
    if (group is! Map) return '';
    if (tagNow == 'android' && marketNow != kRawApk) {
      final Object? markets = group['appMarket'];
      if (markets is Map) {
        final Object? market = markets[marketNow];
        if (market is Map) return market['appVersionCode']?.toString() ?? '';
      }
      return '';
    }
    return group['appVersionCode']?.toString() ?? '';
  }
}

/// 链接行：点击打开 + 复制到剪贴板。
class _LinkRow extends ConsumerWidget {
  const _LinkRow({required this.linkUrl});

  final String linkUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () async {
                final Uri? uri = Uri.tryParse(linkUrl);
                if (uri == null) return;
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    PexIcon.icont(
                      'icont-hyperlink',
                      size: 18,
                      color: PexColors.blueMy,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        linkUrl,
                        style: const TextStyle(
                          color: PexColors.blueMy,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40),
            icon: PexIcon.icont('icont-copy-text-line', size: 20, color: PexColors.grey9),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: linkUrl));
              if (context.mounted) {
                showPexToast(context, ref, _kCopied);
              }
            },
          ),
        ],
      ),
    );
  }
}
