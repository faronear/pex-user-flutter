> [已停用 2026-10-07] 本文件已归档并入 `../../aimemo/`（见 `../../aimemo/README.md` 的来源对照表），请勿再更新。原内容暂时保留，待清理。

This file provides guidance for AI agents when working with code in this repository.

## Overview

This codebase `pex-user-flutter` is meant to migrate the other repo `pex-user-uniapp` to be based on flutter technologies.

与本目录 pex-user-flutter/ 平行的，是 productX/pex/ 目录下的其他协作项目：

- pex/pex-server-torm: 后台服务器，API service
- pex/pex-user-uniapp: 前端应用，基于 uni-app 技术。用一套自行研发的代码架构，支持了2个不同的 app 品牌： Agidin 和 Bableyx。这套代码架构，支持自行开发的简易、内嵌的多语言系统、手机端和桌面端的不同页面布局、桌面端的响应式UI。
- pex/pex-contract-hardhat: Babelyx 所用到的 NFT 智能合约。
- pex/pex-user-uniappx: 一开始试图用 uni-app X 技术来升级，达到原生应用效果，但是中途遇到迁移困难，放弃了。
- pex/pex-web-md: 面向用户的文档。

另外，前后端都引入了一些自行开发的公用库，可在 productX/base/opx/ 下找到源代码，可通过 npm install git+https://git.tic.cc/opx/Xxx 引入到 package.json 里。

在开发过程中，你可以参考 productX/einz/ ，因为老板最近开发了这个基于 flutter 的 einz 项目，安装了全套的编译、构建工具链（flutter, dart, jdk, XCode 26.3, Android Studio, Github CI），形成了一些 flutter 相关的经验和使用习惯，你可以直接复用。

### 迁移的主要动机：真正的原生 App

pex-user-uniapp 基于 uni-app，其 iOS / Android App 本质上仍是**web 技术栈**（运行在 webview / 渲染引擎上），性能、原生体验和能力受限。

本项目迁移到 flutter 的**核心目标**，就是编译出**真正的原生 App**，一套代码同时生成 Web、iOS、Android、MacOS、Windows 端。

开发环境:

- 本台 iMac 为主力，安装有全套工具链（VSCode, flutter, dart, XCode, Android Studio)，另一台 macbook air 也会经常使用，但没有安装 XCode 和 Android Studio。
- VS Code 里开启了后台服务端: [http://localhost:7739](%E2%80%B8http://localhost:6173)
- HBuilderX 里开启了前端 pex-user-uniapp 的预览: [http://localhost:8080](http://localhost:8080) ，同时也有在线版本 [https://u.agidin.com](%E2%80%B8https://u.agidin.com) 和 [https://u.babelyx.com](%E2%80%B8https://u.babelyx.com) You can use Playwright or Puppeteer to open these URLs to make sure that migrated pages works as expected.

实现效果请尽可能与 pex-user-uniapp 保持一致。每个页面的视觉效果也应当保持一致。

先建立框架，然后实现第一个 home-portal 页面，验证可行性后继续实现所有页面。
