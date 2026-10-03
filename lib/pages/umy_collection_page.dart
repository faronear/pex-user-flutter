/// 我的收藏（按身份切换），对应源项目 `pages/umyCollection.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/creation_api.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_router.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/part_creation_as_list.dart';
import '../widgets/part_show_loading.dart';
import '../widgets/part_window_layout.dart';

/// 导航栏标题。
/// 源项目 `pageSet['umyCollection'].i18nPageTitle`。
const LangText _kNavTitle = LangText(
  zhCN: '我的选集',
  enUS: 'My Collections',
  deDE: 'Meine Sammlungen',
  jaJP: 'マイコレクション',
);

class UmyCollectionPage extends ConsumerStatefulWidget {
  const UmyCollectionPage({super.key});

  @override
  ConsumerState<UmyCollectionPage> createState() => _UmyCollectionPageState();
}

class _UmyCollectionPageState extends ConsumerState<UmyCollectionPage> {
  CreationRole _roleNow = CreationRole.creator;

  /// 可用身份：只列出 `pactDict` 里存在的（源项目对 `TOWN` 有此判断）。
  List<CreationRole> _roles() {
    final Object? pact = ref.read(envarProvider).raw['pactDict'];
    if (pact is! Map) return <CreationRole>[CreationRole.creator];
    return CreationRole.values
        .where((CreationRole role) => pact.containsKey(role.pactKey))
        .toList();
  }

  LangText _roleLabel(CreationRole role) {
    final Object? pact = ref.read(envarProvider).raw['pactDict'];
    if (pact is Map) {
      final Object? tag = (pact[role.pactKey] as Map?)?['pact_tag'];
      if (tag is Map) return LangText.fromMap(tag);
    }
    return LangText(zhCN: role.name, enUS: role.name);
  }

  @override
  Widget build(BuildContext context) {
    final AppStartupState startup = ref.watch(appStartupProvider);
    final DeviceInfo device = DeviceInfo.of(context);
    final String lang = ref.watch(languageProvider);
    final List<CreationRole> roles = _roles();

    return PartWindowLayout(
      pageName: AppRoutes.umyCollection,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _kNavTitle.resolve(lang),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            color: PexColors.bg,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (final CreationRole role in roles)
                    GestureDetector(
                      onTap: () => setState(() => _roleNow = role),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              _roleLabel(role).resolve(lang),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: role == _roleNow
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: role == _roleNow
                                    ? const Color(0xFF2979FF)
                                    : PexColors.grey6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 2,
                              width: 24,
                              color: role == _roleNow
                                  ? const Color(0xFF2979FF)
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: device.inPc ? 20 : 10),
          Expanded(
            child: !startup.afterAutologging
                ? const PartShowLoading()
                : SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: PartCreationAsList(
                          key: ValueKey<CreationRole>(_roleNow),
                          role: _roleNow,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
