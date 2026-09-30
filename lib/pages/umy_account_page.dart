/// 我的账号，对应源项目 `pages/umyAccount.vue`：
/// 用户号（去邀请）/ 手机 / 邮箱 / 密码 / 注销 五行入口。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/appmeta/page_meta.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_router.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/part_lang_table.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_window_layout.dart';

const LangText _kUserId = LangText(zhCN: '用户号', enUS: 'User ID');

const LangText _kInviteFriends = LangText(zhCN: '邀请朋友', enUS: 'Invite Friends');

const LangText _kPhone = LangText(zhCN: '手机', enUS: 'Phone');

const LangText _kEmail = LangText(zhCN: '邮箱', enUS: 'Email');

const LangText _kForLogin = LangText(zhCN: '可用于登录', enUS: 'for login');

const LangText _kPassword = LangText(zhCN: '密码', enUS: 'Password');

const LangText _kAddPhone = LangText(zhCN: '添加手机号', enUS: 'Add phone');

const LangText _kChangePhone = LangText(zhCN: '修改手机号', enUS: 'Change phone');

const LangText _kAddEmail = LangText(zhCN: '添加邮箱', enUS: 'Add email');

const LangText _kChangeEmail = LangText(zhCN: '修改邮箱', enUS: 'Change email');

class UmyAccountPage extends ConsumerWidget {
  const UmyAccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStartupState startup = ref.watch(appStartupProvider);
    final DeviceInfo device = DeviceInfo.of(context);
    final String lang = ref.watch(languageProvider);
    final Map<String, dynamic> user = ref.watch(onlineUserProvider);

    final String phone = user['phone']?.toString() ?? '';
    final String email = user['email']?.toString() ?? '';

    return PartWindowLayout(
      pageName: AppRoutes.umyAccount,
      child: !startup.afterAutologging
          ? const PartShowLoading()
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      children: <Widget>[
                        PartNavibarPcFixed(
                          title: pageMetaOf(AppRoutes.umyAccount)?.i18nPageTitle,
                          pageName: AppRoutes.umyAccount,
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            children: <Widget>[
                              // 用户号：点进去即「邀请朋友」（源项目 link to=umyInvite）。
                              _row(
                                lang,
                                icon: PexIcons.icont('icont-userid-line'),
                                title: _kUserId,
                                footer: _footer(
                                  value: user['haid']?.toString() ?? '',
                                  action: ll(lang, _kInviteFriends),
                                ),
                                onTap: () => context.push('/${AppRoutes.umyInvite}'),
                              ),
                              _row(
                                lang,
                                icon: PexIcons.uni('phone'),
                                title: _kPhone,
                                notes: _kForLogin,
                                footer: _footer(
                                  value: phone,
                                  action: ll(lang, phone.isEmpty ? _kAddPhone : _kChangePhone),
                                ),
                                onTap: () => context.push('/${AppRoutes.umyAccountCommid}'),
                              ),
                              _row(
                                lang,
                                icon: PexIcons.uni('email'),
                                title: _kEmail,
                                notes: _kForLogin,
                                footer: _footer(
                                  value: email,
                                  action: ll(lang, email.isEmpty ? _kAddEmail : _kChangeEmail),
                                ),
                                onTap: () => context.push('/${AppRoutes.umyAccountCommid}'),
                              ),
                              _row(
                                lang,
                                icon: PexIcons.uni('more'),
                                title: _kPassword,
                                footer: _footer(
                                  value: '',
                                  action: ll(
                                    lang,
                                    pageMetaOf(AppRoutes.umyAccountPassword)
                                            ?.i18nPageTitle ??
                                        const LangText(zhCN: '修改密码', enUS: 'Change Password'),
                                  ),
                                ),
                                onTap: () =>
                                    context.push('/${AppRoutes.umyAccountPassword}'),
                              ),
                              _row(
                                lang,
                                icon: PexIcons.uni('trash'),
                                title: pageMetaOf(AppRoutes.umyAccountTerminate)?.i18nListTitle,
                                footer: _footer(
                                  value: '',
                                  action: ll(
                                    lang,
                                    pageMetaOf(AppRoutes.umyAccountTerminate)
                                            ?.i18nPageTitle ??
                                        const LangText(zhCN: '销毁我的账号', enUS: 'Terminate My Account'),
                                  ),
                                ),
                                onTap: () =>
                                    context.push('/${AppRoutes.umyAccountTerminate}'),
                                last: true,
                              ),
                            ],
                          ),
                        ),
                        if (!device.inPc)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: PartLangTable(color: PexColors.grey3),
                            ),
                          )
                        else
                          const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  /// 右栏：主值 + 蓝色动作文字（源项目 `uni-list-item` 的 footer 两行）。
  Widget _footer({required String value, required String action}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        if (value.isNotEmpty)
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (action.isNotEmpty)
          Text(
            action,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: PexColors.blueMy),
          ),
      ],
    );
  }

  Widget _row(
    String lang, {
    required PexGlyph? icon,
    required LangText? title,
    required Widget footer,
    required VoidCallback onTap,
    LangText? notes,
    bool last = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: PexColors.bg)),
        ),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PexIcon(icon, size: 22, color: PexColors.grey3),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  ll(lang, title ?? const LangText.from('')),
                  style: const TextStyle(fontSize: 15),
                ),
                if (notes != null)
                  Text(
                    ll(lang, notes),
                    style: const TextStyle(fontSize: 12, color: PexColors.greyA),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontSize: 13, color: PexColors.grey9),
                child: Align(alignment: Alignment.centerRight, child: footer),
              ),
            ),
            const SizedBox(width: 4),
            PexIcon.uni('forward', size: 18, color: PexColors.greyC),
          ],
        ),
      ),
    );
  }
}
