# 老板画像（userProfile）

> 对老板的背景、习惯、偏好的观察总结，按需补充。

## 沟通风格

- 使用简体中文交流。
- 直接、简洁地下达任务，期待 AI 主动核实歧义、提出选项后再执行。
- 重视先对齐计划再动手（会亲自编辑 `aimemo/` 文档来表达意图，例如直接在 `productLens.md` 写入"先建框架 → 先做 homePortal → 再铺开"的指令）。

## 项目角色

- 独立（在 agents 协助下）运营多个品牌 App：Agidin（爱奇点）/ Babelyx（巴贝历）等（TRYAPP/远近星空已于 2026-10-03 下线）。
- 主力设备 iMac（VSCode + flutter + Xcode 26.3 + Android Studio）；另有 macbook air（无 Xcode/Android Studio）。
- 与多个配套仓库协作：`pex-server-torm`（后端）、`pex-contract-hardhat`（合约）、`pex-web-md`（文档）、`base/opx/*`（自研库）、`einz`（Flutter 经验参考）。

## 技术偏好

- 命名规范：见 `AGENTS.md`（CamelCase / camelCase / UPPERCASE / kebab-case 分层；目录文件名主规则 camelCase；存量代码不强制迁移，新增代码遵循）。
- 偏好有意义的完整单词命名，反对 `A, B, i, k` 这类单字母。
- 每完成一次修改并验证成功，自动 git commit（不自动 push，等明确要求）。
- 重视跨 session / 跨模型 / 跨设备的工作连续性，为此维护 `aimemo/` 记忆空间。
- 对已有可复用资产（如 `einz` 的 Flutter 工具链与工程习惯、线上站点）倾向直接复用。

## 决策记录（本项目）

- 2026-09-29：迁移策略 = 垂直切片先行；状态管理 = Riverpod；品牌 = 认可 flavors 单仓方案（不排除未来独立成仓）；首个功能域 = 账户/登录注册；首发验证页 = `homePortal`。
