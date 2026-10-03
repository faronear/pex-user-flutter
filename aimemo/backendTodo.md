# 后端待办（backendTodo）

> 由前端迁移过程中发现、**需要后端配合**的事项。
> 原则：前端迁移优先，后端改动集中清账；以下均**不阻塞**前端继续推进（除注明外）。
> 最后更新：2026-09-30

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

### B3. 【⚠️ 仅 MacBook Air，不适用于 iMac】后端启动崩溃：缺少 `envar/versionCode-*`

> **重要更正（老板指出）**：`/Users/Shared/productX/pex/...` 是 **MacBook Air** 的路径；
> 我们工作的 iMac 是 `/Volumes/repodisk/productX/pex/pex-server-torm`。
> 仓库经 **Seafile 同步**，`_logstore/` 里的日志会被**跨机器同步** ——
> 那条崩溃栈实际来自 **MacBook Air**，**不代表 iMac**。
>
> **在 iMac 本机核实**：`envar/` 下 11 个 versionCode 文件**全部齐全**（3 品牌 × web/apk/ipa/aab），
> 因此本条**不适用于 iMac**；且 `_logstore/pex-server-torm-dev.log` 的 mtime 为 8/23、内容含 Air 路径，
> 属同步产物，**不可用于诊断本机**。
>
> **教训**：`_logstore/` 的日志是同步文件，**跨机器不可信**；诊断本机问题必须看本机进程与终端输出。

- **现象**：后端启动即崩，日志尾部：
  `Error: Cannot find module './versionCode-web-AKAGIDIN'`（require stack: `envar/envar-config.js:1052` → `wo-base-envar/envar-tool.js` → `server.js:74`）
  随后 `[nodemon] app crashed - waiting for file changes before starting...`
- **根因**：`envar-config.js` 里的
  ```js
  function requireVersion(versionFile) {
    if (!inUniapp) {
      delete require.cache[require.resolve(versionFile)];
      return require(versionFile);
    }
    return undefined; // 客户端不 require，版本号由后端下发
  }
  // 调用：requireVersion('./versionCode-web-AKAGIDIN')
  ```
  **服务端**会 `require()` 该模块 → 后端 `envar/` 目录下必须存在对应文件。当前缺失。
- **素材**：前端 `pex-user-uniapp/<brand>/cfstore/` 下已有：
  - `AKAGIDIN`：`versionCode-{aab-GPLAY,apk,ipa,web}-AKAGIDIN.json`（值为 `26082304` 等）
  - `AKBABELY`：对应 4 个（`versionCode-web-AKBABELY.json` = `26082311`）
  - `AKTRYAPP`：源项目本就**无**，且该品牌已于 2026-10-03 下线，不再需要生成。
- **修复**：把这批文件拷进后端 `envar/`。`require('./x')` 会依次尝试 `.js`/`.json`，**直接拷 `.json` 即可**。
  最小修复只需 `versionCode-web-AKAGIDIN.json`（崩溃点）；建议四类一并拷。
- **注意**：后端运行目录与我的工作目录是**两份拷贝**
  （老板运行的 `/Users/Shared/productX/pex/pex-server-torm`，我这边是 `/Volumes/repodisk/productX/pex/pex-server-torm`），
  该路径我无法访问，需老板侧执行拷贝。
- **同类历史**：2026-08-23 AKAIZOIC→AKAGIDIN 迁移后也发生过同类 MODULE_NOT_FOUND（见 uniapp worklog）。
- **正常流程**：`deploy` 会把前端 `${brand}/cfstore/versionCode-*` 拷到后端 `envar/`；本次显然未跑。

## 环境事实（重要，省得下次再验证）

- **本机（iMac）上运行中的后端，就是我的工作目录这一份**：
  证据有二 —— ① 我改 `api/Creation.js` 存盘后，nodemon 自动重启、`7739` 短暂不可用后恢复；
  ② 我用 HTTP 新建的评论/用户，直接出现在
  `/Volumes/repodisk/productX/pex/pex-server-torm/_datastore/pex.sqlite.db` 里。
  → 因此**后端小修可即时生效、可即时验证**，不需要老板手动操作。
- 老板在 B3 里提到的 `/Users/Shared/productX/pex/pex-server-torm` 是本机 **`/Users/Shared` 下并不存在**
  （已实测：只有 adi/Adobe/Key-Base 等），那是 **MacBook Air** 的路径；两台机器靠 Seafile 同步，
  `_logstore/` 里的日志跨机器不可信。

## 已修

### B4. ✅ 事务内未 await 的并发写 → SAVEPOINT 计数错乱（2026-09-30 已修，commit `f51c129` @ pex-server-torm）

- **现象**：`delete_comment` 间歇性返回 `ERROR_FAILED_DELETE_COMMENT`；
  加诊断后拿到真实异常：**`SQLITE_ERROR: no such savepoint: typeorm_5`**
  （另一形态：`Transaction is not started yet...`）。失败时**写操作其实已提交**，
  于是前端按 `bok(_state)` 提示失败、刷新后数据却已变。
- **根因**：`api/Creation.js` 与 `api/User.js` 里有 **6 处 `wo.Mia.api.send_mia(...)` 没有 await**，
  且都位于 `wo.dataStore.transaction(async (txman) => {...})` 事务体内。
  `send_mia` 走 `wo.dataStore.getRepository(...)`，即**同一条 SQLite 连接上的另一个 query runner**；
  在事务未提交时就并发写，会打乱 TypeORM 的 SAVEPOINT 深度计数，
  导致**下一次**事务 commit 时 `RELEASE SAVEPOINT typeorm_N` 找不到对应 savepoint。
- **修复**：6 处统一改为 `await wo.Mia.api.send_mia({...}).catch((expt) => wo.ccerror(expt))`
  （`comment_creation` / `pay_to_fuel` / `pay_to_view` / `pay_to_hold` / `pay_to_own` /
  `DAD.sysapi.pass_kyc`）。顺序化后不再交错。
- **验证**：`dart run tool/check_creation_comments.dart` 修复前 3 次跑 1 成功 2 失败；修复后 **4/4 PASS**。
- **顺带受益**：`pay_to_view/hold/own/fuel`（前端 2C 片）原本也有同样的隐患。

## 已评估但决定不做

### B9. 让后端把「客户端专属配置块」一并下发给客户端（方案 A）—— **不采纳**

- **背景**：源项目 `envar-config.js` 里有一批块受 `inUniapp` 控制，只在**客户端上下文**求值；
  服务端求值时 `inUniapp === false`，因此**永不下发**（如 `tucSymbol`、`pactDict`、`uiStatDict`、
  `Creation`/`Creator`/`Market` 词典、`banChina`、三个扩展名列表、`baseTypeSms`、`waitingSeconds`、
  `registerReward`、`inviteeReward`、`bgTextCover` 等）。
- **曾提议**：让后端在收到带 `_clientInfo` 的请求时把这些块也下发（换成"单一真源"）。
- **老板 2026-09-29 澄清设计意图后撤回**：这批块的**定位本来就是「前端预置的默认值」**，
  由后端在需要时**覆盖**。让后端下发它们与设计相悖。→ 改为**前端生成式本地快照**（方案 E 第 1 层）。
