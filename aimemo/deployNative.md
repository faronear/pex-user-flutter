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
- **图标**：三个品牌共用默认 Flutter 图标，按需替换 `ios/Runner/Assets.xcassets/AppIcon.appiconset` 与 `android/app/src/main/res/mipmap-*`。
- **Android 本机未验证**：当前开发机没有 Android SDK，只做了配置正确性检查，未实际 `flutter build apk`。

## 验证状态
- iOS：`agidin` / `babelyx` flavor 已在 Xcode 26 模拟器构建成功，`Agidin.app` / `Babelyx.app` 产出，bundle id 与应用名正确，权限描述已注入。
- Android：配置就绪，待有 SDK 的机器验证。
