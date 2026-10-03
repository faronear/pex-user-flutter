# 原生构建（iOS / Android）

三品牌用 **Flutter flavors** 区分：Dart 侧入口 `lib/main_<brand>.dart` 决定品牌，原生侧决定包名 / 应用名。

## 包名 / 应用名

| 品牌 | Android applicationId | iOS bundle id | 应用名 |
|---|---|---|---|
| agidin | `cc.tic.agidin` | `cc.tic.agidin` | Agidin |
| babelyx | `cc.tic.babelyx` | `cc.tic.babelyx` | Babelyx |
| tryapp | `cc.tic.tryapp` | `cc.tic.tryapp` | TRYAPP |

## iOS 配置（已验证可构建）
- `ios/Flutter/<Brand>-Debug.xcconfig` / `-Release.xcconfig`：`#include` Pods 配置 + `Generated.xcconfig`，覆盖 `PRODUCT_BUNDLE_IDENTIFIER` / `PRODUCT_NAME`。
- `ios/Runner.xcodeproj/project.pbxproj`：为 Project / Runner / RunnerTests 三套列表各加了 `Debug-<brand>` / `Release-<brand>` 构建配置（已验证 `xcodebuild -list` 能看到）。
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/<brand>.xcscheme`：共享 scheme，构建配置指向对应 flavor。
- `ios/Runner/Info.plist`：`CFBundleDisplayName` / `CFBundleName` 用 `$(PRODUCT_NAME)`（随 flavor 变），并加了相机 / 相册权限描述。
- 生成脚本：`tool/_gen_ios_flavors.py`（如需重生成可跑，但已落地，勿重复跑——会再加一遍配置）。

## Android 配置（配置正确，本机未验证编译）
- `android/app/build.gradle.kts`：`flavorDimensions += "brand"` + 三个 `productFlavors`（applicationId + `resValue app_name`）。
- `android/app/src/main/AndroidManifest.xml`：加了 INTERNET / CAMERA / READ_MEDIA_* / READ_EXTERNAL_STORAGE 权限；应用名走 `@string/app_name`（由 flavor 注入）。

## 构建脚本（package.json）
本地（连 localhost 后端，构建 apk / 模拟器 ipa）：
- `npm run build:android:agidin|babelyx|tryapp` → `flutter build apk --flavor <brand> -t lib/main_<brand>.dart --dart-define=API_BASE=http://localhost:7739`
- `npm run build:ios:agidin|babelyx|tryapp` → `flutter build ios --flavor <brand> -t lib/main_<brand>.dart --dart-define=API_BASE=http://localhost:7739 --simulator`

生产（连 pexserver.tic.cc，aab / 真机 ipa）：
- `npm run build:android:prod:agidin|babelyx|tryapp` → `flutter build appbundle --flavor <brand> -t lib/main_<brand>.dart --dart-define=API_BASE=https://pexserver.tic.cc`
- `npm run build:ios:prod:agidin|babelyx|tryapp` → `flutter build ios --flavor <brand> -t lib/main_<brand>.dart --dart-define=API_BASE=https://pexserver.tic.cc`

## 待办（需老板在有凭据的机器上完成）
- **iOS 签名**：Xcode 里选 Apple Developer Team（模板里 `DEVELOPMENT_TEAM = 37KQR6645B` 是占位，需改成你的 Team ID），并配 provisioning profile；`build:ios:prod` 走真机/Archive 才需要。
- **Android 签名**：`build.gradle.kts` 的 release 现在用 debug key（TODO），上架前配 `signingConfigs` 与 keystore。
- **图标**：✅ 已替换为三品牌官方 logo（见下「应用图标」）。
- **Android 本机未验证**：当前开发机没有 Android SDK，只做了配置正确性检查，未实际 `flutter build apk`。

## 应用图标（已替换）

源 logo 与产物（生成器：`tool/_gen_brand_icons.py`，产物已提交）：

| 品牌 | 源图 | iOS 产物 | Android 产物 |
|---|---|---|---|
| agidin | `pex-app-doc/agidin-爱奇点/图标/logo-circle-closed-bgWhite-appicon-1024.png`（白底不透明） | `ios/Runner/Assets.xcassets/AppIcon-agidin.appiconset/` | `android/app/src/agidin/res/mipmap-*/ic_launcher.png` |
| babelyx | `pex-app-doc/babelyx-巴贝历/logo_标志/logo-babely-bgWhite-fgRedWhite-appicon-1024.png`（RGBA） | `ios/Runner/Assets.xcassets/AppIcon-babelyx.appiconset/` | `android/app/src/babelyx/res/mipmap-*/ic_launcher.png` |
| tryapp | `pex-user-uniapp/static/logoTryapp.png`（RGBA, 512） | `ios/Runner/Assets.xcassets/AppIcon-tryapp.appiconset/` | `android/app/src/tryapp/res/mipmap-*/ic_launcher.png` |

- iOS：在 `project.pbxproj` 的六个 flavor 构建配置里设了 `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon-<brand>`，flavor 各自用独立图标集。
- **注意**：babelyx / tryapp 源图带透明（alpha），iOS 渲染图标会把 alpha 压平为黑色导致黑角；生成器已用 Pillow 先把源图**压平到白底**再 resize，三品牌图标均为不透明 RGB、四角白色。换 logo 重跑生成器即可。

## 验证状态
- iOS：`agidin` / `babelyx` / `tryapp` 三个 flavor 均已构建成功（模拟器），`Agidin.app` / `Babelyx.app` / `TRYAPP.app` 产出，bundle id、应用名、权限描述、品牌图标均正确。
- Android：配置就绪，待有 SDK 的机器验证。
