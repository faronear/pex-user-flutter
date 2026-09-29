# 工作日志（worklog）

> 只追加，每次有变化就记录。

## 2026-09-29

**项目立项：pex-user-uniapp（uni-app）→ pex-user-flutter（Flutter 真原生）迁移**

- 阅读现有文档：本仓 `AGENTS.md`、`aimemo/productLens.md`；并行项目 `pex-user-uniapp/aimemo/*`（productLens/projectPlan/worklog/userProfile/cacheWebFilesArchitecture）、`einz/AGENTS.md`+`README.md`。
- 勘察源项目规模：`pages/` 47 个 .vue（11,236 行）、`parts/` 65 个 part*.vue（10,750 行）、`main.js` 全局 `wo` 对象、`App.data.js`（Vuex + envar/i18n/业务状态）、`envar-config.js`（2,417 行，硬链接后端）、后端 `pex-server-torm`（Express+TypeORM+SQLite，7 个 api 模块）。
- 梳理关键迁移难点：全局单例 `wo.*`、内联多语言 `wo.ll({...})`、PC/手机双布局 `partWindow*`、easycom 组件体系、`envar-config.js` 无法直接消费、WebSocket、原生能力、构建发布链路。
- 与老板讨论并确认 4 项决策：
  - **D1 推进策略**：垂直切片先行（先打通最小闭环验证架构）。
  - **D2 状态管理**：Riverpod。
  - **D3 品牌方案**：老板认可"单仓库 + Flutter flavors"（差异收敛到 `brands/` 配置层 + 三品牌入口；不排除未来独立成仓）。
  - **D4 首个功能域**：账户/登录注册。
- 老板亲自编辑 `aimemo/productLens.md`，补充：
  - 本地后端端口 `http://localhost:6173`（与 `pex/AGENTS.md` 的 `7739` 不一致，已列入待核对）；
  - 线上参照 `https://u.agidin.com` / `https://u.babelyx.com`；
  - **指令：先建立框架 → 实现第一个 `homePortal` 页面验证 → 再实现所有页面。**
- 落盘计划文档：`projectPlan.md`（决策记录 + 阶段零~五 + 风险）、`architecture.md`（技术选型 + uniapp→Flutter 映射 + 环境地址）、`userProfile.md`（老板画像）、本 `worklog.md`。
- `homePortal.vue` 评估：适合作为首发验证页（含布局/组件/envar/i18n/响应式/自动登录）。
- **待办**：阶段零（迁移台账、Flutter 工程骨架、品牌机制、网络/i18n/路由/响应式底座），随后实现 `homePortal` 验证。

### 阶段零执行（同日）

- **端口澄清**：实测 `keyname_to_apiport('pex') = 7739`（`BASEPORT_API_SERVER + alphaToDigit('pex')`），且本地 7739 正在监听；`6173` 未监听（老板笔误）。本地后端定为 **7739**。
- **工程初始化**：在仓库根目录 `flutter create`（flutter 3.47.2 / Dart 3.13.2），平台 android/ios/web/macos/windows；添加依赖 riverpod 3.4.3 / go_router 18.0.2 / dio 5.11.1 / web_socket_channel 3.0.3 / shared_preferences 2.5.5 / intl。
- **迁移台账**：新建 `aimemo/migrationLedger.md`，逐项登记 48 页面 + 65 组件（含行数）+ 通用组件 + 非 UI 资产。
- **框架代码**（`lib/`）：
  - `brands/`：`brand_config.dart` 抽象 + 三品牌实现 + `brand_registry.dart`（`--dart-define=BRAND=`）
  - `core/api/`：`api_client.dart`（Dio 封装 `callBase`，`bok()` 判定）、`client_info.dart`
  - `core/i18n/`：`lang_text.dart`（`LangText`，替代内联 `wo.ll`）、`i18n.dart`（`languageProvider` + `ll()`）、`phrases.dart`
  - `core/responsive/device_info.dart`：inPc/inPad/inPhone/inWeb/inApp 判定
  - `core/router/app_router.dart`：go_router，路由名与源项目页面名一致
  - `core/state/`：`app_providers.dart`（brand/store/clientInfo/apiClient Provider）、`app_startup_notifier.dart`（first_touch + 自动登录状态）
  - `core/storage/local_store.dart`：shared_preferences 封装（`_passtoken`/`mylang`）
  - `app.dart`（`runPexApp` + `PexApp`）、四个入口 `main*.dart`
  - `pages/home_portal_page.dart`（首发验证页）、`widgets/`（`part_window` / `part_button_submit` / `part_lang_table`）
- **命名决策 D6**：Dart 文件采用 **snake_case**（Dart 官方惯例 + `flutter_lints.file_names` 强制），类名仍 UpperCamelCase；老板确认。
- **flavors**：Android `productFlavors`（agidin/babelyx/tryapp，applicationId + `resValue app_name`）；踩坑：需 `buildFeatures.resValues = true`（AGP 8 默认关闭）→ 已修正，`gradlew :app:tasks` 验证 `installAgidin/Babelyx/Tryapp*` 生成。iOS/macOS/Windows flavors 待阶段五。
- **验证**：`flutter analyze` **0 问题**；`flutter build web --release` **成功**；`dart run tool/check_first_touch.dart` → 本地后端 `HTTP 200 / _state=SUCCESS / _stateLogin=MISSING_USID / envarBase 30 键`。
- **待办**：`homePortal` 的视觉校验（与 `localhost:8080` 或 `u.agidin.com` 对比），随后进入账户/登录注册域。
