# 项目计划（projectPlan）

> 状态标记：`[ ]` 待办 / `[>]` 进行中 / `[⏸]` 被阻塞 / `[x]` 已完成
>
> 项目：把 `pex-user-uniapp`（uni-app/Vue）迁移为 `pex-user-flutter`（Flutter 真原生）
> 立项日期：2026-09-29

## 决策记录（2026-09-29 与老板确认）

| 编号 | 决策项 | 结论 | 备注 |
| ---- | ------ | ---- | ---- |
| D1 | 推进策略 | **垂直切片先行** | 先端到端打通一条最小闭环验证架构，再批量迁移 |
| D2 | 状态管理 | **Riverpod** | 把 `wo.ss` 拆成显式 Provider，编译期安全、易测试 |
| D3 | 品牌方案 | **单仓库 + Flutter flavors** | 差异收敛到 `brands/` 配置层 + 三品牌入口；理由见 `architecture.md` |
| D4 | 首个功能域 | **账户/登录注册** | 所有功能的前置，逻辑独立，最适合验证架构 |
| D5 | 配置来源 | 后端 `first_touch` 下发为主，本地最小兜底 | `envar-config.js` 是 Node 文件，Flutter 无法直接消费 |
| D6 | Dart 文件命名 | **snake_case**（`home_portal_page.dart`） | Dart 官方惯例 + `flutter_lints` 强制；AGENTS.md 允许「强冲突时遵循流行惯例」 |
| D7 | 本地后端端口 | **`http://localhost:7739`** | 已实测监听并返回 200；老板曾写 6173（未监听，笔误） |

---

## 阶段零 · 蓝图与骨架

**阶段目标**：技术选型落定并沉淀为文档；搭出可编译的 Flutter 工程骨架；建立迁移台账；打通后端连接。

**验收标准**：空壳工程能分别编译出 Web / iOS / Android 产物；能连上本地 `pex-server-torm` 完成 `first_touch`。

- [x] 决策 D1–D7 与老板确认
- [x] 编写 `architecture.md`：技术选型 + uniapp→Flutter 映射表
- [x] 建立 `migrationLedger.md`：48 页面 + 65 组件 + 通用件的迁移台账（源↔目标↔状态）
- [x] 初始化 Flutter 工程（`flutter create`，android/ios/web/macos/windows）+ lib 分层（brands/core/pages/widgets/theme/assets）
- [x] 品牌机制落地：`brands/` 配置层 + 三品牌入口（`main_agidin/babelyx/tryapp.dart`）+ Android flavors（已验证 `installAgidin/Babelyx/Tryapp*`）
- [x] 网络层：`core/api/api_client.dart` 封装 `callBase`（Dio）+ `first_touch` 联调（实测 200 / SUCCESS / 30 键 envarBase）
- [x] i18n 层：`LangText` + `ll()` + `Phrases` + `PartLangTable`，四语种
- [x] 路由层：`go_router`（`app_router.dart`），对齐 `pages.json` 命名
- [x] 响应式断点框架：`DeviceInfo`（inPc/inPad/inPhone）+ `PartWindow` 等价物
- [x] 编译验证：`flutter analyze` 0 问题；`flutter build web --release` 成功
- [ ] iOS / macOS / Windows flavors（阶段五）
- [ ] WebSocket 基础连接（并入阶段一）

---

## 阶段一 · 框架 + homePortal 首发验证（Walking Skeleton）

> 老板指令（2026-09-29）：**先建立框架，然后实现第一个 homePortal 页面，验证可行性后继续实现所有页面。**
> `homePortal` 是理想的验证页：用到 `partWindow` 布局、`partButtonSubmit`/`partShortcuts`/`partLangTable` 组件、
> envar 数据（portalImage/recocards/newsline/slogans/linkTree）、i18n、响应式（inPc/inPhone）与自动登录态。

**阶段目标**：端到端打通 `启动 → 品牌/地区/语言 → first_touch → 自动登录 → 路由 → 响应式布局`，并完整迁移 `homePortal`，三端运行。

**验收标准**：Web / iOS / Android 三端可运行 `homePortal`，视觉与 `localhost:8080`（或 `u.agidin.com`）一致；自动登录态正确；架构可复制到后续页面。

- [ ] 启动流程（对齐 `App.vue onLaunch`）：地区/语言解析、`first_touch` 重试、envar 覆盖、启动通知
- [ ] 布局框架：`partWindow` / `partWindowHeader` / `partWindowFooter` / `partWindowLayout`
- [ ] 通用件：`partButtonSubmit` / `partShortcuts` / `partLangTable`（含 `partLangPicker`）
- [ ] **页面 `homePortal`（首发验证）**：portal 背景、recocards、newsline、slogans、出发按钮、备案底栏
- [ ] 自动登录 + `_passtoken` 本地存储；WebSocket 基础连接
- [ ] 回归：与 uniapp 逐页视觉比对，沉淀比对方法（本地 8080 / 线上 u.agidin.com）

### 阶段一续 · 账户/登录注册闭环（首个完整功能域 D4）

- [x] 布局框架：`part_window_layout_ident`（含 PC 顶栏/页脚/二级导航）
- [x] 页面：`ident_begin` / `ident_new_register` / `ident_new_regcode` / `ident_new_passcode` / `ident_old_login` / `ident_old_passcode` / `ident_old_reset`
- [x] 通用件：`part_button_passcode` / `part_countdown` / `part_passcode_verify` / `part_password_form` / `part_passcode_input` / `part_land_table`
- [x] PC 框架：`part_window_header` / `part_window_footer` / `part_navibar_pc(_fixed)` / `part_show_loading` / `part_breathing_opacity`
- [x] 端到端自检：`tool/check_ident_flow.dart`（注册→验证→登录全链路 + hash 一致性）
- [ ] 页面：`midAgidin`（品牌落地中间页，实为 AI 域，暂为占位）
- [ ] 验收：三端完成「注册 → 验证码 → 登录 → 自动登录 → 登出」（Web 已通，iOS/Android 待验证）
- [ ] WebSocket 接入（登录后 `SOCKET_OWNER`）

---

## 阶段二 · 框架组件层

**阶段目标**：把 `parts/` 中的框架与通用组件全部迁移，为业务域铺路。

**验收标准**：框架组件在 web/手机两种布局下行为一致；业务页面可直接复用。

- [ ] 框架：`partWindowLayoutUser`、`partNavibarPc`、`partNavibarPcFixed`、`partNavilink`、`partLinkview`
- [ ] 通用：`partLoadMore` / `partEmptyList` / `partShowLoading` / `partTooltip` / `partCloseButton` / `partIcontext*` / `partLinkhelp` / `partUserList` / `partMenuCircle` / `partMenuRing` / `partShortcuts` / `partBreathingDot` / `partBreathingOpacity` / `partDev`
- [ ] 语言/地区/币种选择器：`partLangTable` / `partCoinPicker` / `partCoinTable`

---

## 阶段三 · 业务域迁移

**阶段目标**：按功能域逐个交付，每域含页面 + 专属组件 + 与后端联调。

**验收标准**：每个域在三端可完整走通主流程。

- [>] 3A AI 域（第一轮已完成主干）
  - [x] 页面：`mid_agidin_page`（AI 对话落地页）/ `menu_aipp_page`（Aibot 市场）/ `menu_aipp_aichat_page`
  - [x] 组件：`part_aichat`（核心：消息列表/输入/story 模式/发送/操作菜单/设置条）
  - [x] 组件：`part_story_reader` / `part_story_editor` / `part_text_reader`（**跨域内容容器**）
  - [x] 组件：`part_aipp_models` / `part_aipp_shared` / `part_aipp_picked` / `ai_model_tile` / `part_load_more` / `part_window_layout`
  - [-] 页面：`menuAippCreate(+)` / `menuAippModify(+)`；组件：`part_aipp_editor` —— **不做**（Aibot 已被 agent 概念超越，Agidin 待重新构思）
  - [ ] 组件：`part_menu_ring` / `part_pop_link` / `part_deposit` / `part_sound_recorder`
  - [x] story 段落媒体上传（`Fileloader/receiveFile` + 选择器 + 段落写入，已实测 SUCCESS）
  - [ ] 语音输入 · TTS 自动朗读
  - [ ] WebSocket（`SOCKET_OWNER` 登录后握手、`AICHAT_SUCCESS` 推送路径）
- [ ] 3B 创作/NFT 域：`menuCreation` / `menuCreator` / `showCreation`(2227行) / `showCreationUpdate` / `showCreator` / `userResource` / `userResourceDetail`；组件 `partCreate` / `partCreation*` / `partCreator*` / `partStoryEditor`
- [ ] 3C 资金域：`umyFund` / `umyFundChannel` / `umyFundChannelCreate` / `umyFundChannelWithdraw` / `umyFundTranx`；组件 `partDeposit`(1066行) / `partFundChannelCard` / `partTxList` / `partPexdataSummary`
- [ ] 3D 账户/社交域：`menuUzone` / `umyAccount*` / `umyKyc` / `umyInvite*` / `umyCircle` / `umyCollection` / `umyContact` / `umyConfig` / `umyMia*` / `umyAccountTerminate` / `midTryapp` / `midBabely`；组件 `partIdentCommid` / `partComplain`
- [ ] 其余：`showWebview`（webview 容器）

---

## 阶段四 · 原生能力对接

**阶段目标**：把依赖平台能力的交互迁移到原生实现。

**验收标准**：三端（含桌面）原生能力可用。

- [ ] 语音 / TTS / 录音：`partSoundRecorder`（`record` + `audioplayers`，einz 已有经验）
- [ ] 文件上传：`dragFileUploader` + `uni.uploadFile` 等价物（Dio FormData / file_picker）
- [ ] 媒体查看/播放：视频 `video_player`、图片预览
- [ ] 支付跳转、外部链接唤起（`url_launcher`）、分享
- [ ] IPFS / 链上交互（`tic-crypto` 等价物、NFT 铸造）

---

## 阶段五 · 构建发布与回归

**阶段目标**：三品牌 × 五平台的构建发布流水线；与 uniapp 全量回归对比；上线。

**验收标准**：一键构建各端产物；发布流程可重复。

- [ ] GitHub Actions（参考 `einz/.github`）：Web / iOS / Android / macOS / Windows
- [ ] 三品牌 flavors 产物：包名 / 图标 / 启动图 / 版本号（对齐 `YYMMDDHH` 版本码约定）
- [ ] Web 部署（Cloudflare Pages）与 APK/IPA 分发等价流程
- [ ] 全量页面视觉与功能回归；未迁移项清单确认

---

## 风险与对策

| 编号 | 风险 | 对策 |
| ---- | ---- | ---- |
| R1 | `wo.ss` 全局单例被隐式依赖，Riverpod 化易遗漏 | 阶段一即建立 Provider 分层规范；用 lint 禁止直接全局访问 |
| R2 | 内联多语言 `wo.ll({...})` 无集中词条，翻译量大 | 建词条抽取脚本 + 集中表；保持四语种键一致 |
| R3 | `envar-config.js`（2417 行，Node 依赖）无法直接复用 | 以后端 `first_touch` 下发为唯一真源，本地仅最小 fallback |
| R4 | PC 网页布局 vs 手机 App 布局差异大 | 尽早沉淀 `partWindow*` 等价框架，作为所有页面的底座 |
| R5 | 大页面（`showCreation` 2227 行 / `partAichat` 1504 行）迁移难 | 按子组件拆解后再迁移；单页面独立 commit 可回滚 |
| R6 | 与 uniapp 视觉漂移 | 建立逐页截图比对流程（Playwright 截 uniapp，Flutter 截原生） |
| R7 | 品牌差异散落代码分支 | 收敛到 `brands/` 配置层，业务代码只读配置、不判 appkey |
