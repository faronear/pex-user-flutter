> [已停用 2026-10-07] 本文件已归档并入 `../../aimemo/`（见 `../../aimemo/README.md` 的来源对照表），请勿再更新。原内容暂时保留，待清理。

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
| D3 | 品牌方案 | **单仓库 + Flutter flavors** | 差异收敛到 `brands/` 配置层 + 多品牌入口；理由见 `architecture.md` |
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
- [x] 品牌机制落地：`brands/` 配置层 + 多品牌入口（`main_agidin/babelyx.dart`）+ Android flavors（已验证 `installAgidin/Babelyx*`）
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
- [>] 3B 创作/NFT 域（Babelyx UGC 主战场，约 7000 行，分 6 批）
  - 规模：页面 3591 行（`showCreation` 2227 为最大页）/ 组件 3486 行（`partCreate` 1012、`partStoryEditor` 763）
  - 接口面：`get_single_creation` / `get_creation_list` / `get_creations_as_{creator,owner,holder,viewer,fueler}` /
    `get_user_creations` / `create_creation` / `story_to_cid` / `upvote_creation` / `pay_to_{view,own,hold}` /
    `unlist_creation` / `unhide_creation` / `get_comment_list`；创作者侧 `get_single_creator` / `get_creator_list` /
    `get_my_{followers,followings}` / `get_invitee_list`；社交 `unfollow_user` / `unblock_user` / `send_mia`
  - 外部依赖：**合约铸造**（`mintNow`/`mintTxHash`/`mintCsid`）、**IPFS**（`story_to_cid`）、`tic-crypto`
  - [ ] 批次1 列表与分类（只读）：`menuCreation` + `partCreationCardList` / `partCreationAll` / `partCreationAs{Creator,Owner,Holder,Viewer,Fueler}`
  - [>] 批次2 作品详情与阅读（`showCreation.vue` 2227 行，**全项目最大页**，已拆为 7 片）
    - 侦察结论：模板含大量 `uni-popup`(13) / `uni-list-item`(10) / `partLoadMore`(6)；
      依赖未迁移组件：`partDeposit`(1066，资金域) · `partUserList` · `partPopLink`(分享) ·
      `partComplain`(举报) · `partIcontextPop` / `partIcontextCopy`(复制菜单) ·
      `partCloseButton` · `partPexdataSummary` · `partStoryEditor`(已有基础版)
    - 先建依赖（可先行、也可随片并行）：`partCloseButton` · `partPexdataSummary` ·
      `partIcontextCopy` · `partUserList` · `partComplain` · `partPopLink`
    - [x] **2A 只读骨架**：页面框架 + 「未找到作品」态（含编号搜索）+ 标题/日期/上下架提示
      + 封面与内容渲染（`bannedBySystem` / `deletedByMe` / `HIDED` / `BLOCKED` /
      `unlistedByOwner` / 中国区待审核等**全部禁用态遮罩** + 内容 story 渲染 + 加密封面）
      + 作者头像 + 右栏周边（作者、IPFS、NFT、TVIEW/THOLD/TWORK/TOWN 只读行）
      + `get_single_creation`（`creationShowProvider` 对应 `wo.ss.Creation.ctnShow`）
      + 组件 `part_pexdata_summary`；新工具 `tool/check_creation_show.dart`
      （2A 不渲染任何会死的交互入口：解密按钮留待 2C，评论编辑器/操作按钮留待 2B/2E/2F）
    - [x] **2B 评论闭环**：操作按钮行（评论入口）、`partStoryEditor` 评论编辑器、
      `comment_creation` 发表、评论列表（`get_comment_list` 刷新 / 追加更早）、
      删除自己的评论；新增 `core/util/online_guard.dart`（对应 `wo.tt.check_online`）
    - [-] **点赞（不做，产品决策）**：源项目 `showCreation.vue` 的点赞按钮整块被注释；
      老板 2026-09-30 确认：**Babelyx 强调「有价值的内容」，点赞被付费的 fuel/加油 取代，故意移除**，
      不需要恢复。→ 点赞按钮、点赞者名单入口均不迁移（`get_liker_list` 接口已封装备用）
    - [x] **2C 解锁与付费**：`pay_to_view` / `pay_to_hold` / `pay_to_own` / `pay_to_fuel`
      + 解密按钮（加密封面）+ pact 价格点击 + 赞赏按钮（金额可改）
      + `widgets/part_pay_sheet.dart`（**付费确认**弹窗：标题/金额/说明/反馈/余额不足提示）
      —— 完整 `partDeposit`（充值渠道/钱包）属资金域 3C，本轮不建
      + 自检 `tool/check_creation_pay.dart`（注册用户 → 余额 100 → 付 68 → 内容解锁）
    - [x] **2D 用户名单**：`part_user_list`（头像/昵称/时间/选集与圈子统计）+ `part_close_button`
      + `part_user_list_sheet`（可复用名单弹窗：关闭按钮 + 标题 + 列表 + 加载更多）
      + 接口 `get_{viewer,holder,fueler,liker}_list`；入口：pact 人数计数（仅作品相关人可点）、
      赞赏按钮（自己的作品 → 赞赏者名单）
      ——「点赞者名单」入口随点赞按钮一并搁置（源项目点赞按钮被注释）
    - [x] **2E 上下架 / 隐藏 / 删除**：`list_creation` / `unlist_creation` /
      `hide_creation` / `unhide_creation` / `delete_creation_from_{hide,remove}`
      + 操作行按钮（自己的作品：上架·下架 + 删除；他人作品：隐藏·显示 + 删除）
      + `creation_provider` 增列表同步（`updateItem` / `removeItem`）
      - [⏸] **修改作品**：源项目 `to_modify_my_creation` → `showCreationUpdate` → **`partCreate`(1012 行)**，
        而 `partCreate` 属**批次 3**（UGC 创作核心）；故「修改」按钮与 `showCreationUpdate` 一并留待批次 3
    - [x] **2F 分享与举报**：`part_pop_link`（logo+称谓+标题+二维码+链接+复制）、
      `part_complain`（理由输入 + `User/report_complain`）、`part_icontext_copy`（含 pop 两按钮）；
      IPFS/NFT 行加复制与分享、操作行加分享与举报；`userResourceDetail` 的复制也改用该组件
      —— 系统分享（`uni.shareWithSystem`，源项目仅 App 端）留待阶段四
    - [x] **2G 资源页**：`userResource` / `userResourceDetail`
      （分组/子项切换、安卓应用市场选择、版本比对、二维码 qr_flutter、链接复制；
      分享图标 partIcontextCopyshare 待 2F）
    - 建议顺序：2A → 2G → 2B → 2D → 2F → 2C → 2E（先只读闭环，再交互，最后付费/编辑）
  - [x] 批次3 **创作与编辑（UGC 核心）**：`partCreate` + `midBabely`（新建）+ `showCreationUpdate`（修改）
    + `create_creation`（同接口兼作更新）+ `part_linkhelp`
    - **重要侦察结论**：源项目支持三种加密封印（AGENT/JOINT/CREATOR）与「顺便铸造 NFT」开关，
      但 `sealChoice` / `mintChoice` 在**客户端与服务端都为 false**
      （`envar-config.js` 里 `inUniapp ? false : undefined`，后端 `create_creation` 也校验 `wo.envar.sealChoice`），
      即**自封模式与铸造开关在当前产品中根本不可达** → 本轮只实现 **AGENT** 路径，
      不引入 `tic-crypto`；将来若启用自封，需先补 Dart 版加密（阶段四）。
    - 成功流程含 `creationReward`（后端固定 100）弹窗「领取奖励」→ 跳作品详情
    - 余额不足 → 复用 2C 的付费确认弹窗（源项目 `popDeposit`）
    - 顺带修正：**品牌标签栏此前误用 Agidin 列表** → 改为按品牌（`BrandConfig.tabItems`），
      Babelyx 顶栏现为 探索/遇见/AIGC，中间按钮图标与文案（火苗 / 创造）也对齐源项目
  - [ ] 批次4 付费与持有：`pay_to_{view,own,hold}` + 充值弹窗 `partDeposit`
  - [ ] 批次5 NFT 铸造：合约交互（**需先评审 Flutter web3/加密方案**，风险最高）
  - [ ] 批次6 创作者与社交：`showCreator` / `menuCreator` / `menuMarket` / `partCreator*`
- [ ] 3C 资金域：`umyFund` / `umyFundChannel` / `umyFundChannelCreate` / `umyFundChannelWithdraw` / `umyFundTranx`；组件 `partDeposit`(1066行) / `partFundChannelCard` / `partTxList` / `partPexdataSummary`
- [>] 3D 账户/社交域
  - [x] **`menuUzone`（我的空间）**：顶栏（头像上传 / 昵称 / 自我介绍 / 分享 / 余额·消息·选集·圈子徽标 / 语言）
    + 8 行清单（账号 / 实名 / 资金 / 消息 / 选集 / 圈子 / 设置 / 客服）+ 退出·资源·重启
    + 未登录分支（注册引导，对应 `partWindowLayoutUser`）
    - **老板决定（2026-09-30）**：清单里指向**尚未迁移页面**的行**全部渲染、跳现有占位页**
      （复用 `app_router` 的兜底路由，占位页显示「XX 尚未迁移」），迁移后自动生效、零回改
  - [x] **`umyConfig`（我的设置）**：界面语言 / 银行货币 / 加密货币，换币走
    `core/state/coin_provider.dart`（`partCoinTable` 可排序选择弹窗）
    - **有意改进（老板 2026-09-30 确认）**：源项目换币只改内存（`todo: 通知后台修改`），刷新即丢；
      迁移版**写本地存储**（`bankcoinCode` / `cryptocoinCode`）
    - 新增 `core/i18n/coins.dart`（由 `tool/genCoins.js` 从 `wo-core-i18n` 生成：法定货币 180 种 + 加密币 9 种）
  - [x] **`umyContact`（联系客服）**：邮箱 + 留言 → `System/contact_csr`（后端发信），
    另列团队电话/邮箱/地址；新增 `core/api/system_api.dart`
    - 顺带把 `menuUzone` 设置行补回源项目的三段式「语言 | 法币 | 加密币」
  - [x] **账号安全闭环（5 页）**：`umyAccount`（5 行清单）· `umyAccountPassword`（改密码）·
    `umyAccountCommid`（验证当前账号）· `umyAccountCommidNew`（设置新账号：地区 + 新手机/邮箱）·
    `umyAccountTerminate`（销毁账号）
    - **复用**：把 `part_passcode_verify`（验证码发送 + 校验块）**泛化**为可传入
      `commid`/`usid`/`header`/`onVerified`/`onPasscodeSent`/`sendDisabled`——
      ident 两页行为不变，账户域两页直接复用，避免第二份验证码逻辑
    - 新增 `core/state/session_reset.dart`：把「重置会话缓存」（源项目 vuex `reset_all`）
      收成一处，`menuUzone` 重启与 `umyAccountTerminate` 注销共用
    - **源项目缺口**：`wo.ss.tTerminate`（注销页说明文案）在 `envar-config.js` 里恒为 `undefined`，
      从未被定义 → 迁移版照此留空（后台一填就会显示）
    - 顺带：`showPexModal` 的弹窗底色由 M3 品牌染色改为**白色**（源项目为白）
  - [x] **`umyCircle`（我的圈子）+ `umyInvite`（邀请朋友）+ `umyInviteList`（邀请名单）**
    - 三个源组件 `partCreatorMyFollowings/Followers/Invitees` 逻辑几乎一致 →
      合并为一个 `part_circle_list.dart`（`CircleTag` 区分：接口 / 游标字段 / 空态文案 / 前往按钮）
    - `part_load_more` 补 `loadFresh` 状态（源项目顶部的「刷新」条）
    - **修好的行为**：源项目「加载更多」是**整表替换**（`push` 被注释掉），翻页会丢已加载页；
      迁移版**追加 + 按 usid 去重**；邀请名单接口不支持 `beforeTime` 游标（后端只认
      `order/skip/take`，源项目传的 `beforeTime` 被忽略）→ 改用 `skip` 翻页
    - 圈子页分类条：源项目只在 AKBABELY 渲染（当年字典仅 Babelyx 有值），现有多品牌都有 →
      **一律渲染**；分类按钮 = 数量 + 名称两行（对应源项目 `'\n'` 拼接）
    - 邀请页：标题 `tInviteTitle`（未配置则回退 `slogans`）+ 优惠码/链接/二维码 +
      「已奖励 → umyFundTranx」「已邀请 → umyCircle?tagnow=INVITEE」两个渐变入口
    - `envar` 补 `webUrlRoot` / `tInviteTitle` / `linkCommunity` / `slogans` / `Creator.myCircleDict`
  - [x] **`umyMia`（我的消息）+ `umyMiaDetail`（消息详情 / 回复）**
    - 新增 `core/api/mia_api.dart`（`list_my_mia` / `get_mia_detail` / `send_mia`，
      账户域之外第二个独立 apiWho）+ `core/state/mia_provider.dart`（对应 `wo.ss.Mia`）
    - 列表行 = 头像 + 发件人 + 标题（`miaTitle` 或 `extractStoryTitle` 摘要）+ 日期 + 未读红点；
      详情页 = 头像/昵称/时间 + `PartStoryReader` + 「我的回复」`PartStoryEditor`
      （按 `mia*` 开关限制段落类型）+ 成功弹窗
    - **修好的行为**：源项目「加载更多」同样是整表替换 → 迁移版追加 + 按 `miaUuid` 去重；
      已读后用 `mergeInList` 就地合并，让列表红点即时消失
    - `story_utils` 补 `extractStoryTitle`（对应 `wo.tt.extract_story_title`，text 兼容语言字典）
    - `menuUzone` 的消息徽标行现在指向真页面
  - [x] **`umyKyc`（实名认证）**
    - 表单：姓名 / 国籍（`PartLandTable` 弹层）/ 证件类型（4 种）/ 证件号码 + 证件正反面照片
      （点击上传 → `Fileloader/receiveFile` → `chooseUrl`）；提交 gated：
      姓名+号码+正面照必填，IDCARD 还需背面照
    - `kycStateL1` ∈ SUBMITTED/PASSED 时整表只读（源项目 `isFixed`），
      状态文案取 `kycDict[].long` 并按状态着色（黄/红/绿）
    - `user_api.updateKyc`：成功返回 `_state: 'SUBMITTED'`（非 SUCCESS），
      且**后端会真发一封邮件**给值班邮箱；重复提交返回 `BER_UNEXPECTED`
    - 修自己引入的时序 bug：表单初值必须在 `waitAutologin()` 之后再读用户资料
  - [x] ~~**`midTryapp`（TRYAPP 中页）**~~：**已作废**（2026-10-03 老板决定下线 TRYAPP 品牌，
    代码与页面均已删除）。此前按老板决定只做空白框架页，现随品牌一并移除。
  - [x] **`showCreator`（个人展 / 创作者主页）**：未找到分支（提示 + Creator ID 搜索 + 去「遇见」）
    + 已找到分支（头像·昵称·分享·统计·管理或私信·屏蔽/举报·关注 + 自我介绍展开收起 +
    屏蔽空态 + 作品双列列表）
    - 新增接口：`creator_api.getSingleCreator(usid/haid/unid/skip/takeLimit)`、
      `creation_api.getUserCreations`、`user_api` 的 `followUser/unfollowUser/blockUser/unblockUser`
    - 关注/屏蔽后同步 `hostUser` 与 `onlineUser` 计数，并把屏蔽状态写回圈子名单
      （`creatorProvider.setBlockStateInLists` / `removeFromListAll`）
    - **修好的行为**：源项目作品列表「加载更多」仍是整表替换 → 迁移版追加 + 按 csid 去重
    - `envar` 补 `tBlockTitle/tBlock/tUnblockTitle/tUnblock`（源项目恒为 undefined → 走内置文案）
  - [x] **`menuMarket`（交易市场）**：分类条（`Market.uiClassDict`）+ 右上「我的资金」+ 空态
    - **如实说明**：源项目这一页**本身就是空壳**（只有 `MKALL` 分类，且只渲染「当前没有创作品在售」），
      交易功能从未实装 → 迁移版保持一致的「暂未开放」占位
  - [x] **`showWebview`（内嵌网页）**：url/title 走路由参数（envar 同名字段兜底），
    空地址自动回首页；按**条件导入**分两端实现——原生用 `webview_flutter`，Web 用 `<iframe>`
    - 新增依赖 `webview_flutter` + `web`（Web 端不打包 webview 实现；**原生端首次构建时
      可能需要补 iOS/Android 配置**，届时再处理）
    - 另提供 `openUrlInWebview()`（对应源项目 `wo.tt.open_url_in_webview`）：PC 走外部浏览器
      （源项目是 `window.open`），其余平台进本页内嵌
  - [>] **资金域（本批：资金主页 + 收支明细）**
    - [x] `umyFund`（我的资金）：钱包地址行（链接 / 复制 / 分享）+「当前余额」+
      收支分类行（充值 / 奖励恒有；创作品收入·支出仅 Babelyx；AI 收支仅 Agidin，
      由 `BrandConfig.showCreationIncome` / `showAiCosts` 两个品牌开关决定）+
      充值 / 提现按钮（含 `cashoutAlone` 独立成行分支）
    - [x] `umyFundTranx`（收支明细）+ `widgets/part_tx_list.dart`：类型下拉 + 明细行
      （类型名 + 作品链接/金额 + 日期 + 对方昵称头像或支付渠道 + 带符号金额）
    - 新增 `core/state/tx_provider.dart`（对应 `wo.ss.Tx`）、`user_api.getTxList`、
      `envar` 的 `tucLens`/`hide*`/`cashoutAlone`/`showTxGroup`/`myTxDict`/`txTypeDict`
    - **修好的行为**：源项目 `partTxList` 的「加载更多」仍是整表替换 → 迁移版追加 + 按 `txUuid` 去重
    - **如实说明**：充值按钮指向 `partDeposit`（1066 行，尚未迁移）→ 现跳占位页
      「`umyFundDeposit` 尚未迁移」；提现 → `umyFundChannel(Create)` 同理
    - [x] `partDeposit`（充值 / 支付面板，1066 行）：PAY 模式（余额支付，余额不足自动切充值）
      + DEPOSIT 模式（金额步进 / 币种选择 / CNY 渠道+二维码+链接 / USDT 链+地址+二维码 /
      刷新余额 / 客服入口）；充值按钮已从占位页改为直接打开该面板
      - **新增实时通道**：`core/state/socket_provider.dart`（连 servUrl、断线重连、心跳、
        按 skevent 派发；PC 页脚呼吸灯改用真正的 `socketAlive`），
        充值面板监听 `RECHARGE_SUCCESS` 自动弹「已入账」并刷新余额
      - **有意不做（平台差异，已注释）**：iOS 内购 IAP（uni-app 原生插件）、
        uniCloud `unipay-co` 云函数（改用源项目自带的支付门户链接）、
        「连接钱包」按钮（需 MetaMask 探测）
      - 支付门户按 `kReleaseMode` 切 dev/prod（对应源项目 `NODE_ENV`）
    - [x] **提现页面组**：`umyFundChannel`（渠道列表 + 新建入口）·
      `umyFundChannelCreate`（**配置驱动**的建渠道表单：按 `paytoCoinSet` 的字段渲染 + 格式校验）·
      `umyFundChannelWithdraw`（渠道卡片 + 金额/下限/余额 + 换算预览 + 实名闸门 + 提交）·
      `partFundChannelCard`（渠道卡片 + 删除确认）
      - **修源项目 bug（老板指示两边一起修）**：提现页实名闸门写的是 `kycStatusL1`，
        而用户对象上是 **`kycStateL1`** —— 字段不存在导致恒为 `undefined !== 'PASSED'`，
        **任何人都被挡住、提现永远提交不出去**；源项目 commit `bbbfed64`，迁移版直接用正确字段
      - 新增 `core/i18n/payto_coins.dart`（对应 `paytoCoinSet`）、
        `user_api` 的 `addPaytoChannel` / `deletePaytoChannel` / `requestWithdrawal`、
        `envar.withdrawAmountMin`；`umyFund` 的「提现」按钮已接到真页
  - **资金域至此全部迁完**
  - [x] **零散组件结案**（2026-10-03）：12 个组件逐个查源项目实际引用后定论 ——
    10 个是**死代码**（全库无引用 / 只被注释掉 / `partDev` 是 `v-if="false"` 占位 /
    `partSoundRecorder` 的开关 `*Speak` 全为 false），标 `[-]` 不迁移；
    唯一真缺口 **`partMenuRing`（AI 聊天消息操作菜单）已补齐**（径向环形菜单 → 底部操作表）
  - [x] **`wo` 全局对象等价落地**：`ss`→各 Provider、`ll`→`LangText/ll()`、`tt`→`core/util/*`、
    `bok`→`api_client.dart`、`unisocket`→`socket_provider.dart`、`pageSet`→`page_meta.dart`；
    `App.data.js` 的 store 各域、主题 scss、`myp-one`/`uni_modules`/`uc*` 全部有等价物
  - 待办只剩一项，且属于**原生构建阶段**：`buildPages/manifest/appPackConfig/androidPrivacy.js`
    （iOS/Android 打包、隐私清单、flavors + CI）
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

**阶段目标**：多品牌 × 五平台的构建发布流水线；与 uniapp 全量回归对比；上线。

**验收标准**：一键构建各端产物；发布流程可重复。

- [ ] GitHub Actions（参考 `einz/.github`）：Web / iOS / Android / macOS / Windows
- [ ] 多品牌 flavors 产物：包名 / 图标 / 启动图 / 版本号（对齐 `YYMMDDHH` 版本码约定）
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
