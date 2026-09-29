/// 首页门户，对应源项目 `pages/homePortal.vue`。
///
/// 阶段一首发验证页：用到布局框架 [PartWindow]、按钮 [PartButtonSubmit]、
/// 语言选择 [PartLangTable]、后端下发配置（newsline / slogans / recocards）、
/// 响应式与自动登录态。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/router/app_router.dart';
import '../core/state/app_providers.dart';
import '../core/state/app_startup_notifier.dart';
import '../widgets/part_button_submit.dart';
import '../widgets/part_lang_table.dart';
import '../widgets/part_window.dart';

/// 「出发」按钮文案。
const LangText _kStart = LangText(zhCN: '出 发', enUS: 'Start', jaJP: '出発');

class HomePortalPage extends ConsumerWidget {
  const HomePortalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandProvider);
    final String lang = ref.watch(languageProvider);
    final AppStartupState startup = ref.watch(appStartupProvider);
    final Map<String, dynamic> envar = startup.envar;

    final LangText newsline = LangText.fromMap(envar['newsline']);
    final LangText slogans = LangText.fromMap(envar['slogans']);
    final Map<String, dynamic> recocards =
        (envar['recocards'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

    final bool afterAutologin = startup.afterAutologging;
    final bool online = (startup.onlineUser['usid']?.toString() ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: brand.portalBackgroundColor,
      body: PartWindow(
        backgroundImage: brand.portalImageAsset,
        backgroundColor: brand.portalBackgroundColor,
        maxWidth: 900,
        padding: const EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  _buildLogo(brand.logoAsset),
                  if (!newsline.isEmpty) _buildNewsline(context, lang, newsline),
                  if (recocards.isNotEmpty)
                    _buildRecocards(context, lang, recocards),
                  _buildStatusChip(context, startup),
                ],
              ),
            ),
            _buildSlogans(context, lang, slogans),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: PartButtonSubmit(
                disabled: !afterAutologin,
                loading: !afterAutologin,
                inShadow: true,
                onPressed: () => _launch(context, ref, online),
                children: <Widget>[
                  if (afterAutologin)
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.send, size: 22, color: Colors.white),
                    ),
                  Text(ll(lang, _kStart)),
                ],
              ),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: PartLangTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(String logoAsset) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.only(top: 24, bottom: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          logoAsset,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(Icons.apps, size: 30),
        ),
      ),
    );
  }

  Widget _buildNewsline(BuildContext context, String lang, LangText newsline) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        ll(lang, newsline),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          shadows: <Shadow>[Shadow(blurRadius: 2, color: Colors.black)],
        ),
      ),
    );
  }

  Widget _buildRecocards(
    BuildContext context,
    String lang,
    Map<String, dynamic> recocards,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: <Widget>[
          for (final dynamic card in recocards.values)
            _buildRecocard(context, lang, card as Map),
        ],
      ),
    );
  }

  Widget _buildRecocard(BuildContext context, String lang, Map<dynamic, dynamic> card) {
    final String title = ll(lang, LangText.fromMap(card['title']));
    final String desc = ll(lang, LangText.fromMap(card['desc']));
    final String badge = ll(lang, LangText.fromMap(card['badge']));
    return Container(
      width: 160,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (badge.isNotEmpty)
            Text(
              badge,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          if (desc.isNotEmpty)
            Text(desc, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSlogans(BuildContext context, String lang, LangText slogans) {
    if (slogans.isEmpty) return const SizedBox(height: 10);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Text(
        ll(lang, slogans),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          height: 1.8,
          shadows: <Shadow>[Shadow(blurRadius: 2, offset: Offset(1, 2), color: Colors.black)],
        ),
      ),
    );
  }

  /// 开发辅助：显示与后端的连接状态（正式版可移除）。
  Widget _buildStatusChip(BuildContext context, AppStartupState startup) {
    final String text;
    if (startup.connecting) {
      text = '连接中… (第 ${startup.attempt} 次)';
    } else if (startup.connected) {
      text = '已连接 · 自动登录 ${startup.autologging.name}';
    } else {
      text = '未连接：${startup.lastError ?? '未知'}';
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  void _launch(BuildContext context, WidgetRef ref, bool online) {
    if (online) {
      context.go(AppRoutes.path(ref.read(brandProvider).appLandPage));
    } else {
      context.push(AppRoutes.path(AppRoutes.identBegin));
    }
  }
}
