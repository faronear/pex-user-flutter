# 后端待办（backendTodo）

> 由前端迁移过程中发现、**需要后端配合**的事项。
> 原则：前端迁移优先，后端改动集中清账；以下均**不阻塞**前端继续推进（除注明外）。
> 最后更新：2026-09-29

## 待办

### B1. AI 模型连接过时（老板已知，优先级最高）
- **现象**：`Aimodel/reply_challenge` 返回 `_state: ERROR` / `_msg: Bad request for dependent service.`
- **影响**：所有 AI 对话无法真正出结果（前端契约本身正确，已用 `tool/check_ai_flow.dart` 验证）
- **结论**：老板 2026-09-29 明确 —— **先完成前端迁移，再统一更新后端**；当前很多模型连接是错的

### B2. `first_touch` 支持 304（性能优化，非阻塞）
- **现状**：响应已带 `ETag: W/"6527-…"` 与 `Content-Encoding: gzip`；
  实测两次响应**逐字节相同**、ETag **稳定**。
- **问题**：带 `If-None-Match` 重发仍返回 **200**（未产生 304）。
- **推测原因**：服务端为手写响应（`res.end(...)`），未走 Express 的 freshness 判断。
- **收益**：重复启动的配置传输降为 0。响应体 25.3 KB（gzip 7.3 KB），
  1 万 DAU × 5 次启动/天 ≈ 500 MB/天 → 有 304 后近似 0。
- **建议**：把该接口的响应改为走 Express 的 `res.json()` / `res.send()`，或显式比对 `If-None-Match` 后返回 304。

### B3. 后端启动崩溃：缺少 `envar/versionCode-*` 文件（**曾阻塞，已定位**）
- **现象**：后端启动即崩，日志尾部：
  `Error: Cannot find module './versionCode-web-AKAGIDIN'`（require stack: `envar/envar-config.js:1052` → `wo-base-envar/envar-tool.js` → `server.js:74`）
  随后 `[nodemon] app crashed - waiting for file changes before starting...`
- **根因**：`envar-config.js` 里的
  ```js
  function requireVersion (versionFile) {
    if (!inUniapp) { delete require.cache[require.resolve(versionFile)]; return require(versionFile) }
    return undefined            // 客户端不 require，版本号由后端下发
  }
  // 调用：requireVersion('./versionCode-web-AKAGIDIN')
  ```
  **服务端**会 `require()` 该模块 → 后端 `envar/` 目录下必须存在对应文件。当前缺失。
- **素材**：前端 `pex-user-uniapp/<brand>/cfstore/` 下已有：
  - `AKAGIDIN`：`versionCode-{aab-GPLAY,apk,ipa,web}-AKAGIDIN.json`（值为 `26082304` 等）
  - `AKBABELY`：对应 4 个（`versionCode-web-AKBABELY.json` = `26082311`）
  - `AKTRYAPP`：**无**（若要跑 TRYAPP 需先生成）
- **修复**：把这批文件拷进后端 `envar/`。`require('./x')` 会依次尝试 `.js`/`.json`，**直接拷 `.json` 即可**。
  最小修复只需 `versionCode-web-AKAGIDIN.json`（崩溃点）；建议四类一并拷。
- **注意**：后端运行目录与我的工作目录是**两份拷贝**
  （老板运行的 `/Users/Shared/product-产品/pex/pex-server-torm`，我这边是 `/Volumes/repodisk/productX/pex/pex-server-torm`），
  该路径我无法访问，需老板侧执行拷贝。
- **同类历史**：2026-08-23 AKAIZOIC→AKAGIDIN 迁移后也发生过同类 MODULE_NOT_FOUND（见 uniapp worklog）。
- **正常流程**：`deploy` 会把前端 `${brand}/cfstore/versionCode-*` 拷到后端 `envar/`；本次显然未跑。

## 已评估但决定不做

### B9. 让后端把「客户端专属配置块」一并下发给客户端（方案 A）—— **不采纳**
- **背景**：源项目 `envar-config.js` 里有一批块受 `inUniapp` 控制，只在**客户端上下文**求值；
  服务端求值时 `inUniapp === false`，因此**永不下发**（如 `tucSymbol`、`pactDict`、`uiStatDict`、
  `Creation`/`Creator`/`Market` 词典、`banChina`、三个扩展名列表、`baseTypeSms`、`waitingSeconds`、
  `registerReward`、`inviteeReward`、`bgTextCover` 等）。
- **曾提议**：让后端在收到带 `_clientInfo` 的请求时把这些块也下发（换成"单一真源"）。
- **老板 2026-09-29 澄清设计意图后撤回**：这批块的**定位本来就是「前端预置的默认值」**，
  由后端在需要时**覆盖**。让后端下发它们与设计相悖。→ 改为**前端生成式本地快照**（方案 E 第 1 层）。
