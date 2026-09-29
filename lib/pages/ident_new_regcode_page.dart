/// 优惠码（邀请码）页，对应源项目 `pages/identNewRegcode.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/router/app_router.dart';
import '../core/state/app_providers.dart';
import '../core/state/envar_provider.dart';
import '../core/state/ident_provider.dart';
import '../core/util/feedback.dart';
import '../widgets/part_button_submit.dart';
import '../widgets/part_countdown.dart';
import '../widgets/part_feedback.dart';
import '../widgets/part_ident_commid.dart';
import '../widgets/part_ident_input.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_window_layout_ident.dart';

const LangText _kPlaceholder = LangText(
  zhCN: '输入优惠码，获得更多奖励',
  enUS: 'Enter referral code for more rewards',
  jaJP: 'プロモーションコードを入力してより多くの特典を獲得',
);

const LangText _kGetRewards = LangText(zhCN: '领取优惠', enUS: 'Get Rewards', jaJP: '特典を獲得');

const LangText _kSkip = LangText(zhCN: '跳 过', enUS: 'Skip', jaJP: 'スキップ');

/// PC 二级导航栏标题（源项目页面 `data.i18nPageTitle`）。
const LangText _kNavTitle = LangText(
  zhCN: '优惠码',
  enUS: 'Referral Code',
  jaJP: 'プロモーションコード',
);

class IdentNewRegcodePage extends ConsumerStatefulWidget {
  const IdentNewRegcodePage({super.key});

  @override
  ConsumerState<IdentNewRegcodePage> createState() => _IdentNewRegcodePageState();
}

class _IdentNewRegcodePageState extends ConsumerState<IdentNewRegcodePage> {
  late final TextEditingController _code = TextEditingController(
    text: ref.read(identProvider).inviterHaid,
  );

  bool _loading = false;
  LangText? _feedbackRemote;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _feedbackRemote = null);

    final IdentState ident = ref.read(identProvider);
    if (ident.verifyExpired) {
      await showPexModal(
        context,
        ref,
        title: PartTexts.passcodeExpired,
        content: PartTexts.passcodeExpiredPlease,
        showCancel: false,
      );
      return;
    }
    if (ident.inviterHaid.isEmpty) {
      if (mounted) context.push(AppRoutes.path(AppRoutes.identNewRegister));
      return;
    }

    setState(() => _loading = true);
    final Map<String, dynamic> data = await ref.read(apiClientProvider).callBase(
          apiWho: 'User',
          apiTodo: 'verify_regcode',
          apiWhat: <String, dynamic>{'inviterHaid': ident.inviterHaid},
        );
    if (!mounted) return;
    setState(() => _loading = false);

    ref.read(identProvider.notifier).setInviterHaid('');
    if (bok(data['_state']?.toString())) {
      ref
          .read(identProvider.notifier)
          .setVerifyExpireAt(int.tryParse('${data['verifyExpireAt']}') ?? 0);
      if (mounted) context.push(AppRoutes.path(AppRoutes.identNewRegister));
    } else {
      setState(() {
        _feedbackRemote = data['_msg'] == null
            ? PartTexts.systemDown
            : LangText.fromMap(data['_msg']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final IdentState ident = ref.watch(identProvider);
    final Envar envar = ref.watch(envarProvider);
    final String maxReward =
        '${envar.registerReward + envar.inviteeReward}${envar.tucSymbol}';
    final String registReward = '${envar.registerReward}${envar.tucSymbol}';

    return PartWindowLayoutIdent(
      pageName: AppRoutes.identNewRegcode,
      navTitle: _kNavTitle,
      child: Column(
        children: <Widget>[
          const PartIdentCommid(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              ll(
                lang,
                LangText(
                  zhCN:
                      '输入优惠码，获得高达 $maxReward 优惠金；\n或者跳过这一步，也可获得 $registReward 体验金。',
                  enUS:
                      'Enter referral code to obtain extra rewards $maxReward;\nor click Skip to continue with basic rewards $registReward.',
                  jaJP:
                      'プロモーションコードを入力して最大$maxRewardの特典を獲得；\nまたはスキップして基本特典$registRewardを獲得。',
                ),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF606266)),
            ),
          ),
          PartIdentInput(
            controller: _code,
            placeholder: _kPlaceholder,
            enabled: ident.commid.isNotEmpty && !_loading,
            textAlign: TextAlign.center,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
              LengthLimitingTextInputFormatter(12),
            ],
            onChanged: (String value) =>
                ref.read(identProvider.notifier).setInviterHaid(value),
            onSubmitted: _verify,
          ),
          const PartFeedback(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: PartButtonSubmit(
              disabled: ident.commid.isEmpty || _loading,
              loading: _loading,
              onPressed: _verify,
              children: <Widget>[
                if (!_loading)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PexIcon.uni('gift', size: 22, color: Colors.white),
                  ),
                Text(ll(lang, ident.inviterHaid.isNotEmpty ? _kGetRewards : _kSkip)),
              ],
            ),
          ),
          PartFeedback(bad: _feedbackRemote),
          PartCountdown(expireAt: ident.verifyExpireAt),
        ],
      ),
    );
  }
}
