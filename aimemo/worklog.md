> [已停用 2026-10-07] 本文件已归档并入 `../../aimemo/`（见 `../../aimemo/README.md` 的来源对照表），请勿再更新。原内容暂时保留，待清理。

# 工作日志（worklog）

> 只追加，每次有变化就记录。

## 2026-10-07（续）

**seafile 忽略分层（global/local）+ seafile_ignore_find2merge 移植 Node 跨平台**

- 老板的设计原则确认：**多项目通用的机器本地产物进 `seafile-ignore.global.txt`（随所有合并生成的 seafile-ignore.txt 下发），个别项目的进 `seafile-ignore.local.txt`**（与 node_modules 在 global 同逻辑）。
- **Flutter/Dart 产物分层落地**（起因：`.dart_tool/package_config.json` 含 `/Users/luk/.pub-cache/...` 绝对路径，跨机同步会让另一台机器编译崩——与今日 `flutter pub get` 修复同一根因）：
  - 进 global（`opx/sysconfig/nixhome/seafile-ignore.global.txt`）：`.dart_tool/`、`.flutter-plugins-dependencies`、`Pods/`、`local.properties`、`.gradle/`、`.kotlin/`——逐条核实过 productX 下无任何仓库把这些名字纳入 git 跟踪，可安全全局忽略。
  - 留 pex 本地（`pex/seafile-ignore.local.txt`）：`build/`——**撞车**：tic/tic-www-vue、cox/cox-user-vue、cox/cox-team-vue 把 `build/` 纳入 git 跟踪（vue 打包产物），全局忽略会波及，只能在需要的项目层级覆盖。
  - 规律：**"锁文件"（pubspec.lock / Podfile.lock）跨机共享，"检出/解析产物"（.dart_tool / Pods / node_modules）各机本地再生**（`flutter pub get` / `pod install` / `npm i` 自动重生成）。pub 缓存在 `~/.pub-cache`，在资料库根之外，seafile 同步不到，无需列出。
- **`seafile_ignore_find2merge` 移植 Node**（`opx/sysconfig/seafile_ignore_find2merge.js`，跨平台通用）：忠实移植 .sh 语义；修正 .sh 三个问题——① 默认 global 是 URL 但 .sh 用 `cat` 处理会失败（.js 用 fetch）；② 去掉误从 git_ignore_find2merge 抄来的 `.git` 检测（判定条件改为存在 seafile-ignore.txt 或 .local.txt）；③ 根目录自身参与合并（.sh 的 `find -name '[^.]*'` 匹配不到根目录）。
- **验证**：/tmp 夹具树（覆盖根目录、local-only、深度 3 边界、skip 目录、隐藏目录）.sh 与 .js 写入产物 `diff -r` 逐字节一致；productX 全树 dry-run 候选目录 87 条两边一致。
- **提交**：flutter 仓 aimemo 本条目（`pex/seafile-ignore.local.txt` 不在任何 git 仓库内，靠 seafile 同步，不提交）；sysconfig 仓 `seafile_ignore_find2merge.js`（新增）+ `.sh`（同步修正）+ `nixhome/seafile-ignore.global.txt`（新增 6 条 Flutter 规则）。均不 push。
- **遗留**：① `seafile_ignore_find2merge.bat`（Windows 旧版）仍被 git 跟踪，待 .js 验证稳定后老板自行删除；② 各层级已生成的 `seafile-ignore.txt` 产物（含 pex/）留待老板自行跑合并脚本重新生成；③ `pex-user-flutter/ios/Podfile.lock` 已提交、`macos/Podfile.lock` 未提交（不含机器路径、可共享，是否提交待老板定夺）。

## 2026-10-07

**双机切换首跑：macbook air 上 web 端编译崩溃 → `flutter pub get` 修复**

- 背景：老板开始在 iMac（原生端）与 macbook air（web 端）间频繁切换。air 上跑 `npm run app-webapp-run-local`（`flutter run -d chrome`，`CHROME_EXECUTABLE` 指向 Edge）崩溃：`The Dart compiler exited unexpectedly`。
- 根因：`.dart_tool/package_config.json` 是机器本地文件（gitignored），引用 `/Users/luk/.pub-cache/...` 下的 `go_router-18.0.2`、`flutter_riverpod-3.4.3` 等包；两台机器 HOME 用户名恰好都是 `luk`，路径"看起来对"，但 air 的 pub 缓存里根本没有这些包（iMac 上拉过，air 从未 `pub get`）。
- 修复：在 air 上 `flutter pub get`，包落进本机缓存、package_config 重生成，`npm run app-webapp-run-local` 验证通过（Edge 起窗口、debug service 正常、热重载可用）。
- **换机 SOP**：切到另一台机器后如出现指向 `.pub-cache` 的 "No such file or directory" 编译错误，先 `flutter pub get`；同理 `node_modules` → `npm install`、`ios/Pods` → `pod install`（原生端 iMac 上才需要）。
- 已更新 `userProfile.md` 的双机切换条目。

## 2026-10-03

**下线 TRYAPP（远近星空）品牌**

- 老板决定：TRYAPP 在源项目 `pex-user-uniapp` 里只是历史遗留，无实际意义，从本项目彻底删除。删除前做过依赖扫描，结论是 tryapp 在代码里是**纯叶子节点**（`tryapp_brand.dart` / `main_tryapp.dart` / `mid_tryapp_page.dart` / `midTryapp` 路由 / `BrandFeatures.tryapp` / `logoTryapp.png` / `bgStars.jpg` 均无人反向依赖），删除不影响 agidin/babelyx。
- **删除范围**（单独一个 commit，便于回退）：
  - 代码：`main_tryapp.dart`、`brands/tryapp_brand.dart`、`pages/mid_tryapp_page.dart`、`assets/static/logoTryapp.png`、`assets/static/bgStars.jpg`；`brand_registry.dart` 去 import+列表项；`app_routes.dart` 去 `midTryapp`；`brand_features.dart` 去 `BrandFeatures.tryapp`。
  - 配置：`assets/clientEnvar.json` 去 `AKTRYAPP` 整块（JSON 校验 + 确认 agidin/babelyx 块逐字节不变）、`tool/genClientEnvar.js` 的 `APPKEYS` 去 `AKTRYAPP`。
  - Android：删 `android/app/src/tryapp/`，`build.gradle.kts` 去 tryapp flavor。
  - iOS：删 `Tryapp-{Debug,Release}.xcconfig`、`tryapp.xcscheme`、`AppIcon-tryapp.appiconset`；`project.pbxproj` 移除 6 个 tryapp 构建配置（Project/Runner/RunnerTests × Debug/Release）与 6 个文件引用；重跑 `pod install` 并清掉 Pods 里的 tryapp 残留。`xcodebuild -list` 确认只剩 agidin/babelyx，工程结构完好。
  - 脚本/生成器：`package.json` 去 10 个 tryapp 脚本；`_gen_ios_flavors.py` / `_gen_brand_icons.py` 的品牌表去 tryapp。
- **文档口径**：面向未来的文档（`architecture.md` / `projectPlan.md` / `deployNative.md` / `deployWeb.md` / `userProfile.md`）把「三品牌」改为「多品牌」，并**不写死品牌数量**——新增品牌只需按下表格式补一行。历史文档（`worklog.md` / `migrationLedger.md`）只追记录，不改写历史。
- **Cloudflare 清理**：用仓库里 wrangler OAuth 凭据（`~/Library/Preferences/.wrangler/config/default.toml`，含 `pages: write`）确认账号后，删除 Pages 项目 `tryapp-user` / `tryapp-store`（实际域名 `aimint-user.pages.dev` / `aimint-store.pages.dev`，两者均**无自定义域名**，删除不影响任何 DNS；项目已闲置约 2 年）。复核账号内 `user-agidin-com` / `user-babelyx-com` 两个在用项目及其自定义域名完好无损。
- **遗留**：后端 `pex-server-torm` 里的 AKTRYAPP 配置未动（无害冗余，删它需改后端 envar）；iOS 侧从未申请过 tryapp 的 profile，开发者账户无遗留。

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

### 创作/NFT 域 批次 2 · 2F 分享与举报

- **新增**：
  - `widgets/part_icontext_copy.dart`：`PartIcontextCopy`（复制）+ `PartIcontextPop`（分享）两个 40×40 小按钮，
    图标取源项目 `wo.ss.iconCopy`/`iconPop`（客户端常量，`App.data.js` 里定义、不随配置下发，故就近声明）。
  - `widgets/part_pop_link.dart`：分享弹窗（品牌 logo + 称谓 + 标题 + 二维码 + 可点链接 + 复制）。
    复制的文案按源项目拼 `url?_ut=\n<品牌-标题>`（粘到地址栏会被浏览器替换成空格）。
  - `widgets/part_complain.dart`：举报弹窗（理由输入 512 字 + 取消/举报）。
  - `core/api/user_api.dart`：`User/report_complain`（账户域第一个接口）。
  - `part_texts.dart` 增 `copied` / `cancel`。
- **接线**：
  - IPFS 行 → 复制 CID + 分享 `ipfsLens/<cid>`（标题 `byxCertFullname`）
  - NFT 行 → 复制 tokenId + 分享 `nftLens/nft/<contract>/<toid>`（标题 `byxTokenFullname`）
  - 操作行 → **分享**（标题=作品标题，链接=`https://goto.<webDomain>/creation/<csid>`，带 `inhaid`）
    + **举报**（仅他人作品，`reportTargetType: 'CREATION'`）
  - `userResourceDetail` 的复制按钮改用 `PartIcontextCopy`（原先是自制 IconButton）
- **实测**：`dart run tool/check_creation_pay.dart`（再扩展）——`User/report_complain` → `SUCCESS`；
  至此该脚本一次跑通 **解密支付 + 4 个名单 + 2E 上下架/隐藏 + 2F 举报** 全链路 → PASS。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。
- **收尾**：批次 2 的 2A/2B/2C/2D/2E/2F/2G 七片**除「修改作品」外全部完成**；
  「修改」阻塞于批次 3 的 `partCreate`(1012 行)，届时与 `showCreationUpdate` 一并做。

### 批次 3 · 创作与编辑（UGC 核心）

- **侦察（关键，省掉一大块高风险工作）**：`partCreate.vue` 支持三种加密封印模式
  （AGENT 委托 / JOINT 联合 / CREATOR 自主）与「顺便铸造 NFT」开关。但：
  - `envar-config.js`：`sealChoice: inUniapp ? false : undefined`、`mintChoice: 同` → **客户端恒 false**；
  - 后端 `create_creation` 同样 `if (!wo.envar.sealChoice) return BER_MINT_BY_CHOICE_DISALLOWED`
    （服务端上下文同样 falsy）→ **非 AGENT 路径两端都不可达**；
  - 且源项目里 `ticc`（tic-crypto）的 import 是**注释掉的**，`to_create_by_choice` 依赖它 → 本就跑不通。
  → 结论：**AGENT-only，本轮零加密依赖**；`tic-crypto` 的 Dart 版留给将来（阶段四）。
- **新增**：
  - `widgets/part_create.dart`：创作编辑器（标题 / 封面上传 / 内容 story / 下一步）
    + 合约弹窗（TVIEW/THOLD/TWORK/TOWN，按 `pactDict` 决定出现哪些）
    + `submitCreation` / `showCreationFeeSheet`（余额不足复用 2C 付费确认）/ `afterCreation`
  - `core/state/creation_draft_provider.dart`：草稿状态（`ctnCreate` / `ctnUpdate` 合一），
    修改模式含「按 unid 装载 + 原创主/权利主权限校验」
  - `pages/mid_babely_page.dart`（新建，Babelyx 中间按钮落地页；手机固定顶栏：返回/标题/跳最后一个标签）
  - `pages/show_creation_update_page.dart`（修改），接上 2E 里搁置的「修改」按钮
  - `widgets/part_linkhelp.dart`；`creation_api.createCreation`（**同接口兼作更新**，带 csid 即更新）
  - `tool/check_create_creation.dart`
- **顺带修的真问题**：
  1. **品牌标签栏此前误用 Agidin 列表** → 新增 `BrandConfig.tabItems`，
     Babelyx = 探索/遇见/AIGC/我的，TRYAPP = 探索/遇见/Aibot/我的；PC 顶栏现在按品牌渲染
     （截图已验证：Babelyx 顶栏显示 Creations/Creators/AIGC）。
  2. 中间按钮图标/文案：Babelyx 应为火苗 + 「创造」，TRYAPP 为火苗 + 「行动」，
     此前都吃默认值（chatboxes + 对话）→ 已按 `pages.json` 修正。
  3. `midBabely` 的标题「创造新可能」/图标 `fire-filled` 补进品牌配置。
  4. `story_utils` 增 `isFilledSection` / `isEmptyStory`（对应 `wo.tt.is_filled_section` / `is_empty_story`）。
- **实测**：`dart run tool/check_create_creation.dart` ——
  注册用户 → 创建（`creationReward=100`、`userUpdated` 就位）→ 复查标题与 `pexdataUser` 一致
  → 带 `csid` 再提交（更新）→ 复查标题已变 → **PASS**。
  截图：手机（返回/标题/My→ + 标题/封面/内容/Next）与 PC（探索·遇见·AIGC + 火苗中间按钮）均正确。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。
- **遗留（下一步候选）**：手机端**底部标签栏**尚未实现（源项目由 uni-app 原生 tabBar 承担，
  Flutter 侧目前手机端没有标签栏）；`menuCreator` / `menuMarket` / `showCreator` / `menuUzone` 等页面未迁移。

### 手机端底部标签栏 + 创作者域首片（menuCreator）

- **背景**：批次 3 时发现**手机端根本没有标签栏**（源项目的标签栏是 uni-app 原生 tabBar，
  Flutter 侧一直没做）→ 老板确认「手机端要有底部标签栏」。
- **架构冲突与老板决策**：源项目 Babelyx 标签栏是 4 个（探索/遇见/**AIGC**/我的），
  但我们的 Babelyx 入口**故意不含 AI 域**（`main_babelyx.dart` 不 import `route_ai`，产物小 147KB）。
  → 老板 2026-09-30 决定：**去掉 AIGC，只留 3 个**（保持裁剪）；TRYAPP 因入口只注册了 AI+公共域，
  标签栏暂列 2 项（`menuAipp` / `menuUzone`），等 TRYAPP 定位明确再定。
- **新增 `widgets/part_tab_bar_phone.dart`**：底色 `#303133`、未选中 `#c0c0c0`、选中 `#ffffff`、
  图标 26px、文字 12px；中间凸起按钮 = 白底圆内品牌 logo + 「创造/对话/行动」，
  占第 `length ~/ 2` 位（uni-app 的 midButton 规则：3 标签→1左2右，2 标签→1左1右）。
  - `TabItem` 增 `iconTypeOn`（源项目 `selectedText`）；`BrandConfig.tabItems` 品牌化（Agidin 2 / Babelyx 3）。
  - 由 tab 页面显式开启：`PartWindowLayout(showTabBar: true)`（`menuCreation`/`menuCreator`/`menuAipp`），
    普通页（`midBabely`/`showCreation` 等）不显示——与源项目「只有 tabBar 页面才有标签栏」一致。
- **顺带补齐创作者域首片**（否则 Babelyx 标签栏 3 个里有 2 个是死标签）：
  - `core/api/creator_api.dart`（`get_creator_list` / `get_single_creator`）
  - `core/state/creator_provider.dart`（对应 `wo.ss.Creator`）
  - `widgets/part_creator_all.dart` / `part_creator_card_list.dart`（卡片=头像+昵称+选集/圈子统计+
    该创作者的作品小卡片；被屏蔽时显示「该用户已被您屏蔽」）
  - `pages/menu_creator_page.dart`（遇见；顶栏分类 + 「我的圈子」入口）
- **实测**：`tool/check_create_creation.dart` 扩展第 5 步 —— `User/get_creator_list` 返回 12 位创作者，
  卡片所需 7 个字段（usid/nickname/portrait/countCtnPublic/countFollower/countFollowing/collectList）齐全 → PASS。
  另修脚本一处：后端按**内容**去重（`ERROR_DUPLICATE_CREATION`），故正文也要带时间戳。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。
- **遗留**：`menuUzone`（我的空间，675 行，属账户/社交域）未迁移 → 「我的」标签暂落到占位页；
  这是下一步最该做的（标签栏可见性最高）。

### 账户域 · menuUzone「我的空间」（675 行，手机端「我的」标签落地）

- **老板决策（2026-09-30）**：清单里指向**尚未迁移页面**的行（账号/实名/资金/消息/圈子/设置/客服）
  **全部渲染、跳现有占位页**——复用 `app_router.dart` 的兜底路由（占位页显示「XX 尚未迁移」），
  对应页面迁移后**自动生效、零回改**；比「置灰不可点」更接近源项目观感，也不留死按钮。
- **新增**：
  - `pages/menu_uzone_page.dart`：未登录态（slogans + 注册奖励 + 注册登录 + 资源 + 重启 + 语言）
    / 已登录态（顶栏头像上传·昵称弹窗·自我介绍弹窗·分享 + 余额/消息/选集/圈子徽标 + 语言表
    + 8 行清单 + 退出·资源·重启）
  - `core/api/user_api.dart`：`update_portrait` / `update_nickname` / `update_aboutme` / `logout_user`
  - `core/state/app_startup_notifier.dart`：`restart()`（源项目 `reset_all` + `reLaunch(homePortal)`）
  - `core/util/story_utils.dart`：`filterStory`（对应 `wo.tt.filter_story`，去掉 `{text:''}` 空段落）
  - 路由：`menuUzone` 注册在 **`route_common.dart`**（源项目里它是三品牌共有的 tabBar 页）
  - `AppRoutes` 补 `umyAccount` / `umyKyc` / `umyMia` / `umyConfig` / `umyInvite`（跳转占位用）
- **拆解 `partWindowLayoutUser`**：它 = `partWindow` + header + (内容 | 未登录引导) + footer，
  Flutter 侧「布局」由既有的 `part_window_layout.dart` 承担，**未登录引导落在本页**（故该组件目标文件为「—」）。
- **顺手修的真 bug**：`part_window_header` 的 PC 头像用 `AssetImage(pexAssetPath(portrait))` 渲染
  **服务端头像地址**（http/https）——`AssetImage` 只认打包资源、遇到网络地址会报错，
  改为 `ServerImage`（与详情页头像一致）。
- **自己写出来又抓到的一个 bug**：`urlMyself`（分享本人主页）原先从**用户对象**取 `webDomain`，
  但该字段在**品牌配置**里 → 会拼出 `https://goto./creator/...`；已改为读 `brandProvider.webDomain`，
  实测分享弹窗链接为 `https://goto.babelyx.com/creator/<haid>?inhaid=<haid>` ✅。
- **有意简化（已在代码注明）**：设置行 footer 只显示「语言 | 品牌币种」；
  源项目还有**法币 / 加密币**两段，那属于 `umyConfig`（设置）域且**尚未迁移**，迁移时补。
- **实测**：
  - `dart run tool/check_user_zone.dart` —— 注册 → 改昵称 / 自我介绍 / 头像 → `first_touch` 复查三者已落库
    → 非数组入参返回 `FAIL_INVALID_ABOUTME` → `logout_user` SUCCESS → **PASS**
  - 视觉（headless Chrome，手机 500 / PC 1200）：未登录引导、已登录顶栏与 8 行清单、
    改昵称弹窗、自我介绍弹窗、分享弹窗（二维码 + 正确链接）、
    点徽标 → 占位页「「umyCircle」尚未迁移」全部正确
- **工具经验（重要，避免重复踩坑）**：
  1. `--screenshot` + `--virtual-time-budget` **截不到刚弹出的弹窗**——虚拟时间会让定时器立刻触发，
     但弹窗首帧还没绘制就截图了（我因此一度误判「弹窗没出来」）。→ 改用 CDP 真实等待，见下条。
  2. 新增 `tool/cdpShot.js`（Node 18+，自带 fetch/WebSocket）：CDP 打开页面 → 真实等待 →
     按坐标点击 → 截图，专用于验证**弹窗/交互态**。
     **注意 CDP `Input.dispatchMouseEvent` 坐标是 CSS 像素，不要乘 dpr**（乘了会点偏到别的控件上，
     我第一次就是这样误点到「My Circles」徽标、结果验证了徽标跳转是好的）。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。
- **遗留**：清单里 7 个目标页仍未迁移（点了看占位页）；`umyConfig` 迁移时补设置行的法币/加密币段。

### 账户域 · umyConfig（我的设置）+ umyContact（联系客服）

- **老板决策（2026-09-30）**：`umyConfig` 的货币选择「**完整实现 + 本地持久化**」。
  背景：源项目 `to_change_bankcoin/cryptocoin` 只改内存变量、底下写着 `todo: 通知后台修改`，
  **既不通知后端也不存本地，刷新即丢**；迁移版写本地存储（`bankcoinCode` / `cryptocoinCode`），
  默认值仍与源项目一致（法币按地区 CN→CNY、其余→USD；加密币 TUC）。
- **新增**：
  - `core/i18n/coins.dart`（**生成物**）：法定货币 180 种 + 加密币 9 种 + 地区→法币映射；
    生成器 `tool/genCoins.js`（数据源 = 源项目依赖包 `wo-core-i18n`，只留页面用得到的字段，约 22KB）
  - `core/state/coin_provider.dart`（对应 `wo.ss.i18n.bankcoinNow/cryptocoinNow`）
  - `widgets/part_coin_table.dart`（对应 `partCoinTable.vue`：符号/名称/代号三列 + 名称·代号可排序 + 选择弹窗）
  - `pages/umy_config_page.dart`（三行：界面语言 / 银行货币 / 加密货币）
  - `pages/umy_contact_page.dart`（邮箱 + 留言 → `System/contact_csr`；团队电话/邮箱/地址；手机端语言表）
  - `core/api/system_api.dart`（`contactCsr`，账户域之外第一个 `System` 接口）
  - 两者都注册在 `route_common.dart`（三品牌共用的账户域页）
- **顺带补齐**：`menuUzone` 设置行恢复源项目的三段式「语言 | 法币 | 加密币」
  （上一片我把法币/加密币省掉了，注明「待 umyConfig 迁移时补」，现在补上了）。
- **实测**：
  - `dart run tool/check_contact_csr.dart` → `contact_csr` SUCCESS → **PASS**
  - 视觉（headless + `tool/cdpShot.js`）：设置页三行与图标、货币弹窗（可排序，Name/Code 带升降箭头）、
    选中后行内文案更新、**重新加载后仍是所选货币（持久化生效）**；
    客服页表单、未填写时「发送」置灰、填写后变品牌色可点、团队邮箱链接、手机端语言表。
  - `tool/cdpShot.js` 增 `type:文本` 步骤（用 CDP `Input.insertText`）——**Flutter web 输入框可用**，
    以后表单类页面可以端到端验证「填写 → 按钮态 → 提交」。
- **注意（副作用）**：`System/contact_csr` 会**真的发邮件**给后端 `oncallMessage.to`（值班邮箱），
  且后端**不做入参校验**（空内容也发）。验证期间共发出 2 封测试邮件（1 次 curl + 1 次脚本），
  脚本内已注明「别在循环里跑」。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。

### 账户域 · 账号安全闭环（umyAccount 5 页）

- **页面**：`umy_account_page`（用户号/手机/邮箱/密码/注销 五行）
  · `umy_account_password_page`（改密码，两项哈希 + 6 位下限 + 新旧不同 + 两次一致）
  · `umy_account_commid_page`（验证当前账号：手机/邮箱分段选择 + 大字账号 + 验证码）
  · `umy_account_commid_new_page`（设置新账号：地区选择 + 新手机/邮箱 + 验证码）
  · `umy_account_terminate_page`（销毁账号：密码 + 二次确认 + 7 天冷静期说明）
  五页全部注册在 `route_common.dart`（三品牌共用）。
- **复用（本片的主要工程决策）**：`part_passcode_verify` 原本硬绑 `identProvider`，
  泛化为可传 `commid` / `usid` / `header` / `onVerified` / `onPasscodeSent` / `sendDisabled`
  ——**ident 两页一行未改**，账户域两页直接复用，避免再写第二份「发码 + 校验」逻辑。
  - 有意简化：源项目在 CommidNew 里**先**用 `Ident.verifyExpireAt` 做客户端过期判断，
    迁移版依赖后端返回 `OLD_VERIFY_EXPIRED`（**后端本来就有这道校验**，且带原因文案），
    少一个参数、行为一致。
- **新增**：
  - `core/state/session_reset.dart`：把「重置会话缓存」（源项目 vuex `reset_all`）收成一处，
    `menuUzone` 的重启与 `umyAccountTerminate` 的注销共用（此前是 menuUzone 里的私有方法）
  - `user_api`：`changePassword` / `terminateAccount` / `sendPasscode` / `verifyPasscode`
  - `part_ident_input` 增 `autofocus`（对应源项目 `uni-easyinput` 的 `:focus`）
- **顺带修**：`showPexModal` 的弹窗底色从 M3 品牌染色改为**白色**（源项目为白）——
  这条影响全站所有确认弹窗（此前截图里偏粉）。
- **源项目缺口**：`wo.ss.tTerminate`（注销页的说明段）在 `envar-config.js` 里恒为 `undefined`，
  **从未被定义过** → 迁移版照此留空（代码注释写明：后台一填就会显示）。若你希望给用户一段
  明确的注销须知，需要产品文案。
- **实测**：
  - `dart run tool/check_account.dart` —— 注册 → 改密码（错密码 `PASSWORD_UNMATCH` / 对的 `SUCCESS`）
    → **用新密码复登 `LOGIN_SUCCESS`**（证明改动真生效）→ CHECK_OLD 发码 + 本地哈希比对 + 校验
    （`VERIFY_SUCCESS`，带 `verifyExpireAt`）→ CHECK_NEW 改邮箱并复查已更新
    → 销毁账号（错 `PASSWORD_UNMATCH` / 对 `SUCCESS`）→ **PASS**
  - 视觉（CDP 截图，手机 500）：5 页布局；改密码页「三个框填写 → 按钮由灰变品牌色 → 提交出成功弹窗」；
    验证当前账号页「发码成功（绿字）+ 倒计时 + 输入 6 位错误码 → 红字 Passcode is mismatched」（客户端哈希闸门生效）；
    设置新账号页「填邮箱 → 发码按钮变可用」+ 地区选择表（搜索 + 国旗 + 区号）；
    销毁账号页「填密码 → 二次确认弹窗（白色，含昵称 + 7 天警告）」
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。
- **遗留**：`umyKyc`(435) / `umyInvite*` / `umyCircle` / `umyMia*` / `midTryapp` 未迁移；
  `umyAccount` 里「手机/邮箱」两行都指向 `umyAccountCommid`（与源项目一致）。

### 账户域 · umyCircle（我的圈子）+ umyInvite（邀请朋友）+ umyInviteList

- **合并复用**：源项目 `partCreatorMyFollowings` / `partCreatorMyFollowers` / `partCreatorMyInvitees`
  三个组件 340 行里逻辑几乎一致（只有接口、时间字段、空态文案、「前往」按钮不同）→
  合并为 `widgets/part_circle_list.dart`，由 `CircleTag` 枚举区分；
  状态存 `creator_provider`（`myFollowingList` / `myFollowerList` / `myInviteeList` + 各自 `onceLoaded`）。
- **修好的两处源项目行为**（代码有注释）：
  1. 源项目「加载更多」是**整表替换**（`push(...)` 被注释掉），翻页会丢掉已加载的页
     → 迁移版追加 + 按 usid 去重（`appendCircle`）
  2. `get_invitee_list` 后端只认 `order/skip/take`，源项目传的 `beforeTime` **被忽略**
     → 数量 ≥ 每页条数时会永远翻到同一页；迁移版改用 `skip` 翻页
- **分类条**：源项目 `uni-segmented-control` 只在 `appkey === 'AKBABELY'` 渲染
  （当年 `myCircleDict` 仅 Babelyx 有值的遗留判断），现在三品牌配置都有该字典 → 一律渲染；
  按钮两行 = `onlineUser[counter]` + 分类名（对应源项目的 `'\n'` 拼接）。
- **邀请页**：标题 `tInviteTitle`（三品牌均未配置 → 回退 `slogans`，与源项目 `||` 一致）+
  优惠码（haid + 复制）/ 优惠链接（`webUrlRoot/#/?inhaid=<haid>` + 复制 + 分享弹窗）+
  优惠二维码 + 「已奖励 0¢ / 已邀请 1」两个渐变入口（入口目标与源项目一致：
  Agidin → `umyInviteList`，其余 → `umyCircle?tagnow=INVITEE`）。
- **新增**：`part_load_more` 补 `loadFresh`（顶部「刷新」条）；`envar` 补
  `webUrlRoot` / `tInviteTitle` / `linkCommunity` / `slogans` / `Creator.myCircleDict`；
  路由补 `umyInviteList`（真页面）与 `umyFundTranx`（跳占位页）。
- **实测**：
  - `dart run tool/check_circle.dart` **PASS**：注册 A/B → B 关注 A → B 的关注名单含 A、
    A 的粉丝名单含 B → 用 A 的优惠码注册 C → A 的邀请名单含 C 且 `count=1`、
    `skip=0` 1 条 / `skip=1` 0 条（skip 翻页正确）
  - 视觉（CDP 截图，手机 500）：邀请页（标语标题、200¢、优惠码 546bd4、
    链接 `https://u.babelyx.com/#/?inhaid=546bd4`、二维码、「0¢ Rewarded / 1 Invited」渐变入口）、
    圈子页三个分类（选中高亮 + 数量）、关注/粉丝的创作者卡片、
    邀请名单「I have invited 1 users + Invite More + 注册日期行」；PC 1200 邀请页布局正常
  - 造数脚本 `/tmp/seed_circle.js`（临时）：注册 A/B/C + 互关 + C 挂在 A 名下
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。
- **遗留**：`menuUzone` 的圈子徽标/清单行、`umyAccount` 的「用户号」行现在都指向真页面；
  剩 `umyKyc`(435) / `umyMia*` / `midTryapp`。

### 消息域 · umyMia（我的消息）+ umyMiaDetail（详情 / 回复）

- **新增**：
  - `core/api/mia_api.dart`：`list_my_mia` / `get_mia_detail` / `send_mia`（账户域之外第二个独立 apiWho）
  - `core/state/mia_provider.dart`：对应 `wo.ss.Mia`（`myMiaList` + `onceLoaded` + `miaNow`）
  - `pages/umy_mia_page.dart`：消息列表（头像 + 发件人 + 标题/摘要 + 日期 + UNREAD 红点）
  - `pages/umy_mia_detail_page.dart`：详情（头像/昵称/时间 + `PartStoryReader`）
    + 「我的回复」`PartStoryEditor`（按 `miaText/miaImage/...` 开关限制段落类型，
      Babelyx 预置 = 文本+图片、最多 2 段）+ 空回复提示（5 秒自动消失）+ 成功弹窗
  - `story_utils.extractStoryTitle`（对应 `wo.tt.extract_story_title`；段落 text 兼容语言字典）
  - 路由注册在 `route_common.dart`（三品牌共用）；`AppRoutes` 补 `umyMiaDetail`
- **复用**：详情页完全搭在既有的 `PartStoryReader` / `PartStoryEditor` 上（零改动）；
  已读后用 `mergeInList` 就地合并列表项，红点即时消失（源项目靠 `$forceUpdate`）。
- **修好的行为**：源项目「加载更多」同样是整表替换 → 迁移版追加 + 按 `miaUuid` 去重。
- **实测**：
  - `dart run tool/check_mia.dart` **PASS**：B 给 A 发消息 → A 列表出现且 UNREAD、
    `miaTitle` 由后端 normalize 兜底 → 打开详情返回 `miaUnread=UNREAD` 且状态变 READ →
    再拉详情不再返回 miaUnread → A 回复 B → B 列表出现回复 → 空 story 被拒 `INPUT_MALFORMED`
  - 视觉 / 交互（CDP，造数：B 给 A 发 2 条消息）：
    列表两条消息带红点 → 点行进详情（顶部 Back）→ 深链 `?miaUuid=` 直接进详情
    （uuid-only 分支）→ **详情打开后服务端已标记 READ**（API + sqlite 双确认）→
    输入回复 → Publish → 白色成功弹窗 → **回复落库**（sqlite 确认 `{"text":"好的，我们微信详聊！"}`）
  - **工具坑（记下）**：CDP 点击坐标是 **CSS 像素**，而截图是 dpr=2 的设备像素——
    我把截图上的 y=530 直接当坐标用，点了个空处；除以 2（y=265）才对。
    `tool/cdpShot.js` 的用法注释里补一句提醒。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。
- **环境**：本机起了一个 dev 后端（7739）和一个静态服务（8090，serve `build/web`）供验证用，
  老板确认沿用（「我用你的，你不要停」）。

### 账户域收官 · umyKyc（实名认证）+ midTryapp（TRYAPP 空白中页）

- **umyKyc**（435 行）：
  - 表单：姓名 / 国籍（`PartLandTable` 弹层，默认 = `onlineUser.citizen || userlandCode || phoneLand`）
    / 证件类型（IDCARD/PASSPORT/DRIVERID/OTHER）/ 证件号码（18 位、letterSpacing）+ 证件正反面（1:1 上传框）
  - 上传走既有 `pickMedia → FileloaderApi.validate/uploadFile → chooseUrl`（与头像同一条链路）
  - 提交 gated 与源项目一致：姓名+号码+正面照必填，**IDCARD 还需背面照**（护照/驾照/其他不需要）
  - `kycStateL1 ∈ {SUBMITTED, PASSED}` → 整表只读（源项目 `isFixed`），
    状态行取 `kycDict[state].long` 并着色（SUBMITTED 黄 / REJECTED 红 / PASSED 绿，取自源项目 scss 变量值）
  - `user_api.updateKyc`：注意成功码是 **`SUBMITTED`** 而非 `SUCCESS`；成功后把全部字段 merge 回 onlineUser
  - **邮件提醒**：`update_kyc` 的成功分支和 `contact_csr` 一样会**真发一封邮件**到
    `oncallMessage.to`（= 老板邮箱）。`tool/check_kyc.dart` 只会因此发 **1 封**（完整提交那一步），
    缺字段与重复提交两个分支都不发信。
  - **修自己引入的 bug**：表单初值原本在 `initState` 里同步读 `onlineUserProvider`，
    但那时 `first_touch` 还没回来 → 姓名/国籍/证件号全空（截图抓到了）。改为等 `waitAutologin()` 后再填。
- **midTryapp**：按老板决定只做**空白框架页**（`PartWindowLayout` + PC 导航占位，无业务），
  只在 `main_tryapp.dart` 注册路由（入口级裁剪）。TRYAPP = 与品牌无关的中立基础框架占位。
- **实测**：
  - `dart run tool/check_kyc.dart` **PASS**：缺字段 → `INPUT_MALFORMED`（不发信）→ 完整提交 →
    `SUBMITTED`（发了 1 封邮件）→ `first_touch` 复查 `kycStateL1/realname/citizen/idType` 已落库 →
    重复提交 → `BER_UNEXPECTED`（不发信）
  - 视觉（CDP，手机 500）：空表单（Submit 置灰）→ 填姓名+号码后仍置灰（**IDCARD 缺背面照**，gating 正确）→
    DB 直设 PASSED 后整表只读 + 绿色「You have passed verification!」→
    把 idCardCover/Back 指到本地 `_filestore` 的测试图后**照片正常渲染**
  - tryapp 产物单独构建（`build/web_tryapp`）成功，`/#/midTryapp` 直达显示空白框架页（无报错；
    若路由未注册会显示「尚未迁移」占位文字，据此确认命中了新页面）
- **环境补充说明**：本机目前访问不到 `ipfs.tic.cc` / `ipfs.test.tic.cc:8080`（ping 100% loss），
  IPFS CID 形式的证件照/头像在截图里显示空白是**网络原因**，代码路径已用 `_filestore` 相对路径验证无误。
- **验证**：`flutter analyze` 0 问题；Babelyx + Tryapp 双产物构建成功。
- **里程碑**：账户 / 社交 / 消息域页面全部迁完；`menuUzone` 八行清单中仅剩的目标页缺口 = 无
  （全部为真页面或按需占位）。剩余大项在创作/NFT 域与资金域。

### 复核 · menuCreation（老板要求迁移，发现早已迁移，改为补齐 3 处缺口）

- 老板点名「迁移 menuCreation」——对照后发现它在更早批次已完成（`pages/menu_creation_page.dart`，
  注册在 `route_creation.dart`）。逐行对照源项目（79 行）发现 3 处小缺口，按老板选择补齐：
  1. **`?tagnow=` 路由参数**：源项目 `onLoad({tagnow})` 只认 `uiClassDict` 里存在的键，
     点分类是 `uni.reLaunch` 换参重开 → 迁移版改为 `context.go('/menuCreation?tagnow=<key>')`
     （当前三品牌 `uiClassDict` 都只有 `POALL` 一项，故视觉上无差别，但后台加分类即自动生效）
  2. **右上「前往」文案**：源项目用 `pageSet['umyCollection'].i18nGotoTitle` =
     「我的选集 / My Collections」，迁移版此前写成了「我的收藏 / My Collection」→ 对齐；
     顺带把 `umy_collection_page` 的页标题也对齐源项目 `i18nPageTitle`（我的选集 / My Collections）
  3. **登录判断**：`['usid'] != null` → `isOnlineProvider`（usid 非空才算登录，空串不误判）
- **实测**：Babelyx 构建成功；CDP 截图（手机 500，DB 有 301 条 creation）：分类条 +
  「My Collections ›」+ Load more + 双列作品卡片 + 底部标签栏（Creations 高亮）全部正确；
  游客点「My Collections」会进 `identBegin`（与源项目 `usid ? umyCollection : identBegin` 一致）。
- **验证**：`flutter analyze` 0 问题。

### 创作域 · showCreator（个人展 / 创作者主页，712 行）

- **新增页面** `pages/show_creator_page.dart`，两大分支与源项目一致：
  - **未找到**：提示 + 「Creator ID」搜索框（回车/按钮 → `?unid=`）+「或者到处看看」
    渐变按钮（`--YellowMatt` #fcbd71 → `--RedMy`）→ `menuCreator`
  - **已找到**：头像 + 昵称 + 分享（复用 `showPopLinkSheet`，链接
    `https://goto.<域名>/creator/<haid|usid>?inhaid=<我的 haid>`）+ 统计（公开数 / 圈子数）+
    「管理」（本人 → `menuUzone`）或「私信」（他页 → 私信弹窗）+ 屏蔽/解除屏蔽 + 举报 + 关注/已关注；
    自我介绍一行摘要 + 展开（`PartStoryReader`）/收起；屏蔽空态；作品双列列表 + 刷新/加载更多
- **新增接口**：`creator_api.getSingleCreator`（支持 `usid`/`haid`/`unid` + `skip`/`takeLimit`）、
  `creation_api.getUserCreations`、`user_api.followUser/unfollowUser/blockUser/unblockUser`
- **新增状态方法**：`creatorProvider.setBlockStateInLists` / `removeFromListAll`
  （对应源项目屏蔽后遍历 `myFollowingList`/`myFollowerList`/`creatorListAll` 的同步）
- **修好的行为**：源项目作品列表「加载更多」仍是**整表替换**（`push` 被注释）→ 迁移版追加 + 按 `csid` 去重
- **如实简化（代码已注释）**：源项目 `onLoad` 有「已有 hostUser（从列表页带过来）」的快速分支，
  它依赖上一个页面把整条用户数据塞进 `User.hostUser`；Flutter 侧列表点击只传 `unid`
  （`part_user_list` / `part_creator_card_list` 都是 `?unid=`），因此统一走「按参数查人」分支，结果一致
- **实测**：
  - `dart run tool/check_creator.dart` **PASS**：按 `usid`/`haid`/`unid` 三种方式都能查到同一个人 →
    无参数 `ERROR_USID_MISSING` / 坏 unid `ERROR_BAD_UNID` → `get_user_creations` SUCCESS →
    关注后 `followState=FOLLOWED`、取关 `UNFOLLOWED` → 屏蔽 `BLOCKED`、解封 `UNBLOCKED`（均回查确认）
  - 视觉 / 交互（CDP，手机 500；用库里真实创作者「年少不识花期」97 作品 / 3 关注 / 6 粉丝）：
    访客视角（Share / Message / Block / Report / Follow 齐全）→ 点 Follow 变红色「Following」
    且圈子数 9→10 → 点 Share 弹出分享弹窗（品牌 logo + 二维码 + 正确链接）→
    点 Message 弹出「Message to 年少不识花期」私信编辑器 → 点 Block 弹白色确认框 →
    自己的主页显示「Manage」且无关注/屏蔽 → 坏 unid 显示未找到分支 → 屏蔽后显示
    「This user is blocked by you.」+ Unblock（验证后已解封复原）
- **工具坑（重要，已修）**：`tool/cdpShot.js` 用的固定 `--user-data-dir` 会让 **service worker
  命中旧缓存** —— 重建产物后截图仍显示旧界面（我一度以为渐变按钮没生效）。现在每次运行前
  清空该 profile 目录，重建后立刻可见。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。
- **连带生效**：`menuCreator`（遇见）列表卡片、`umyCircle` 名单、作品详情页里的作者头像点击，
  现在都落到真页面。

### 创作域收尾 · menuMarket（交易市场）+ showWebview（内嵌网页）

- **menuMarket**：分类条（`Market.uiClassDict`，三品牌都只有 `MKALL`）+ 右上「我的资金」
  （未登录 → `identBegin`）+ 空态。
  **如实说明**：源项目这一页**本身就是个空壳**——`MKALL` 分支只渲染
  `partEmptyList(「当前没有创作品在售」)`，交易功能从未实装。迁移版保持一致，不做多余发挥。
- **showWebview**：源项目里它**只在非 PC 端使用**（`open_url({inWebview:true})` 才会写
  `wo.ss.webviewUrl` 并跳本页；PC 一律 `window.open`）。老板 2026-10-03 决定**引入
  `webview_flutter` 做全平台内嵌**，于是：
  - 新增 `widgets/part_webview.dart`（**条件导入**）+ `part_webview_native.dart`（`webview_flutter`）
    + `part_webview_web.dart`（`<iframe>`，`dart:ui_web` + `package:web`）；
    业务侧只 `import 'part_webview.dart'`
  - 新增依赖 `webview_flutter`（连带 android/wkwebview 实现）与 `web`（由传递依赖提为直接依赖）
  - 页面 url/title 走**路由参数**（源项目写 `wo.ss`）；`envar.webviewUrl/webviewTitle` 作兜底；
    空地址自动回 `homePortal`（对应源项目 `onShow` 里的 reLaunch）
  - 另提供 `openUrlInWebview()`：PC → 外部浏览器（等价源项目 `window.open`），其余平台 → 本页内嵌
- **实测**：
  - `flutter analyze` 0 问题；Babelyx Web 构建成功（**Web 端确认没把 webview 实现打进产物**，
    条件导入生效）
  - CDP 截图：`/#/showWebview?url=https%3A%2F%2Fexample.com&title=Demo%20Page`
    → 顶部显示「Demo Page」+ **iframe 真把 example.com 渲染进来了**；
    `/#/showWebview`（空 url）→ 自动回首页门户；
    `/#/menuMarket` → 「Exchange Market」分类条 + 「My Coins ›」+ 空态；
    游客点「My Coins」→ 进登录页（与源项目 `usid ? umyFund : identBegin` 一致）
  - **坑（记下）**：在 hash 路由里直接写 `#/showWebview%3Furl=...` 会被当成**路径**而走兜底占位页
    （之前用 seed 页时 `%3F` 会被 URLSearchParams 解码成真正的 `?` 才对）。
    直链要用字面 `?` / `&`，只对**内层 URL** 做百分号编码。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。
- **备注（原生端待办）**：`webview_flutter` 在 iOS/Android 首次构建时通常要补原生配置
  （Android `minSdkVersion`、iOS `Podfile` 平台版本等）；等真正开始出移动端产物时一并处理。
- **里程碑**：账户 / 社交 / 消息 / 创作四域页面**全部迁完**；只剩**资金域**（`umyFund*`、`partDeposit` 等）。

### 资金域（第一批）· umyFund（我的资金）+ umyFundTranx + partTxList

- **页面**：
  - `pages/umy_fund_page.dart`：钱包地址行（外部浏览器打开 + 复制 + 分享弹窗）+「当前余额」+
    收支分类行 + 充值/提现按钮；含 `cashoutAlone`（提现单独成行）分支与
    `hideWalletAddress` / `hideDepositButton` / `hideCashoutButton` 三个开关
  - `pages/umy_fund_tranx_page.dart`：收支类型下拉（`paydir + 名称`）+ 明细列表；
    切类型 = `context.go('/umyFundTranx?tagnow=…')`（对应源项目 `redirectTo`）
  - `widgets/part_tx_list.dart`：明细行 = 类型名 + 作品链接（`openTitle` 或「无题#尾6」）/
    金额、日期、对方昵称头像（点进创作者主页）或支付渠道名、右侧带符号金额（我支出红 -、收入绿 +）
- **新增**：`core/state/tx_provider.dart`（对应 `wo.ss.Tx`：`tagNow` + 各标签列表 + `onceLoaded`）、
  `user_api.getTxList`、`envar` 的 `tucLens`/`hide*`/`cashoutAlone`/`showTxGroup`/`myTxDict`/`txTypeDict`
- **品牌分支按既有约定处理**：源项目用 `appkey === 'AKBABELY'` / `'AKAGIDIN'` 判断，
  迁移版在 `BrandConfig` 上加 `showCreationIncome`（= `features.enableCreation`）与
  `showAiCosts`（`appkey === 'AKAGIDIN'`），**业务代码不判 appkey**。
- **修好的行为**：`partTxList`「加载更多」仍是整表替换 → 迁移版追加 + 按 `txUuid` 去重。
- **如实说明（两处留白）**：充值按钮指向 `partDeposit`（1066 行，**尚未迁移**）→
  现跳占位页「`umyFundDeposit` 尚未迁移」；提现 → `umyFundChannel` / `umyFundChannelCreate`（同样未迁移）。
  这不是遗漏，是刻意让按钮「有去处、可见进度」，与之前 menuUzone 清单行的做法一致。
- **实测**：
  - `dart run tool/check_fund.dart` **PASS**：注册临时用户 → 用 sqlite 直接写入
    充值 x2 / 奖励 x1 / 我支出 x1 / 我收入 x1（**写入路径属于尚未迁移的 partDeposit 等，工具只验读取**）→
    `TXG_ALL` 6 条、`TXG_RECHARGE` 2 条、`TXG_IN_REWARD` ≥1、`TXG_OUT_PEX` 1、`TXG_IN_PEX_CREATOR` 1 →
    倒序正确、`beforeTime` 翻页正确 → `first_touch` 里资金页要用的 9 个字段齐全 →
    跑完自动清理测试流水
  - **工具踩坑（记下）**：`stamp.substring(0,8)` 当手机号后 8 位**几乎不变**（毫秒时间戳前 8 位要 ~2.8 小时才进一位），
    连跑两次会撞号；`txUuid` 用固定串也一样，`dpOrderCode` 空串还会撞唯一约束 → 全部改成「时间戳后 8 位 + 后缀」。
  - 视觉 / 交互（CDP，手机 500；用测好的临时用户种了余额与流水）：
    资金页（钱包地址 + Copy/Share、Balance 286.5¢、+200 / +100 / +15 / -28 四行、Deposit/Cashout 渐变按钮）→
    明细页「+ Recharges」两条（日期 + Wechat/AliPay + 绿色 +100¢）→ 下拉切到「- Creation Costs」
    后 URL 与列表同步刷新（-8¢ 红字）→ 点 Deposit 落到「`umyFundDeposit` 尚未迁移」占位页
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。

### 资金域（第二批）· partDeposit 充值面板 + WebSocket 实时通道

- **实时通道（新）**：`core/state/socket_provider.dart`，照搬源项目 `wo.unisocket` 协议：
  连 `envar.servUrl`（http→ws）→ 有 passtoken 就发 `SOCKET_OWNER_RECONNECT` 认领 →
  20s 心跳 PING → 断开每 5s 重连 → 按 `skevent` 广播给订阅方。
  接入点：`app_startup_notifier.runOnce`（first_touch 后连接）、`setOnlineUser`（登录后发 `SOCKET_OWNER`）；
  **`part_window_footer` 的呼吸灯从 HTTP `connected` 改为真正的 `socketAlive`**（源项目语义）。
- **`widgets/part_deposit.dart`**（源 1066 行）：
  - **PAY**：标题 + 金额（有 `payAmountPrompt` 时可输入）+ 备注 + 帮助链接 + 提交按钮
    （`submitAction(payAmount)` 由调用方提供；**余额不足自动切到 DEPOSIT**，与源项目一致）
  - **DEPOSIT**：标题 + 呼吸灯余额 + 金额步进（管理员 0.01 / 普通 1）+ 币种选择（复用 `PartCoinTable`）
    + 换算与赠送（`coinToTUC` / `depositBonusRate`）+ CNY 渠道(微信/支付宝)+二维码+链接+复制/分享
    + USDT 链选择+转账说明（链名可点进合约页）+地址二维码+地址复制/分享 + 刷新余额 + 客服入口
  - 到账确认：`RECHARGE_SUCCESS` 推送（按 usid 过滤）或「刷新余额」发现余额变大 → 弹「您的充值已入账！」
    → `depositOnly` 时关闭面板，否则切回 PAY（源项目 `confirm_deposit_done` 的行为）
  - 支付门户按 `kReleaseMode` 切 dev/prod（源项目用 `NODE_ENV`）；`clid` 现在会从后端响应持久化下来
    （补上了 `apiClientProvider.onClid` → `LocalStore.keyClid`）
- **有意不做（平台差异，代码里已注明）**：
  1. **iOS 内购 IAP**：源项目走 `uni.requestPayment(appleiap)` + `uni-pay` 原生插件；
     `inAppIos` 未配置时源项目本就不显示该分支，故迁移版同样不显示。待真正出 iOS 产物时再补。
  2. **uniCloud `unipay-co` 云函数**：uni-app 云空间专有；源项目本身有 payPortal 链接的 fallback，只用它。
  3. **「连接钱包」按钮**：源项目仅在「PC 且检测到 `window.ethereum`」时显示，需要 MetaMask 探测（条件导入 js_interop）。
- **实测**：
  - `dart run tool/check_socket.dart` **PASS**：连 ws → 认领连接 → B 给 A 发消息 → A 收到
    `skevent=MIA_SENT` 推送（用 `send_mia` 当推送源，**不产生邮件副作用**；
    `RECHARGE_SUCCESS` 只能由支付门户的 `System/deposit_callback`（sysapi）触发且会真发邮件，故不自检）
  - `dart run tool/check_deposit.dart` **PASS**：`get_current_balance` 字段齐 → `coinToTUC`(USDT/CNY) /
    `depositBonusRate` 齐 → 按源项目公式算出「10 CNY = 136.9863¢ + 6.8493¢；10 USDT = 1000¢ + 50¢」
  - 视觉 / 交互（CDP，手机 500，用带余额的临时用户）：
    资金页点「Deposit」→ 面板（USDT 默认：金额步进 10、换算 =1000¢、赠送 50、Polygon / Ethereum 链、
    地址二维码、Copy/Share、Check Balance、客服）→ 点币种 → 币种表（₮ USDT / ¥ Chinese Yuan）
    → 选 CNY → CNY 分支（WxPay 渠道、**二维码已渲染**、生产门户链接 `pay.yuanjinx.com/?coin=cny&provider=wxpay&appkey=…`）
    → 点「Check Balance」→ 红字「充值尚未到账…请联系客服」
- **踩坑（两个，都值得记）**：
  1. **`Random().nextInt(999999999999)` 抛 `RangeError`**（Dart 的 `nextInt` 上限是 2^32）——
     我照抄了源项目 `String(Math.random()).substring(2,14)` 的「12 位随机数」意图，却用错了 API。
     后果很隐蔽：CNY 分支在 build 时抛异常 → 面板渲染成灰屏/空二维码，我一度误判成「CDP 点击坐标不准」。
     现在改为逐位生成 12 个数字。
  2. **弹层会自动滚动**：`showModalBottomSheet` 打开后，Flutter 会把第一个可聚焦控件（链下拉）
     滚入视野，导致弹层内容整体上移约 90px —— 所以按静态截图上的坐标去点「币种」会点到「链」。
     排查后按 `-90px` 点击即命中（币种表正常弹出）。以后验这类面板，先点一次再按新截图定位。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功（含实时通道与充气面板）。

### 资金域（第三批/收官）· 提现页面组 + 修源项目实名闸门笔误

- **先修源项目（老板指示「两边一起修」）**：`pex-user-uniapp/pages/umyFundChannelWithdraw.vue`
  的实名闸门写的是 `wo.ss.User.onlineUser.kycStatusL1`，但用户对象上的字段其实是 **`kycStateL1`**；
  不存在的字段恒为 `undefined !== 'PASSED'` → **任何用户点提现都会被「请先完成实名认证」挡住、
  永远提交不出去**。已改为 `kycStateL1`（源项目 commit `bbbfed64`，只提交这一个文件，
  老板正在编辑的 `aimemo/productLens.md` 未动）。
- **Flutter 侧四件套**：
  - `widgets/part_fund_channel_card.dart`：渠道卡片 = 货币 + 各字段明细（`inCard` 的才显示，
    链字段显示链名）+ 底部「删除 / 提现」操作行（`toWithdraw` 时隐藏）；
    删除走确认弹窗 → `delete_payto_channel` → 从 `onlineUser.paytoChannels` 移除
  - `pages/umy_fund_channel_page.dart`：渠道列表 + 「新建渠道」入口；点卡片进提现页
  - `pages/umy_fund_channel_create_page.dart`：**配置驱动的表单**——源项目模板里写死了
    TUC/USDT/CNY/USD/EWALLET 五个分支，但 `paytoCoinSet` 里只有 TUC（其余是死分支），
    故迁移版按配置渲染（链 → 下拉、服务商 → 下拉、其余 → 输入框），并保留各币种的格式校验
    （链地址 `0x`+40 位十六进制、EWALLET 邮箱、法币数字）；建成功后按源项目逻辑
    「首个渠道 → 去列表页，否则返回上一页」
  - `pages/umy_fund_channel_withdraw_page.dart`：渠道卡片 + 金额（下限/余额提示）+ 换算预览 +
    实名闸门 + 提交；成功后本地扣余额 → 成功弹窗 → 返回
- **新增**：`core/i18n/payto_coins.dart`（`paytoCoinSet` + `defaultPaytoChannel`）、
  `user_api.addPaytoChannel/deletePaytoChannel/requestWithdrawal`、`envar.withdrawAmountMin`（预置层 1000）；
  路由三个都注册在 `route_common.dart`；`umyFund` 的「提现」按钮**从占位页改成了真页**
  （有渠道 → 渠道列表，无渠道 → 新建渠道，与源项目 `request_withdraw` 一致）
- **实测**：
  - `dart run tool/check_withdraw.dart` **PASS**：建渠道（读回确认 coinType/链/地址/appkey）→
    三个拒绝分支（渠道不存在 / 低于下限 / 超出余额，都 FAILED 且**不发信**）→ 临时加余额后
    正常提交 SUCCESS 且**余额正好少 1000** → 删渠道复查 `lifeState=DELETED` → 清理测试数据。
    **注意：成功提现那一步后端会真发一封邮件给值班邮箱**（源项目行为），本工具只跑一次。
  - 视觉 / 交互（CDP，手机 500，用未实名的临时用户）：
    资金页点「Cashout」→（无渠道）新建渠道页（货币 TUC / 区块链警告 + Polygon / 钱包地址）→
    填地址提交 → 渠道列表（卡片 + Delete/Cashout + 「+ New」）→ 点卡片 → 提现页
    （渠道卡片无操作行、Minimum 1000 / Balance、换算预览）→ 输入 1000 提交 →
    **实名闸门弹窗**（Cancel / Verify Identity）→ 回列表点「Delete」→ 删除确认弹窗
- **两处如实说明**：
  1. **换算预览对 TUC 显示 0**：源项目的 `coinToTUC` 里**没有 TUC**（只有 USDT/USD/EUR/IAP/CNY/JPY/HKD），
     所以唯一的 TUC 渠道算出来恒为 0 —— 源项目行为一致（同样显示 0），不是迁移引入的问题。
  2. **提现金额必须严格小于余额**（源项目 `Number(withdrawAmount) < balanceTUC`），
     即**无法把余额一次性全部提走**。迁移版保持一致（已在代码注明）。
- **踩坑**：卡片最初忘了整卡点击（源项目是在列表页外包一层），导致点卡片没反应；
  已让卡片自身承接 `onTap`（`onCashout` 只是显式入口）。
- **验证**：`flutter analyze` 0 问题；Babelyx Web 构建成功。
- **里程碑**：**资金域（充值 / 余额 / 流水 / 提现渠道 / 提现）全部迁完**。

### 零散组件结案 + AI 聊天消息操作菜单 + Web 全量冒烟

- **先回答老板的问题**：是的，目前**全部是 Web 平台**——三个品牌都用 `flutter build web`
  出产物、用 headless Chrome 在 `localhost:8090` 验证；原生端（iOS/Android/macOS/Windows）
  还没做任何构建配置（ledger 里只剩那一项）。
- **零散组件：逐个查源项目实际引用后定论**（不是「都做一遍」）：
  - **死代码 10 个**（标 `[-]`）：`partNavilink` / `partTooltip` / `partBreathingDot` /
    `partMenuCircle` / `partLangPicker` / `partLangSelect` / `partCoinPicker` / `partTexturlReader`
    全库**无任何引用**；`partLinkview` 只被 `homePortal.vue` 里一处**已注释掉**的代码提到；
    `partDev` 只渲染 `<view v-if="false">`
  - **配置未启用 1 个**：`partSoundRecorder`（语音输入）——`creationSpeak`/`miaSpeak`/`commentSpeak`
    全为 false，源项目本身也不显示
  - **真缺口 1 个**：`partMenuRing`（AI 聊天里点消息气泡弹操作菜单）→ **本轮补齐**
- **AI 聊天消息操作菜单**（`part_aichat.dart`，对应 `partMenuRing` + `act_on_message`）：
  - 触发改为**点击气泡**（源项目是 click；长按也保留给触屏）
  - 动作按内容/品牌过滤：`删除`/`拷贝` 恒有，`转存` 仅 Babelyx，`朗读` 需有文字，`预览` 需有图片
  - 行为逐一对齐源项目：拷贝按 markdown 拼媒体、朗读只送文字段并扣 `tucCost`/`sumOutTTS`、
    删除走确认框 + `delete_chat_item`、预览摊成图片画廊、转存并入创作草稿并问「去创造 / 留在AIGC」
  - 形态差异（已在代码注明）：源项目是**径向环形菜单**，迁移版改为**底部操作表**（Web/桌面更好点）
- **顺手修了两个 API 参数名 bug**（一直没人用到，这次接线才暴露）：
  `text_to_speech` 后端要 `inputText`（原写 `text`）、`delete_chat_item` 后端要
  `chatUuid`+`chatTimeUnix`（原传整条 `chatItem`）。
- **新增依赖** `audioplayers`（朗读播放；Web/原生都支持）。
- **新增工具 `tool/webSmoke.js`**：按一批路由逐个打开，收集 console error / 未捕获异常，
  并用截图体积粗判白屏。**它立刻抓到一个真 bug**：
  - `umyKyc` 抛 `LateInitializationError` —— 我早前把那页的 `_idType`/`_land` 写成 `late`，
    却在「自动登录完成后」的异步回调里赋值，首次 build 早于回调就崩（上次截图侥幸没触发）。
    已改为**同步默认值 + 可空字段兜底**。
- **Web 全量冒烟结果**：
  - Babelyx 产物 **29 个路由全部 OK**（含 `showCreator` / `showCreation` / `umyFundChannelWithdraw` /
    `showWebview` / `umyKyc` 等带参路由）
  - Agidin 产物 15 个路由（含 `midAgidin` / `menuAipp` / `menuAippAichat`）全部 OK
- **AI 朗读（TTS）验证受限**：`tool/check_tts.dart` 自检显示后端返回 `_state=ERROR _msg="Connection error."`
  —— 本地没有可用的 OpenAI 出口/密钥。**关键是它没有返回 `ERROR_MISSING_INPUT`**，
  说明 `inputText` 参数名修复是生效的；音频播放与扣费这两步本地无法端到端验证（已如实记录）。
  同理，AI 聊天的「发消息 → 回复」在本地也通不了（同一个 OpenAI 出口问题），
  故操作菜单是用**直接写入 `ai_chat` 的历史消息**来验证的。
- **验证**：`flutter analyze` 0 问题；Babelyx + Agidin 两个 Web 产物均构建成功。

### 添加 Web 生产部署脚本 + 找齐 Cloudflare 项目名（2026-10-04）

- 在 `package.json` 新增 9 个脚本，避免生产构建误用 localhost 后端：
  - `build:web:prod:<agidin|babelyx|tryapp>`：`API_BASE=https://pexserver.tic.cc` 的生产构建
  - `deploy:web:<brand>`：`wrangler pages deploy build/web --project-name=<名>`
  - `release:web:<brand>`：先 prod 构建再部署（一步到位）
- 从 uniapp 源 `AK*/framework/appenv.json` 找齐三个品牌的 Cloudflare Pages 项目名：
  agidin=`user-agidin-com`(agidin.com)、babelyx=`user-babelyx-com`(babelyx.com)、tryapp=`tryapp-user`(tryapp-user.pages.dev)
- 部署记录整理进 `aimemo/deployWeb.md`（含后端地址、构建/部署命令、覆盖旧网页的提醒）。
- 未提交（待老板确认后一起 commit，或本次直接提交）。

### 配置 iOS / Android 原生构建（flavors）（2026-10-04）

- 老板确认 iOS 做成三品牌独立包名，与 Android flavors 对齐。
- **Android**：`android/app/build.gradle.kts` 早就有三品牌 `productFlavors`（applicationId + app_name）。
  - `AndroidManifest.xml` 补了权限：INTERNET / CAMERA / READ_MEDIA_IMAGES·VIDEO·AUDIO / READ_EXTERNAL_STORAGE(≤32)。
  - 本机无 Android SDK，未实编译，仅做了配置正确性核对。
- **iOS**：从零配齐 flavors（用 `tool/_gen_ios_flavors.py` 生成，已在文档注明勿重复跑）：
  - `ios/Flutter/<Brand>-Debug/Release.xcconfig`：include Pods 配置 + Generated.xcconfig，覆盖 bundle id / PRODUCT_NAME。
  - `project.pbxproj`：Project / Runner / RunnerTests 三套列表各加 `Debug-<brand>`/`Release-<brand>` 构建配置（踩坑：生成时 `name =` 字段漏改，导致 `xcodebuild -list` 不枚举，已修）。
  - `xcshareddata/xcschemes/<brand>.xcscheme`：共享 scheme。
  - `Info.plist`：`CFBundleDisplayName`/`CFBundleName` 改 `$(PRODUCT_NAME)` 随 flavor 变；加相机/相册权限描述。
- **package.json** 新增 12 个原生脚本：`build:android:*`/`build:android:prod:*`(appbundle) + `build:ios:*`(模拟器)/`build:ios:prod:*`(真机)。
- **验证（本机 Xcode 26 可编译）**：`flutter build ios --flavor agidin -t lib/main_agidin.dart --simulator` 与 `babelyx` 均成功，产出 `Agidin.app`/`Babelyx.app`，bundle id=`cc.tic.agidin/babelyx`、应用名=Agidin/Babelyx、权限描述已注入。
- **待老板在凭据机器上做**：iOS 签名（Team ID + provisioning，模板 `DEVELOPMENT_TEAM=37KQR6645B` 是占位）；Android 签名（release 现用 debug key）；三品牌图标替换。
- 文档：`aimemo/deployNative.md`。
