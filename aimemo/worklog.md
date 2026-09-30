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

### homePortal 视觉校验与修正（同日，回应老板「推进2」）

- **落实老板指示**：连接状态保留到正式版（去掉"开发用可移除"措辞）；把首个验证页跑起来给老板看。
- **预览链路**：`flutter build web --dart-define=API_BASE=http://localhost:7739` + `python3 -m http.server 8090`，并在默认浏览器打开 `http://localhost:8090/`。
- **后端 CORS 已开放**（`Access-Control-Allow-Origin: *`），Web 可直连本地后端。
- **修正项**（对照 `localhost:8080` 源站）：
  1. 推荐卡片由「2 个/行、无图」改为源站版式「一行 3 个（`flex: 0 0 calc(33.3%)`）+ 左侧封面图 + 右侧红色徽标 + 标题 + 描述」，并用 `AspectRatio(1)` 方形卡；
  2. 新增 `partShortcuts`（源 `parts/partShortcuts.vue`）：由 `envar.linkTree` 渲染 ios/android/webapp/info 图标 + 固定的 umyContact 耳机图标 + more；
  3. 底栏状态文字改为独立右对齐一行，消除横向溢出；
  4. **整目录迁移 `static/` → `assets/static/`（2.4M）**，并生成 **icont + uniicons 图标字体**（109 + 166 个码点）到 `lib/core/icons/`，配套 `PexIcon`/`PexGlyph` 组件与 `pex_assets.dart`（`/static/*` → `assets/static/*`）。
- **踩坑记录**（已写入 architecture.md）：
  - shell `&` 后台进程会被回收 → 用受管后台任务；
  - headless Chrome（macOS）窗口宽度最小被钳制为 **500**，且截图高度比视口高 ~87px（白边假象，纯 `100vh` 页同样如此）→ 手机版式截图用 `--window-size=500,987`。
- **验证**：`flutter analyze` 0 问题；`flutter build web` 成功；PC（1280×800）与手机（500 宽）截图版式与源站一致。
- **待办/遗留**：`start` 按钮圆角需再核对；newsline 点击外链未接；`umyContact`/`userResource` 跳转待页面迁移后接通；`homePortal` 尚未在 iOS/Android 真机验证。

### 账户域迁移（ident*，同日）

- **梳理源流程**（读 `identBegin/NewPasscode/NewRegcode/NewRegister/OldLogin/OldPasscode/OldReset` + 相关组件）：
  `identBegin`(输入手机/邮箱 → `User/identify_user`) → OLD_USER→`identOldLogin` / NEW_USER→`identNewPasscode`
  →`send_passcode`+`verify_passcode`→`identNewRegcode`(`verify_regcode`)→`identNewRegister`(`register_new_user`)；
  老用户重设：`identOldLogin`→`identOldPasscode`(RESETPWD)→`identOldReset`(`reset_password`)。
- **关键兼容点：`hash_stable`**。源实现为 `crypto.createHash('sha256').update(data,'utf8').digest('hex')`；
  Flutter 侧用 `crypto` 包等价实现。**已与后端实测比对一致**（`passwordClient` 与 `passcodeHash` 逐位相同），
  否则存量用户无法登录。
- **关键发现：`callBase` 自动持久化凭据**。源项目 `wo-core-toolkit` 的 callBase 会把响应里的
  `_passtoken` / `uni_id_token` / `clid` 自动写入本地存储（各页面里的 `setStorageSync('_passtoken')` 因此全部注释掉）。
  已在 `ApiClient` 复刻（`onPasstoken` 回调 → `LocalStore`），否则自动登录失效。
- **生成式数据**（脚本生成，避免手工出错）：
  - `lib/core/i18n/lands.dart`：249 个国家/地区（含 5 个 `phoneRegex`），源自 `wo-core-i18n/i18n-lands.js`
  - `lib/core/appmeta/page_meta.dart`：35 个页面元数据（i18nPageTitle/gotoIcon/navigationStyle），源自 `pages.json`
  - `lib/core/icons/icont_icons.dart`：icont 109 + uniicons 166 个图标码点
- **基础设施**：`core/util/pex_toolkit.dart`（hashStable/validateEmail/validatePhone/numberPrecision）、
  `core/state/{ident,region,envar}_provider.dart`、`core/util/feedback.dart`（toast/modal）、
  `core/appmeta/app_env.dart`（`kInProd`，替代 `kReleaseMode` 做生产守卫，使本地预览与源项目 dev 行为一致）。
- **组件**（11 个）：`part_window_layout_ident` / `part_window_header` / `part_window_footer` /
  `part_navibar_pc` / `part_navibar_pc_fixed` / `part_show_loading` / `part_breathing_opacity` /
  `part_button_passcode` / `part_countdown` / `part_ident_commid` / `part_land_table`，
  以及复用的 `part_passcode_verify`（验证码发送+校验，供新老两个 passcode 页共用）、
  `part_password_form`（两次密码+协议，供注册/重设共用）、`part_passcode_input`（6 位盒子输入，替代第三方 `myp-one`）。
- **页面**（7 个）：`ident_begin` / `ident_new_passcode` / `ident_new_regcode` / `ident_new_register` /
  `ident_old_login` / `ident_old_passcode` / `ident_old_reset`；路由表改为显式声明 + 未迁移页兜底占位。
- **端到端自检**：新增 `tool/check_ident_flow.dart`，对本地后端跑通
  `identify_user(NEW_USER)` → `send_passcode(PASSCODE_SENT)` → **hash 一致** → `verify_passcode(VERIFY_SUCCESS)`
  → `register_new_user(REGISTER_SUCCESS)` → `identify_user(OLD_USER)` → `login_user(LOGIN_SUCCESS)`。
- **视觉对照修正**：Submit 按钮改为整行；顶栏标签按源项目 `slice(0, N-1)` 只显示第一个；
  补 PC 二级标题（各页 `i18nPageTitle`）；页脚分组纵向堆叠；logo 增加兜底图标。
- **验证**：`flutter analyze` 0 问题；`flutter build web` 成功；与 `localhost:8080` 逐页截图比对。
- **待办**：`midAgidin`（登录后落地页）仍是占位，属 AI 域；WebSocket 未接；iOS/Android 真机待验证。

### AI 域迁移（第一轮，同日）

- **传输机制澄清**：AI 回复**不是** WebSocket 流式，而是 HTTP 长请求
  `Aimodel/reply_challenge`（源项目前端同步等待 + 「思考中…N」倒计时）；
  WebSocket 的 `AICHAT_SUCCESS` 只是补充推送路径。→ 实现大幅简化。
- **老板提示并确认的核心架构**：`story`（`[{text|image|video|audio|link|file}]`）是**跨域内容容器**，
  贯穿 AI 对话、创作/NFT、列表详情；`partStoryReader` 渲染、`partStoryEditor` 组编。
  已写入 `architecture.md` 第七节。
- **接口实测**（`tool/check_ai_flow.dart`，注册账号后全链路）：
  `get_aipp` SUCCESS（爱奇点/Agidin）· `get_all_aippList` SUCCESS（10 个共享 Aibot）·
  `get_my_aippList` SUCCESS · `get_chat_history` SUCCESS ·
  `reply_challenge` 返回 `_state=ERROR / Bad request for dependent service.`（含 `promptUuid`）。
  → **前端契约正确**；失败原因是**本地后端的上游模型连接已过时**。
- **老板指示**：后台连 AI 模型很久没更新，**先完成前端迁移、再更新后台**；目前很多模型连接是错的，
  不必为此阻塞前端。
- **新增基础设施**：
  - `core/util/server_url.dart`（`make_server_url` 等价 + `ServerImage`）
  - `data/ai_model.dart`（`AiModel` 视图：ainame/ainote/aiprice/aiprovider/aiavatar/isTextChat/isImageChat/isAibot/pickState）
  - `core/state/ai_provider.dart`（chatList/promptStory/aicodeNow/aintNow/memory/imgNum/autoTTS/aippTag/…）
  - `core/api/aimodel_api.dart`（9 个 apiTodo；注意参数名为 **`takeLimit`**）
  - `pex_toolkit` 增补 `formatDate` / `segmentNumber`
- **新增组件**：`part_window_layout`、`part_load_more`、`part_text_reader`、
  `part_story_reader`、**`part_story_editor`**、`ai_model_tile`、
  `part_aipp_models` / `part_aipp_shared` / `part_aipp_picked`、`part_aichat`（核心）。
- **`part_aichat` 覆盖**：模型头部（名称/价格/供应商 + 清空/加载更多/收藏）、消息列表（story 渲染、
  左右分栏、头像、tuc 成本）、输入条（多行 + 发送）、**story 模式**（图片对话模型或 Aibot 时切换为
  `partStoryEditor`，发布即发送 `promptStory`）、记忆条数/图片数设置、余额显示、消息长按菜单（拷贝/删除）。
  **暂缓**：语音输入（`partSoundRecorder`）、TTS 自动朗读、分享弹窗、充值弹窗、story 段落媒体上传。
- **新增页面**：`mid_agidin_page`（AI 对话落地页，含手机端自绘顶栏）、`menu_aipp_page`（Aibot 市场，
  限宽 900、分类切换、创建入口）、`menu_aipp_aichat_page`；路由已接入。
- **视觉对照修正**：`menuAipp` 内容限宽 900 居中；列表说明文字限 1 行（对齐 `uni-list-chat`）。
- **验证**：`flutter analyze` 0 问题；`flutter build web` 成功。
- **待办**：`menuAippCreate`/`menuAippModify` + `partAippEditor`；`partMenuRing`/`partPopLink`/`partDeposit`；
  语音/TTS；story 段落媒体上传（`pickupFile2Server` 等价）。

### story 媒体上传（AI 域第二轮，同日）

- **老板决定（战略）**：**Aibot 创建/编辑不做** —— Aibot 是两年前的设想，已被 **agent 概念全面超越**，
  **Agidin 需要重新构思新方向**。故 `menuAippCreate/Modify(+wrapper)`、`partAippEditor` 标记为 `[-]` 不迁移
  （Aibot 市场的浏览/选择仍保留）。
- **上传契约**（读 `wo.tt.pickupFile2Server` 得到）：
  `POST {servUrl}/api/Fileloader/receiveFile`，multipart，文件字段名 `file`，
  另附 `_passtoken` 与 `filenameOriginal`（源项目为解决 multer 拿到随机文件名而主动回传）；
  响应 `{_state:'SUCCESS', path, destination, filename, size, cid, ipfsUrl, baseUrl, ...}`。
  客户端侧校验顺序：空文件 → 超出 `envar.fileSizeLimit`（100MB）→ 后缀类型检查。
- **story 段写入规则**（源 `partStoryEditor.pushContent`）：
  - image → `{ image: choose_url(info, prefer:'url') }`
  - video/audio → `{ video|audio: choose_url(...), _originalname, _size }`
  - file → `{ file: { usage, ...simplify_file(info) } }`，usage 依 `aiConfig.openaiFileSearchExt`
    → `KNOWBASE` / `openaiCodeInterpreterExt` → `TEMPLIB` / 否则 `UNKNOWN_USAGE`
- **实现**：
  - `core/api/fileloader_api.dart`（Dio multipart 上传 + 客户端校验 + `fileUrl` 计算）
  - `core/util/file_utils.dart`（`getFileExt`/`isImageFile|VideoFile|AudioFile`/`simplifyFile`/`chooseUrl`/`matchesExtensionList`）
  - `core/util/pex_file_picker.dart`（跨端统一返回 bytes；`image_picker` + `file_picker` 13）
  - `part_story_editor` 接入真实上传：选择 → 校验 → 上传 → 按类型写入 story 段，含上传中/失败反馈
- **踩坑**：`file_picker` 13 API 变更（`FilePicker.pickFile` 为静态方法、返回 `PlatformFile?`，
  且用 `readAsBytes()` 而非 `bytes` 字段）；Dart 侧统一取 bytes 以便 Web 与原生共用一套上传逻辑。
- **实测**：`curl` 直打上传接口 → `_state: SUCCESS`，返回 `path`/`cid`/`baseUrl`/`ipfsUrl` 全部正确。
- **验证**：`flutter analyze` 0 问题；`flutter build web` 成功。
- **顺带修正**：`part_aichat` 的欢迎语在模型详情未返回时误显示 `Loading...`，改为加载态组件。

### 备注：Aibot 相关（不投入）
- 老板 2026-09-29：Aibot 概念已被 agent 取代，Agidin 待重新构思方向；
  **除非另行指示，不再迁移 Aibot 的创建/编辑链路**。

### 品牌切换机制（入口级裁剪，同日）

- **老板提问**：切到 NFT（Babelyx）项目，是分成两个项目，还是一个项目里用 switchApp 式脚本切换构建？
- **结论与落地**：**一个仓库 + 每品牌一个入口 + 构建期指定**，不做破坏性文件改写。
  - `main_agidin.dart`（公共+AI）/ `main_babelyx.dart`（公共+创作NFT）/ `main_tryapp.dart`（公共+最小 AI）；
    `main.dart` 默认 = Agidin。
  - **路由分文件**：`route_common.dart` / `route_ai.dart` / `route_creation.dart`；
    `createAppRouter(routes: ...)` 组装 + 兜底占位。
  - **BrandFeatures** 功能开关（enableAiChat/enableAibotMarket/enableCreation/enableCreator/enableMarket/enableNft/enableResource）；
    `showCreatorShortcuts` 改为由 features 推导，业务代码不再判断 appkey。
  - 新增 `brands/brand_features.dart`（含 agidin/babelyx/tryapp 三套预设）。
  - `package.json` 脚本按品牌入口更新（`build:web:agidin|babelyx|tryapp`、`run:agidin|babelyx|tryapp`）。
- **实测入口级裁剪**：Agidin `main.dart.js` 3,030,380 B vs Babelyx 2,883,228 B，
  差 **147KB**（AI 域代码未进入 Babelyx 产物）✅
- **实测品牌渲染**：Babelyx 产物在浏览器正确显示红色主题、Babelyx logo、
  后端下发 `100 BAB` 与 `Sell Your Content` slogan、橙色 Start 按钮 —— 同代码、换品牌即变。
- **验证**：`flutter analyze` 0 问题；两品牌 Web 构建均成功。

### 配置来源方案 E（预置层 + 后端覆盖层，同日）

- **老板两轮澄清**：
  1. 连不上后端时 App 停在首屏 Connecting 读秒 → 本地副本**不是**为离线兜底；
     真正目的是「大多数设置/文案可由后台随时下发」，故**前端一份 + 后台持有**；
     源项目用 `inUniapp`/`base2app` 控制预置/仅后台/可下发三种角色（翻开关即可让纯客户端配置也可下发，但该需求不重要）。
  2. 因此我**撤回方案 A**（让后端下发客户端专属块），D+ 的**缓存层也降级不做**。
- **采用方案 E**：① 本地预置层（只含服务端不发的块 + 首屏稳定标量）→ ② 后端 `first_touch.envarBase` 覆盖。
- **落地**：
  - `tool/genClientEnvar.js`：模拟客户端上下文求值 `envar-config.js`，与后端实际下发的 `envarBase` 做**差集**，
    得到 **79 个客户端专属键**；按品牌合并 `AK*` 块并删除品牌键 → `assets/clientEnvar.json`（48.9 KB / gzip 5.8 KB）
  - `core/state/client_envar.dart`：启动时加载预置（`runPexApp`），`clientEnvarPresetProvider` 注入
  - `core/state/envar_provider.dart`：合并 `{...预置, ...后端}`（后端覆盖预置）
- **验证**：三品牌 `tucSymbol='¢'`、`pactDict`(TCREATE/TFUEL/TVIEW/THOLD)、`Creation.uiStatDict` 均就位；
  预置资源 50,056 B 已进产物；`flutter analyze` 0 问题；Agidin Web 构建成功。
- **注意**：后端 7739 在本轮期间已停止（只剩 HBuilderX 8080 与静态服务 8090），
  为此生成器增加了「后端未启动时回退缓存基准」的能力。

### 创作/NFT 域 批次 1（列表与分类，只读）

- **范围**：`menuCreation`（探索创作品）+ `umyCollection`（我的收藏·5 身份）+ 卡片/空态/加载组件。
- **一处设计偏离**（按老板"不必照抄 uniapp"原则）：
  源项目 `partCreationAs{Creator,Owner,Holder,Viewer,Fueler}.vue` 是 5 个近乎相同的组件（各 107 行），
  **合并为一个参数化组件** `part_creation_as_list.dart`（入参 `CreationRole`），行为等价、代码量降约 80%。
- **新增**：
  - `core/api/creation_api.dart`（`get_creation_list` / `get_creations_as_<role>` / `get_single_creation`，含 `CreationRole` 枚举）
  - `core/state/creation_provider.dart`（`listAll` + 各身份集合 + `onceLoaded`）
  - `data/creation.dart`（`Creation` 视图：封面 3 态、禁用原因、我与作品的关系、标题兜底、seal 文案）
  - `core/util/story_utils.dart`（`filterStoryImage/Video`、`isAutocontent`、`readVarchain`）
  - 组件：`part_empty_list` / `part_creation_card_list`（封面 3 态 + 标题栏 + 统计条 + 禁用遮罩）/
    `part_creation_all` / `part_creation_as_list`
  - 页面：`menu_creation_page` / `umy_collection_page`；`route_creation.dart` 已接入
- **接口契约核对**（匿名打 `Creation/get_creation_list`）：`_state=SUCCESS`，返回 3 条；
  卡片用到的 20 个字段中 **19 个存在**（仅可选 `myCommentCount` 缺 → 按"未评论"处理）；
  `pexdataUser[0]` 为 `{textIpfs: ...}` → 走文本封面分支。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。
- **遗留**：headless 截图在本页卡住（应用持续重连导致 Chrome 虚拟时间不收敛），
  本轮以**接口契约核对**替代视觉验收；下轮改用其它方式补视觉对照。

### 创作/NFT 域 批次 2 侦察与拆解（本轮止于此）

- **侦察 `showCreation.vue`（2227 行，全项目最大页）**：
  - 模板重度依赖弹窗与列表：`uni-popup` ×13、`uni-list-item` ×10、`partLoadMore` ×6
  - 未迁移的依赖组件：`partDeposit`(1066，属资金域) · `partUserList` · `partPopLink`(分享) ·
    `partComplain`(举报) · `partIcontextPop`/`partIcontextCopy`(复制菜单) · `partCloseButton` ·
    `partPexdataSummary` · `partStoryEditor`(已有基础版可复用)
  - 主体包含**大量禁用态分支**：`bannedBySystem` / `deletedByMe` / `HIDED` / `BLOCKED` /
    `unlistedByOwner`(对本人/他人/被链接者三种视角不同) / 中国区待审核
- **结论**：该页不可一次吞下，已拆为 **7 片**（2A 骨架 → 2B 互动 → 2C 付费 → 2D 用户列表 →
  2E 编辑下架 → 2F 分享举报 → 2G 资源页），建议顺序 **2A → 2G → 2B → 2D → 2F → 2C → 2E**。
- **本轮未写实现代码**：上下文预算耗尽，为免留半成品而主动止步，拆解方案已落盘供下次直接开工。

### 创作/NFT 域 批次 2 · 2A 只读骨架（showCreation 首片）

- **范围**：`showCreation.vue`（2227 行，全项目最大页）的第一片——**只读骨架**：
  页面框架（PC 二级导航 + 加载态）→「未找到作品」态（含编号搜索，对应 `search_unid`）→
  标题/日期/上下架提示 → 封面（**全部禁用态遮罩** + 内容 story 渲染 + 加密封面）→
  作者头像 → 右栏周边（作者、IPFS、NFT、pact 只读行）→ `get_single_creation`。
- **新增**：
  - `pages/show_creation_page.dart`（页面本体，按 `ShowCoverKind` 枚举集中呈现源项目
    模板里的一串 `v-if/v-else-if` 遮罩优先级）
  - `core/state/creation_show_provider.dart`（对应 `wo.ss.Creation.ctnShow`，含 `readyShow` 语义）
  - `widgets/part_pexdata_summary.dart`（对应 `partPexdataSummary.vue`）
  - `data/creation.dart` 扩展：`Pact` 视图、`ShowCoverKind` 判定、`bannedBySystem` /
    `unlistedByOwner` / `unlistedByMe` / `deletedByMe` / `linkedByMe` / `belongToMe` / `stockNumber`
  - `core/api/creation_api.dart`：`getSingleCreation` 支持多入口参数（csid/链接参数，对应 `onLoad` 两分支）
  - `theme/app_theme.dart` 补色：`grey8/greyE/subtext/blueMy/blueMatt/greenLight`
  - 工具 `tool/check_creation_show.dart`（契约自检：18 个关键字段全部 OK）
- **有意偏离**（均已在代码注释与本项目标注）：
  1. **不渲染任何「会死」的交互入口**：解密按钮（2C）、评论编辑器与操作按钮行（2B/2E/2F）、
     复制/分享小图标（2F）、mint 入口（批次5）本轮全部不出现，只保留只读信息；
  2. 源项目把封条文字渲染了两遍（疑似视觉密度 hack），Flutter 侧只渲染一遍；
  3. `dateAt` 源项目恒为 `SUBTITLE`，只实现该分支；
  4. 搜索按钮与输入框并排（源项目绝对定位叠在输入框内）。
- **实测**（headless Chrome 截图，本轮解决了上轮截图卡住的问题——
  **Chrome 窗口宽度有 500px 下限**，此前 420/300 宽的截图其实是 500 宽布局被裁切，并非布局溢出）：
  - 手机 500 宽：内容作品 / 加密作品 / 未找到 三态均正确；
  - PC 1200 宽：左右栏 60/40（实测右栏 724–1190px，与 flex 6:4 精确吻合）；
  - 修掉一处真 bug：加密封面兜底背景误用纯绿色导致封条文字不可见，已改回 `matrix7.jpg`。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功；`dart run tool/check_creation_show.dart` PASS。
- **下一片**：按既定顺序 **2G 资源页 → 2B 统计与互动**（评论列表 + 点赞）。

### 创作/NFT 域 批次 2 · 2G 资源页（userResource / userResourceDetail）

- **新增**：
  - `pages/user_resource_page.dart`：按 `linkTree` 分组渲染图标入口
    （`hiddenGroup` 隐藏整组；apps 组按平台过滤；recos 组排除本品牌，均与源项目一致）；
    底部 Customer Service 入口 + 手机端语言选择器。
  - `pages/user_resource_detail_page.dart`：两层切换条（分组 / 子项）+
    安卓应用市场下拉（RAWAPK + `appMarket`）+ `infoTitle` 说明 +
    「官方版本 / 本机版本 / 更新建议」（本机版本仅原生 App 内显示，与 `#ifdef APP` 对齐）+
    **二维码** + 可点击/可复制的链接。
  - `core/state/envar_provider.dart` 增 `linkGroup` / `isLinkGroupHidden`。
  - **新增依赖 `qr_flutter ^4.1.0`**（老板确认采用）；复制用 Flutter 内置 `Clipboard`（零依赖）。
- **实测**：headless 截图手机 500 宽——列表页三组图标与过滤正确（recos 隐藏）；
  安卓详情页：分组/子项选中态、市场下拉、官方版本号 26082314、二维码、
  链接 `https://apk.babelyx.com`（注意：后端按 `_clientInfo.webDomain` 动态拼链接，
  之前的 curl 样例没传 webDomain 才显示 `undefined`，App 内正常）。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。

### 创作/NFT 域 批次 2 · 2B 评论闭环（showCreation 互动区）

- **范围**（比计划更完整，避免做出「只能看不能写」的半截页面）：
  操作按钮行（评论入口，点击聚焦编辑器）→ `partStoryEditor` 评论编辑器
  （允许类型取自后台 `commentText/Image/Video/Speak/File/Link`、`commentMaxSections`）
  → `comment_creation` 发表 → 评论列表（`get_comment_list` 刷新 / 追加更早）
  → 删除自己的评论（`delete_comment`，带确认弹窗）。
- **新增**：
  - `core/util/online_guard.dart`：对应 `wo.tt.check_online()`，未登录弹「请先登录」并跳 `identBegin`
    （源项目还会记 `routeAfterLogin` 以便登录后回原页，尚未迁移）。
  - `creation_api.dart`：`get_comment_list` / `comment_creation` / `delete_comment`。
  - `creation_show_provider.dart`：`copyWith` + `setComments` / `appendComments` /
    `prependComment` / `removeCommentAt`。
  - `part_story_editor.dart` 增 `textFocusNode`（对应源项目 `isFocused`）。
  - `tool/check_creation_comments.dart`：注册临时用户 → 发表 → 列表 → 删除 → 复查。
- **有意偏离**：加载更早评论时，源项目是**整表替换**（`this.commentList = commentList`），
  会丢掉已加载的较新评论；Flutter 侧改为**按 commentUuid 去重后追加**。
- **⚠️ 发现后端缺陷 B4（已记 `backendTodo.md`）**：`delete_comment` 返回
  `ERROR_FAILED_DELETE_COMMENT`，但**三条写操作全部已提交**（已在 `pex.sqlite.db` 核实
  commentState=DELETED / countComment-1 / countComment2Del+1）。
  前端保持契约严格判定**不改**（会提示删除失败，刷新后其实已删），待后端修。
- **未做**：点赞 —— 源项目 `showCreation.vue` 的点赞按钮**整块被注释**（1851–1859 行），
  `to_toggle_vote` 已无入口，等老板确认是否恢复。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功；
  `dart run tool/check_creation_comments.dart` 发表/列表/删除三步契约正确；
  headless 截图确认编辑器、发表按钮、刷新按钮、评论入口渲染正常。

### 后端 B4 修复（老板授权「随手修掉后台小错误」）

- **诊断手法**：先把 `catch` 里的异常 `expt.message` 临时塞进响应 `_msg`（后端由 nodemon 托管，
  存盘即自动重启），跑一次 `tool/check_creation_comments.dart` 就拿到了真实异常，
  随后移除诊断代码。**比猜 TypeORM 内部行为高效得多**，以后后端问题可沿用。
- **根因**：事务体内 6 处 `wo.Mia.api.send_mia()` **没有 await** → 并发写同一条 SQLite 连接
  → 打乱 SAVEPOINT 深度 → 下一个事务 commit 时报 `no such savepoint: typeorm_N`。
- **修复**：6 处改为 `await ....catch(ccerror)`（Creation.js 5 处 + User.js 1 处）。
- **验证**：修复前连跑 3 次（1 成 2 败），修复后 **4/4 PASS**。
- 提交：`pex-server-torm` `f51c129`；`backendTodo.md` B4 移入「已修」。

### 创作/NFT 域 批次 2 · 2C 解锁与付费

- **范围**：`pay_to_view` / `pay_to_hold` / `pay_to_own` / `pay_to_fuel` 四个付费动作，
  以及三个入口：加密封面上的**解密按钮**、pact 行上的**可点击价格**、操作行的**赞赏按钮**（金额可改）。
- **新增**：
  - `widgets/part_pay_sheet.dart`：付费确认弹窗（标题/金额/说明/失败反馈/余额不足提示 +
    「去充值」跳 `umyFund`）。**只做付费确认**——源项目 `partDeposit`(1066 行) 的
    「选充值渠道/钱包地址/法币渠道」属资金域，留给 3C。
  - `creation_api.dart`：`payToView/payToHold/payToOwn/payToFuel`。
  - `app_routes.dart`：补 `umyFund`（仅作跳转目标，页面未迁移）。
  - `tool/check_creation_pay.dart`：注册临时用户 → 找付费作品 → `pay_to_view` → 复查解锁。
- **成功回写**（对齐源项目）：`pexdataUser`（解锁内容）、`countViewer/Holder`、
  `mytx*_txAmount/_txTimeUnix`、`amountFuel`；`pay_to_own` 额外回写 `ownerUsid`（后端确实转移所有权）。
  余额优先用响应里的 `balanceTUC`，否则本地扣减。
- **实测**：`dart run tool/check_creation_pay.dart` —— 余额 100，解密价 68，支付后返回
  `pexdataUser`，复查 `get_single_creation` 已解锁且 `mytxView_txAmount` 就位 → PASS。
  headless 截图：解密按钮、5¢/10¢ 可点价格、Fuel 按钮、评论闭环同屏正常。
- **说明**：`pay_to_hold/own/fuel` 与 `pay_to_view` 共用同一后端事务族（B4 已修），
  契约一致；本轮以 `pay_to_view` 做端到端验收。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。
- **下一片**：2D 用户名单（`partUserList`：观看者/持有者/赞赏者）+ 恢复点赞入口（待老板确认）。

### 创作/NFT 域 批次 2 · 2D 用户名单

- **新增**：
  - `widgets/part_user_list.dart`：头像 50 + 昵称 + 时间（`timeKey`/`timeIcon`）+ 统计行
    （选集数 `count_creation_public`、圈子数 `countFollower+countFollowing`）；`userType === 'INVITEE'` 时隐藏统计。
  - `widgets/part_close_button.dart`（弹窗右上角关闭）。
  - `widgets/part_user_list_sheet.dart`：**可复用名单弹窗**——源项目里四个 `uni-popup`
    （点赞者/赞赏者/解密者/持有者）结构完全一致，合并为一个组件（省 4 份重复）。
  - 接口：`get_{viewer,holder,fueler,liker}_list`（含 `beforeTime` 游标分页）。
  - `brand_config.dart` 增 `colorCollect` / `colorCircle`（源项目品牌主题 `--ColorCollect`/`--ColorCircle`，
    仅 Babelyx 定义）；`pex_toolkit.dart` 增 `countCreationPublic`。
- **入口**（对齐源项目）：pact 行的人数计数——仅「作品相关人（原创主/权利主）」可点，
  可点时变蓝色（`.locCounterActive`）；赞赏按钮改为「自己的作品看名单 / 他人作品去赞赏」，不再是死按钮。
- **就近声明**：`umyCollection`/`umyCircle` 的 `gotoIconType`（`images`/`staff`）——
  这两页在源 `pages.json` 里受 `!ifA` 约束（非 Agidin），故未进生成式 `page_meta.dart`，
  在 `part_user_list.dart` 里就近声明并注明。
- **实测**：`dart run tool/check_creation_pay.dart`（已扩展）——
  `get_viewer_list`/`get_holder_list`/`get_fueler_list`/`get_liker_list` 四个接口
  均返回预期键（`viewerList`=2 / 其余=0）→ PASS。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功；headless 截图确认布局无回归。
- **搁置**：点赞者名单入口（源项目点赞按钮整块被注释）；点赞相关功能待老板确认是否恢复。

### 老板决策记录：点赞不做（2026-09-30）

老板说明：**点赞是故意消除的**——按 Babelyx 的产品定位，强调「有价值的内容」，
因此把点赞换成 **fuel/加油，必须支付一定费用**。→ 不恢复点赞按钮，
点赞者名单入口也不迁移（`get_liker_list` 接口已封装好，将来若需要可直接用）。
已同步 `projectPlan.md`（该分片标为 `[-]` 并注明产品理由）与长期记忆。

### 创作/NFT 域 批次 2 · 2E 上下架 / 隐藏 / 删除

- **范围**：源项目 `to_toggle_creation_listing` / `to_toggle_hide` /
  `to_delete_creation_from_{hide,remove}`。
- **新增**：
  - `creation_api.dart`：`listCreation` / `unlistCreation` / `hideCreation` / `unhideCreation` /
    `deleteCreationFromHide` / `deleteCreationFromRemove`（参数名逐一对照后端确认）。
  - `creation_provider.dart`：`updateItem(csid, patch)` / `removeItem(csid)`，
    对应源项目在各操作后对 `myCollectionAs*` / `creationListAll` 的同步。
  - 操作行按钮（源项目同款门控）：
    - 自己的作品 → **上架/下架**（按 `unlistedByMe`）+ **删除**（`ctnDeletable && unlistedByMe`）
    - 他人作品 → **隐藏/显示**（按 `hideState`）+ **删除**（`ctnDeletable && hideState==='HIDED'`）
    - 隐藏提示按源项目拼接「已购买可重新显示」；隐藏后把该作品从探索列表移除。
- **⏸ 修改作品未做（阻塞于批次 3）**：源项目「修改」跳 `showCreationUpdate`，
  而该页主体是 **`partCreate`(1012 行)**——那是批次 3「创作与编辑（UGC 核心）」的核心组件。
  故「修改」按钮与 `showCreationUpdate` 页一并留待批次 3，避免做半截编辑页。
- **实测**：`dart run tool/check_creation_pay.dart`（再扩展）——
  `hide_creation`/`unhide_creation` 可逆往返均 SUCCESS；
  `unlist_creation`/`list_creation`/`delete_creation_from_remove` 对非本人作品
  均返回 `ERROR_UNAUTHORIZED_USER`（参数名与鉴权均正确）→ PASS。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。
- **下一片**：2F 分享与举报（`partPopLink` / `partComplain` / `partIcontextCopy` / `partIcontextPop`）。
