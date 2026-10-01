/// 邀请朋友，对应源项目 `pages/umyInvite.vue`。
///
/// 展示本人优惠码 / 优惠链接 / 优惠二维码，以及「已奖励」「已邀请」两个入口。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/router/app_routes.dart';
import '../core/state/envar_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/part_icontext_copy.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_pop_link.dart';
import '../widgets/part_window_layout.dart';

const LangText _kCommunity = LangText(
  zhCN: '社区优惠计划',
  enUS: 'Community Reward Program',
);

const LangText _kRewardForNew = LangText(
  zhCN: '新用户注册即可获赠 ',
  enUS: 'New users will be rewarded with ',
);

const LangText _kCode = LangText(zhCN: '优惠码', enUS: 'Referral Code');

const LangText _kLink = LangText(zhCN: '优惠链接', enUS: 'Referral Link');

const LangText _kQrcode = LangText(zhCN: '优惠二维码', enUS: 'Referral QR Code');

const LangText _kRewarded = LangText(zhCN: '已奖励', enUS: 'Rewarded');

const LangText _kInvited = LangText(zhCN: '已邀请', enUS: 'Invited');

/// 源项目两个入口条的底色（`linear-gradient(90deg, ...)`）。
const Color _kRewardStart = Color(0xFFFFCD1E);

const Color _kRewardEnd = Color(0xFFFF8A18);

const Color _kInviteStart = Color(0xFFFE00F1);

const Color _kInviteEnd = Color(0xFFFF2972);

class UmyInvitePage extends ConsumerWidget {
  const UmyInvitePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final Map<String, dynamic> user = ref.watch(onlineUserProvider);

    final String haid = user['haid']?.toString() ?? '';
    // 源项目：为了方便从后台控制，邀请链接固定用主域名。
    final String inviteUrl = '${envar.webUrlRoot}/#/?inhaid=$haid';

    final LangText title =
        envar.tInviteTitle.isEmpty ? envar.slogans : envar.tInviteTitle;

    return PartWindowLayout(
      pageName: AppRoutes.umyInvite,
      child: Column(
        children: <Widget>[
          const PartNavibarPcFixed(),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 10),
                        Text(
                          title.resolve(lang),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.8,
                          ),
                        ),
                        if (envar.linkCommunity.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: InkWell(
                              onTap: () => _open(envar.linkCommunity),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  PexIcon.icont(
                                    'hyperlink',
                                    size: 14,
                                    color: PexColors.blueMy,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    _kCommunity.resolve(lang),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: PexColors.blueMy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          color: Colors.white,
                          child: Column(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        _kRewardForNew.resolve(lang),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${envar.registerReward + envar.inviteeReward}${envar.tucSymbol}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFF29100),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _row(
                                lang: lang,
                                label: _kCode,
                                value: haid,
                                trailing: PartIcontextCopy(
                                  onCopy: () => Clipboard.setData(
                                    ClipboardData(text: haid),
                                  ),
                                ),
                              ),
                              _row(
                                lang: lang,
                                label: _kLink,
                                value: inviteUrl,
                                link: inviteUrl,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    PartIcontextCopy(
                                      onCopy: () => Clipboard.setData(
                                        ClipboardData(text: inviteUrl),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Share',
                                      onPressed: () => showPopLinkSheet(
                                        context,
                                        ref,
                                        shareTitle: envar.tInviteTitle,
                                        shareUrl: inviteUrl,
                                      ),
                                      icon: PexIcon.uni(
                                        'redo',
                                        size: 20,
                                        color: PexColors.grey6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: <Widget>[
                                    Text(_kQrcode.resolve(lang)),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      color: Colors.white,
                                      child: QrImageView(
                                        data: inviteUrl,
                                        size: 140,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            _entry(
                              lang: lang,
                              text:
                                  '${user['sumInInviter'] ?? 0}${envar.tucSymbol}',
                              label: _kRewarded,
                              start: _kRewardStart,
                              end: _kRewardEnd,
                              onTap: () => context.push(
                                '${AppRoutes.path(AppRoutes.umyFundTranx)}?tagnow=TXG_IN_REWARD',
                              ),
                            ),
                            _entry(
                              lang: lang,
                              text: '${user['countInvitee'] ?? 0}',
                              label: _kInvited,
                              start: _kInviteStart,
                              end: _kInviteEnd,
                              onTap: () => context.push(
                                '${AppRoutes.path(AppRoutes.umyCircle)}?tagnow=INVITEE',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({
    required String lang,
    required LangText label,
    required String value,
    String link = '',
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: PexColors.greyE, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label.resolve(lang)),
          const SizedBox(width: 10),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: link.isEmpty ? null : () => _open(link),
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: link.isEmpty ? 18 : 14,
                    color: link.isEmpty ? PexColors.grey3 : PexColors.blueMy,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          trailing,
        ],
      ),
    );
  }

  Widget _entry({
    required String lang,
    required String text,
    required LangText label,
    required Color start,
    required Color end,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: <Color>[start, end]),
          ),
          child: Column(
            children: <Widget>[
              Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                label.resolve(lang),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _open(String link) async {
    final Uri? uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
