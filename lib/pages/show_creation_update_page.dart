/// 修改创作品，对应源项目 `pages/showCreationUpdate.vue`。
///
/// 逻辑很薄：按 `unid` 取回作品 → 校验本人是原创主或权利主 → 交给 [PartCreate]
/// （草稿来自 [creationDraftProvider] 的修改模式）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/lang_text.dart';
import '../core/responsive/device_info.dart';
import '../core/router/app_router.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/creation_draft_provider.dart';
import '../widgets/part_create.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_window_layout.dart';

class ShowCreationUpdatePage extends ConsumerStatefulWidget {
  const ShowCreationUpdatePage({super.key, this.unid = ''});

  /// 作品编号（路由 `?unid=`）。
  final String unid;

  @override
  ConsumerState<ShowCreationUpdatePage> createState() =>
      _ShowCreationUpdatePageState();
}

class _ShowCreationUpdatePageState
    extends ConsumerState<ShowCreationUpdatePage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 50), _load);
  }

  @override
  void didUpdateWidget(covariant ShowCreationUpdatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unid != widget.unid) _load();
  }

  Future<void> _load() async {
    await ref.read(appStartupProvider.notifier).waitAutologin();
    if (!mounted) return;
    await ref.read(creationDraftProvider.notifier).initUpdate(widget.unid);
  }

  @override
  Widget build(BuildContext context) {
    final DeviceInfo device = DeviceInfo.of(context);
    return PartWindowLayout(
      pageName: AppRoutes.showCreationUpdate,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (device.inPc)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: PartNavibarPcFixed(
                      title: const LangText(
                        zhCN: '修改创作品',
                        enUS: 'Modify Creation',
                      ),
                      pageName: AppRoutes.showCreationUpdate,
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(5, device.inPc ? 0 : 10, 5, 30),
                  child: const PartCreate(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
