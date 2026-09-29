/// 首页门户，对应源项目 `pages/homePortal.vue`。
///
/// 阶段一首发验证页：用到布局框架 [PartWindow]、按钮 [PartButtonSubmit]、
/// 语言选择 [PartLangTable]、快捷入口 [PartShortcuts]、后端下发配置
/// （newsline / slogans / recocards / linkTree）、响应式与自动登录态。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/assets/pex_assets.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/router/app_router.dart';
import '../core/state/app_providers.dart';
import '../core/state/app_startup_notifier.dart';
import '../widgets/part_button_submit.dart';
import '../widgets/part_lang_table.dart';
import '../widgets/part_shortcuts.dart';
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
                  if (!newsline.isEmpty) _buildNewsline(lang, newsline),
                  if (recocards.isNotEmpty) _buildRecocards(context, lang, recocards),
                  const Spacer(),
                  _buildSlogans(lang, slogans),
                  _buildStartButton(context, ref, lang, afterAutologin, online),
                ],
              ),
            ),
            _buildBottomBar(startup),
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
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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

  Widget _buildNewsline(String lang, LangText newsline) {
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

  /// 推荐卡片：对应源项目 `flex: 0 0 calc(33.3%)` 的一行 3 个。
  Widget _buildRecocards(
    BuildContext context,
    String lang,
    Map<String, dynamic> recocards,
  ) {
    final bool phone = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          const double gap = 10;
          final double itemWidth = (constraints.maxWidth - gap * 2) / 3;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: <Widget>[
              for (final dynamic card in recocards.values)
                SizedBox(
                  width: itemWidth,
                  child: _buildRecocard(lang, card as Map, itemWidth, phone),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecocard(String lang, Map<dynamic, dynamic> card, double size, bool phone) {
    final String title = ll(lang, LangText.fromMap(card['title']));
    final String desc = ll(lang, LangText.fromMap(card['desc']));
    final String badge = ll(lang, LangText.fromMap(card['badge']));
    final String img = card['img']?.toString() ?? '';

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: size * 0.5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: size * 0.5,
                    height: size * 0.5,
                    child: PexImage(img, fit: BoxFit.contain),
                  ),
                  Expanded(
                    child: Text(
                      badge,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: const Color(0xFFFA3534),
                        fontSize: phone ? 14 : 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: phone ? 16 : 18,
              ),
            ),
            Expanded(
              child: Text(
                desc,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: phone ? 14 : 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlogans(String lang, LangText slogans) {
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
          shadows: <Shadow>[
            Shadow(blurRadius: 2, offset: Offset(1, 2), color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(
    BuildContext context,
    WidgetRef ref,
    String lang,
    bool afterAutologin,
    bool online,
  ) {
    return Padding(
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
    );
  }

  /// 底栏：上一行为连接状态（右对齐），下一行为快捷入口（左）+ 语言选择（右）。
  Widget _buildBottomBar(AppStartupState startup) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Align(
          alignment: Alignment.centerRight,
          child: _buildStatusText(startup),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 2),
          child: Row(
            children: <Widget>[
              const PartShortcuts(color: Colors.white),
              const Spacer(),
              const PartLangTable(),
            ],
          ),
        ),
      ],
    );
  }

  /// 后端连接状态（正式版保留）。
  Widget _buildStatusText(AppStartupState startup) {
    final String text;
    if (startup.connecting) {
      text = '连接中…（第 ${startup.attempt} 次）';
    } else if (startup.connected) {
      text = '已连接 · 自动登录 ${startup.autologging.name}';
    } else {
      text = '未连接：${startup.lastError ?? '未知'}';
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8),
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
