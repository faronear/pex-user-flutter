# Web 部署（生产）

Flutter 产物是纯静态文件（`build/web/`），用 hash 路由无需 404 回退；后端 `server.js` 走 `cors()`（allow-all），新域名不受跨域限制。

## 后端地址
编译期 `--dart-define=API_BASE=` 决定连哪台后端：
- `http://localhost:7739` 本地（dev 脚本默认）
- `https://pexserver.tic.cc` 生产（`ApiEndpoint.production` 默认值）

## 构建
- 本地：`npm run build:web:<agidin|babelyx>`（API_BASE 写死 localhost）
- 生产：`npm run build:web:prod:<brand>`（API_BASE=https://pexserver.tic.cc）

## 部署（Cloudflare Pages，沿用 uniapp 旧 web 的项目名）
| 品牌 | Cloudflare 项目名 | 线上域名 |
|---|---|---|
| agidin | `user-agidin-com` | https://agidin.com |
| babelyx | `user-babelyx-com` | https://babelyx.com |

> 已下线品牌：tryapp 的 Cloudflare 项目 `tryapp-user`（`tryapp-user.pages.dev`）仍存在但本项目已不再构建/部署它，是否下线站点待定。

需要本机已装 `wrangler` 并登录（当前开发机未装，部署得在老板有凭据的机器上跑）：
- `npm run deploy:web:<brand>` → `wrangler pages deploy build/web --project-name=<上表>`
- 或一步到位：`npm run release:web:<brand>`（先 prod 构建再部署）

## 注意
- 部署会**覆盖**同名 Cloudflare 项目上现有的 uniapp 旧网页，上线前确认替换时机与 DNS。
- 别用 `build:web:*` 直接上生产（API_BASE 是 localhost，线上必挂）。
