# 架构与技术决策（architecture）

> 记录 `pex-user-flutter` 的技术选型与 uniapp → Flutter 的迁移映射，供跨 session 复用。
> 最后更新：2026-09-29

## 一、总原则

1. **真原生**：编译出 iOS / Android / macOS / Windows 原生 App，一套代码同时出 Web。
2. **保持同构**：目录结构、页面结构、业务逻辑尽量与 `pex-user-uniapp` 一一对应，降低对照与回归成本。
3. **显式优于隐式**：源项目的全局单例 `wo.*` 改为显式依赖注入（Riverpod Provider）。
4. **单一真源**：品牌差异收敛到 `brands/` 配置层；运行期配置以后端 `first_touch` 下发为唯一真源。

## 二、技术选型

| 维度 | 选型（实际版本） | 替代源项目 |
| ---- | ---- | ---- |
| 状态管理 | `flutter_riverpod` ^3.4.3 | Vuex `wo.store` + 全局 `wo.ss` |
| 路由 | `go_router` ^18.0.2 | `pages.json` + `uni.navigateTo/switchTab/reLaunch` |
| 网络 | `dio` ^5.11.1 | `wo.tt.callBase` |
| 实时 | `web_socket_channel` ^3.0.3 | `wo-user-websocket-uniapp`（MIA 消息） |
| 本地存储 | `shared_preferences` ^2.5.5（＋后续 `flutter_secure_storage`） | `uni.getStorageSync` |
| i18n | 自建 `LangText` + `ll()` | 内联 `wo.ll({zhCN,enUS,jaJP,deDE})` |
| 响应式 | `DeviceInfo` + `PartWindow` | `inPc/inPad/inPhone` + `partWindow*` |
| 媒体（待用） | audioplayers / record / video_player / image_picker | `innerAudioContext` / `RecorderManager` |
| 文件（待用） | file_picker / Dio FormData | `uni.uploadFile` / `dragFileUploader` |
| 外部链接（待用） | url_launcher | `wo.tt.open_url` |
| 构建发布（待用） | GitHub Actions + flavors | `create` / `deploy` 脚本 |

## 三、命名约定（重要：与源项目不同）

**Dart 文件用 snake_case**（`home_portal_page.dart`），而非源项目 Vue 的 camelCase（`homePortal.vue`）。

**Why**：Dart 官方惯例为 snake_case，且 `flutter_lints` 的 `file_names` 规则默认强制；`AGENTS.md` 明确允许「与流行惯例强冲突时遵循流行惯例」。老板 2026-09-29 确认采用。

**How to apply**：
- 文件/目录：snake_case（`core/api/api_client.dart`）。
- 类名：UpperCamelCase（`ApiClient`）；对应 `partXxx` → 类名 `PartXxx`（如 `PartWindow`），文件 `part_window.dart`。
- 与源项目对照时以「类名/页面名」为锚点，文件名映射见 `migrationLedger.md`。

## 四、品牌方案（D3）

**结论：单仓库 + Flutter flavors。** 业务代码只读 `BrandConfig`，**不判 appkey**。

```text
lib/
├── main.dart              # 默认入口（--dart-define=BRAND=AKAGIDIN 决定品牌）
├── main_agidin.dart       # 品牌入口
├── main_babelyx.dart
├── main_tryapp.dart
├── app.dart               # runPexApp() + PexApp（ProviderScope / MaterialApp.router）
├── brands/                # 品牌差异层
│   ├── brand_config.dart  # 抽象 BrandConfig
│   ├── agidin_brand.dart
│   ├── babelyx_brand.dart
│   ├── tryapp_brand.dart
│   └── brand_registry.dart
├── core/
│   ├── api/               # api_client.dart（callBase）、client_info.dart
│   ├── i18n/              # lang_text.dart、i18n.dart、phrases.dart
│   ├── responsive/        # device_info.dart（断点与设备判定）
│   ├── router/            # app_router.dart（go_router）
│   ├── state/             # app_providers.dart、app_startup_notifier.dart
│   └── storage/           # local_store.dart
├── pages/                 # 对应源项目 pages/
├── widgets/               # 对应源项目 parts/
├── theme/                 # app_theme.dart（由品牌主色生成）
└── assets/brands/<brand>/ # logo.png / portal.jpg
```

**为何不拆成三个独立仓库**：约 95% 代码三品牌共用，拆分会复制三份并导致长期漂移；flavors 已能产出独立包名/图标/上架的独立 App，同时保留单一代码源。若某品牌未来业务严重分叉，再抽库拆分。

### flavors 落地状态

| 平台 | 状态 | 说明 |
| ---- | ---- | ---- |
| Android | `[已实现]` | `android/app/build.gradle.kts` 定义 `flavorDimensions "brand"` + 三个 flavor（applicationId / resValue `app_name`）；`buildFeatures.resValues = true`；AndroidManifest 用 `@string/app_name`。已用 `gradlew :app:tasks` 验证 `installAgidin/Babelyx/Tryapp*` 生成。 |
| Web | `[已实现]` | 用不同入口：`flutter build web -t lib/main_agidin.dart`。 |
| iOS / macOS / Windows | `[待开发]` | 需 xcconfig + Xcode schemes（iOS 需在 Xcode 中操作）；阶段五处理。 |

## 五、启动流程映射（对齐 `App.vue onLaunch`）

```text
1. 初始化本地存储（mylang / userlandCode / _passtoken）
2. 解析地区与语言（webland / userland / 邀请码）
3. first_touch → 拉 envarBase 覆盖本地 → 判定 _stateLogin 自动登录
4. 建立 WebSocket（待迁移）
5. 启动通知 / 版本升级提示（待迁移）
```

已实现：步骤 1–3。`AppStartupNotifier.runOnce()` 执行一轮 `first_touch`，`app.dart` 按 1 秒间隔重试。

## 六、API 契约（已实测）

- 路径：`POST {base}/api/{apiWho}/{apiTodo}`
- 请求体：`apiWhat` + `_clientInfo`（含 `lang`/`webDomain`/平台信息）+ `_passtoken`
- 响应：`_state`（成功经 `bok()` 判定）+ 数据；`_stateLogin` 为自动登录结果
- 后端模块：`User` / `Creation` / `Mia` / `Aimodel` / `EthAccount` / `Moderator` / `System`

**实测（2026-09-29，本地 7739）**：`first_touch` 返回 `HTTP 200`、`_state = SUCCESS`、`_stateLogin = MISSING_USID`、`envarBase` 30 个键（含 `slogans`/`newsline`/`linkNews`/`linkSlogan`/`servUrl`/`linkTree`/`aiModelSet`）。

## 七、开发环境与地址

| 用途 | 地址 | 备注 |
| ---- | ---- | ---- |
| 本地后端 | **`http://localhost:7739`** | 已确认：`keyname_to_apiport('pex') = BASEPORT_API_SERVER + alphaToDigit('pex') = 7739`，实测监听并返回 200。（老板曾写 6173，实测未监听，为笔误） |
| 源项目 HBuilderX 预览 | `http://localhost:8080` | 逐页视觉比对 |
| 线上源项目（回归参照） | `https://u.agidin.com`、`https://u.babelyx.com` | 可用 Playwright/Puppeteer 抓图比对 |

- 开发时用 `--dart-define=API_BASE=http://localhost:7739` 指向本地后端；默认走生产 `https://pexserver.tic.cc`。
- 连通性自检脚本：`dart run tool/check_first_touch.dart [baseUrl]`。

## 八、待评审事项

- `tic-crypto`（加密/链上）在 Flutter 的等价实现方案待调研。
- 图片/视频资源的品牌化与 `static/` 命名映射。
- go_router 与 Web hash 路由的兼容（外部链接 `#/pages/xxx`）。
- iOS / macOS / Windows 的 flavors 落地方案（阶段五）。
- Android 包名暂用 `cc.tic.agidin|babelyx|tryapp`（源项目无现成 bundle id，待确认）。
