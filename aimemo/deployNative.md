# 原生构建（iOS / Android）

多品牌用 **Flutter flavors** 区分：Dart 侧入口 `lib/main_<brand>.dart` 决定品牌，原生侧决定包名 / 应用名。

> 品牌数量不写死在本文档：新增品牌时按下表格式补一行，并同步
> `android/app/build.gradle.kts`（`productFlavors`）、`ios/Flutter/<Brand>-*.xcconfig`、
> `project.pbxproj`（构建配置）、`xcshareddata/xcschemes/<brand>.xcscheme`、
> `AppIcon-<brand>.appiconset`、`package.json`（构建脚本）、`brands/` 配置层与 `main_<brand>.dart`。

## 包名 / 应用名

| 品牌 | Android applicationId | iOS bundle id | iOS 应用名 |
|---|---|---|---|
| agidin | `cc.tic.agidin` | `cc.aizoi.app.dist.ios` | Agidin |
| babelyx | `cc.tic.babelyx` | `faronear.babely.app.ios.dist` | Babelyx |

> iOS bundle id 与 Android 不同：iOS 沿用开发者账户里已注册的分发 profile 所绑定的 id
> （详见下「iOS 签名」），Android 用 `cc.tic.<brand>`。两者互不影响。

## iOS 配置（已验证可构建）
- `ios/Flutter/<Brand>-Debug.xcconfig` / `-Release.xcconfig`：`#include` Pods 配置 + `Generated.xcconfig`，覆盖 `PRODUCT_BUNDLE_IDENTIFIER` / `PRODUCT_NAME` / `DEVELOPMENT_TEAM`。
- `ios/Runner.xcodeproj/project.pbxproj`：为 Project / Runner / RunnerTests 三套列表各加了 `Debug-<brand>` / `Release-<brand>` 构建配置（已验证 `xcodebuild -list` 能看到）。
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/<brand>.xcscheme`：共享 scheme，构建配置指向对应 flavor。
- `ios/Runner/Info.plist`：`CFBundleDisplayName` / `CFBundleName` 用 `$(PRODUCT_NAME)`（随 flavor 变），并加了相机 / 相册权限描述。
- 生成脚本：`tool/_gen_ios_flavors.py`（如需重生成可跑，但已落地，勿重复跑——会再加一遍配置）。

## Android 配置（已验证可构建与签名）
- `android/app/build.gradle.kts`：`flavorDimensions += "brand"` + 每个品牌一个 `productFlavors`（applicationId + `resValue app_name`）。
- `android/app/src/main/AndroidManifest.xml`：加了 INTERNET / CAMERA / READ_MEDIA_* / READ_EXTERNAL_STORAGE 权限；应用名走 `@string/app_name`（由 flavor 注入）。

## 构建脚本（package.json）
本地（连 localhost 后端，构建 apk / 模拟器 app）：
- `npm run build:android:<brand>` → `flutter build apk --flavor <brand> -t lib/main_<brand>.dart --dart-define=API_BASE=http://localhost:7739`
- `npm run build:ios:<brand>` → `flutter build ios --flavor <brand> -t lib/main_<brand>.dart --dart-define=API_BASE=http://localhost:7739 --simulator`

生产（连 pexserver.tic.cc，aab / 真机 app / 上架 IPA）：
- `npm run build:android:prod:<brand>` → `flutter build appbundle --flavor <brand> -t lib/main_<brand>.dart --dart-define=API_BASE=https://pexserver.tic.cc`
- `npm run build:ios:prod:<brand>` → `flutter build ios --flavor <brand> -t lib/main_<brand>.dart --dart-define=API_BASE=https://pexserver.tic.cc`（只出 .app）
- `npm run build:ios:ipa:<brand>` → `flutter build ipa ...` + `ios/ExportOptions-appstore.plist`（上架用）

## 待办 / 已完成
- **iOS 签名**：✅ 已完成并验证（见下「iOS 签名」）。Team `CQ6733CTMV` (Faronear Co. Ltd.)，两个品牌用 App Store 分发 profile 手动签名。
- **Android 签名**：✅ 已复用 einz 的 `key.properties`（同一 keystore）完成真实签名验证（见下「Android 签名」）。
- **图标**：✅ 已替换为各品牌官方 logo（见下「应用图标」）。
- **未来新增品牌**：需为其申请分发 profile（iOS）并把 Android 包名加入 flavors。

## iOS 签名（已配置并验证）
- Team：`CQ6733CTMV`（Faronear Co. Ltd.）。Apple Distribution 证书已在本机钥匙串（`Apple Distribution: Faronear Co. Ltd. (CQ6733CTMV)`）。
- App Store 分发 profile 已安装到 `~/Library/MobileDevice/Provisioning Profiles/`（按 UUID 命名）：
  - `Agidin_Dist_Appstore.mobileprovision` → UUID `25d732be-...`（profile 名 `Agidin Dist Appstore`）
  - `Babelyx_Dist_Appstore.mobileprovision` → UUID `3acc0719-...`（profile 名 `Babelyx Dist Appstore`）
- bundle id 沿用 profile 内绑定的 id（老板决定，2026-10-03）：
  - agidin → `cc.aizoi.app.dist.ios`（⚠️ 来自 profile 旧命名 aizoi，非 `cc.tic.agidin`）
  - babelyx → `faronear.babely.app.ios.dist`
- 配置落点：`ios/Flutter/<Brand>-*.xcconfig` 设 `DEVELOPMENT_TEAM`；`project.pbxproj` 的 Runner target 各 flavor 配置里设 `CODE_SIGN_STYLE=Manual` + `CODE_SIGN_IDENTITY=Apple Distribution` + `PROVISIONING_PROFILE_SPECIFIER`。
- **Ad Hoc 分发**：老板准备 Ad Hoc profile 后，把 `PROVISIONING_PROFILE_SPECIFIER` 与 `ios/ExportOptions-appstore.plist` 里的 profile 名换成 Ad Hoc 的即可（身份仍 `Apple Distribution`）。

## Android 签名（已配置并验证）
- `android/app/build.gradle.kts` 加了 `signingConfigs.release`，从 gitignore 的 `android/key.properties` 读 storePassword/keyPassword/keyAlias/storeFile（Kotlin DSL 用 `getProperty`，且 `import java.util.Properties` 须放在 `plugins {}` 之后）。
- `android/key.properties`（已 gitignore，不提交）**直接复用 einz 的同一 keystore**：`storeFile=/Volumes/repodisk/productX/einz/app/android/android.keystore.jks`，`keyAlias=android.keystore`，store/key 口令同 einz。`key.properties` 不存在时 release 回退 debug key。
- 验证：`ANDROID_HOME=/Users/luk/Library/Android/sdk npm run build:android:prod:agidin` → 产出 `app-agidin-release.aab`（已签名，cert subject CN=yuanjin）。其它品牌同 keystore 同理。

## 应用图标（已替换）

源 logo 与产物（生成器：`tool/_gen_brand_icons.py`，产物已提交）：

| 品牌 | 源图 | iOS 产物 | Android 产物 |
|---|---|---|---|
| agidin | `pex-app-doc/agidin-爱奇点/图标/logo-circle-closed-bgWhite-appicon-1024.png`（白底不透明） | `ios/Runner/Assets.xcassets/AppIcon-agidin.appiconset/` | `android/app/src/agidin/res/mipmap-*/ic_launcher.png` |
| babelyx | `pex-app-doc/babelyx-巴贝历/logo_标志/logo-babely-bgWhite-fgRedWhite-appicon-1024.png`（RGBA） | `ios/Runner/Assets.xcassets/AppIcon-babelyx.appiconset/` | `android/app/src/babelyx/res/mipmap-*/ic_launcher.png` |

- iOS：在 `project.pbxproj` 的各 flavor 构建配置里设 `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon-<brand>`，flavor 各自用独立图标集。
- **注意**：babelyx 源图带透明（alpha），iOS 渲染图标会把 alpha 压平为黑色导致黑角；生成器已用 Pillow 先把源图**压平到白底**再 resize，图标为不透明 RGB、四角白色。换 logo 重跑生成器即可。

## 验证状态
- iOS：`agidin` / `babelyx` flavor 已用各自 App Store profile **真机构建并成功签名**（`flutter build ios --flavor ...` 出 `Agidin.app`/`Babelyx.app`，embedded profile 校验为对应 profile 名，bundle id 见上表）。`xcodebuild -list` 确认工程结构完好。
- Android：`agidin` aab 已用共用 keystore 真实签名构建成功（`app-agidin-release.aab`，58.3MB），另一品牌同 keystore 同理可用。
