/// 应用装配入口：`main*` → [runPexApp]。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'brands/brand_config.dart';
import 'core/router/app_router.dart';
import 'core/state/app_providers.dart';
import 'core/state/app_startup_notifier.dart';
import 'core/storage/local_store.dart';
import 'theme/app_theme.dart';

/// 启动应用：注入品牌与本地存储，构建 [ProviderScope]。
Future<void> runPexApp(BrandConfig brand) async {
  WidgetsFlutterBinding.ensureInitialized();
  final LocalStore store = await LocalStore.open();
  runApp(
    ProviderScope(
      overrides: [
        brandProvider.overrideWithValue(brand),
        localStoreProvider.overrideWithValue(store),
      ],
      child: const PexApp(),
    ),
  );
}

class PexApp extends ConsumerStatefulWidget {
  const PexApp({super.key});

  @override
  ConsumerState<PexApp> createState() => _PexAppState();
}

class _PexAppState extends ConsumerState<PexApp> {
  late final GoRouter _router = createAppRouter(ref.read(brandProvider));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectWithRetry());
  }

  /// 连接后端并完成启动初始化，失败按源项目逻辑每秒重试。
  Future<void> _connectWithRetry() async {
    final AppStartupNotifier notifier = ref.read(appStartupProvider.notifier);
    while (mounted) {
      final bool ok = await notifier.runOnce();
      if (ok) return;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final BrandConfig brand = ref.watch(brandProvider);
    return MaterialApp.router(
      title: brand.displayName.enUS,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(brand),
      routerConfig: _router,
    );
  }
}
