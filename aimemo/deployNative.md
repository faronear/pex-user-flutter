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
- **iOS 签名**：✅ 已完成并验证（见下「iOS 签名」）。Team `CQ6733CTMV` (Faronear Co. Ltd.)，agidin/babelyx 用 App Store 分发 profile 手动签名。tryapp 暂无 profile。
- **Android 签名**：已接好 plumbing（见下「Android 签名」），但 `android/key.properties` 的 storePassword/keyAlias/keyPassword 待老板填（keystore 与 einz/app 共用：`/Volumes/repodisk/productX/einz/app/android/android.keystore.jks`）。填好前 release 回退 debug key。
- **图标**：✅ 已替换为三品牌官方 logo（见下「应用图标」）。
- **Android 本机已验证配置**：iMac 有 Android SDK (`/Users/luk/Library/Android/sdk`)，但真实 keystore 签名待填凭据后验证。

## iOS 签名（已配置并验证）
- Team：`CQ6733CTMV`（Faronear Co. Ltd.）。Apple Distribution 证书已在本机钥匙串（`Apple Distribution: Faronear Co. Ltd. (CQ6733CTMV)`）。
- 两个 App Store 分发 profile 已安装到 `~/Library/MobileDevice/Provisioning Profiles/`（按 UUID 命名）：
  - `Agidin_Dist_Appstore.mobileprovision` → UUID `25d732be-...`（profile 名 `Agidin Dist Appstore`）
  - `Babelyx_Dist_Appstore.mobileprovision` → UUID `3acc0719-...`（profile 名 `Babelyx Dist Appstore`）
- bundle id（按你决定改用 profile 里的 id，与 Android 的 `cc.tic.*` 不同，互不影响）：
  - agidin → `cc.aizoi.app.dist.ios`（⚠️ 来自 profile 旧命名 aizoi，非 cc.tic.agidin）
  - babelyx → `faronear.babely.app.ios.dist`
  - tryapp → `cc.tic.tryapp`（暂未申请 profile）
- 配置落点：`ios/Flutter/<Brand>-*.xcconfig` 设 `DEVELOPMENT_TEAM`；`project.pbxproj` 的 Runner target 六个 flavor 配置里 agidin/babelyx 设 `CODE_SIGN_STYLE=Manual` + `CODE_SIGN_IDENTITY=Apple Distribution` + `PROVISIONING_PROFILE_SPECIFIER`。tryapp 仍 Automatic。
- **Ad Hoc 分发**：老板准备 Ad Hoc profile 后，把 `PROVISIONING_PROFILE_SPECIFIER` 与 `ios/ExportOptions-appstore.plist` 里的 profile 名换成 Ad Hoc 的即可（身份仍 `Apple Distribution`）。
- 真机/上架产出 IPA：`npm run build:ios:ipa:agidin|babelyx`（用 `ios/ExportOptions-appstore.plist`，`flutter build ipa`）。`build:ios:prod:*` 只出 .app 不导 IPA。

## Android 签名（plumbing 已接，待填凭据）
- `android/app/build.gradle.kts` 加了 `signingConfigs.release`，从 gitignore 的 `android/key.properties` 读 storePassword/keyPassword/keyAlias/storeFile。
- `android/key.properties`（已 gitignore，不提交）默认指向共用 keystore `/Volumes/repodisk/productX/einz/app/android/android.keystore.jks`；`keyAlias` 行默认注释掉，填好并取消注释后 release 才用真签名，否则回退 debug key。
- 验证：`ANDROID_HOME=/Users/luk/Library/Android/sdk npm run build:android:prod:agidin` 应输出带签名的 aab。

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
- iOS：`agidin` / `babelyx` flavor 已用各自 App Store profile **真机构建并成功签名**（`flutter build ios --flavor ...` 出 `Agidin.app`/`Babelyx.app`，embedded profile 校验为 `Agidin Dist Appstore`/`Babelyx Dist Appstore`，bundle id 分别为 `cc.aizoi.app.dist.ios`/`faronear.babely.app.ios.dist`）。tryapp 仅模拟器验证（无 profile）。
- Android：plumbing 就绪，待填 keystore 凭据后验证真实签名。
