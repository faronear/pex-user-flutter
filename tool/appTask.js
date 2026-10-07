#!/usr/bin/env node
/**
 * `app-*` 系列 npm 脚本的统一入口（跨平台）。
 *
 *   npm run app-web-build-prod                      # 默认 agidin
 *   APP=babelyx npm run app-apk-build-prod
 *   EMU=ip16pro@26.3 npm run app-ios-run-local
 *   API_BASE=https://pexserver.tic.cc npm run app-ios-run-local
 *   npm run app-ios-build-local -- --dry-run        # 只打印命令，不执行
 *
 * **为什么不用 shell 写**：npm 默认用 `/bin/sh`，而 `${VAR:-default}`、`$(...)`、`[[ ]]`、
 * `VAR=x cmd` 这些都是 bash/posix 专有写法，换机器、换 `script-shell` 就会挂。
 * 这里统一由 Node 解析品牌与环境，再 spawn 出真实命令（不经过 shell）。
 */

const { spawn, spawnSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const APP_DEFAULT = 'agidin';
const API_BASE_LOCAL = 'http://localhost:7739';
const API_BASE_PROD = 'https://pexserver.tic.cc';
const WO_SCRIPTS = path.join('node_modules', 'wo_scripts');

/** 品牌相关的取值集中在这张表，脚本里不再出现 `if app == ...` */
const brands = {
  agidin: { webPort: '8081', iosBundleId: 'cc.aizoi.app.dist.ios' },
  babelyx: { webPort: '8082', iosBundleId: 'faronear.babely.app.ios.dist' },
};

const app = (process.env.APP || APP_DEFAULT).toLowerCase();
const brand = brands[app];
if (!brand) {
  console.error(`❌ 未知品牌 APP=${app}，可用：${Object.keys(brands).join(' / ')}`);
  process.exit(1);
}

const dryRun = process.argv.includes('--dry-run');
const argv = process.argv.slice(2).filter((item) => item !== '--dry-run');
const command = argv[0] || '';
const extra = argv.slice(1);

const entry = `lib/main_${app}.dart`;
// macOS / Linux 沿用 /tmp（老板有查 /tmp/pex_flutter_ios_*.pid 的习惯），只给 Windows 兜底
const tmpDir = process.platform === 'win32' ? os.tmpdir() : '/tmp';
const apiBase =
  process.env.API_BASE || (command.endsWith('-prod') ? API_BASE_PROD : API_BASE_LOCAL);

// mac 上用 Edge 当 Chromium 跑（macbook air 没装 Chrome）；路径不存在就不设，交给系统默认
const edgePath = '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge';
const chromeExecutable =
  process.platform === 'darwin' && fs.existsSync(edgePath) ? edgePath : '';

/** 解析要打的那台 iOS 模拟器 UDID（不给 EMU 则打「当前已启动的那台」） */
function resolveUdid() {
  if (dryRun) return '<UDID>';
  // iOS 模拟器只在 macOS 上存在，这一步调共享包 wo_scripts 里的脚本
  const result = spawnSync('bash', [path.join(WO_SCRIPTS, 'emuUdidIos.sh'), process.env.EMU || ''], {
    encoding: 'utf8',
  });
  if (result.status !== 0) {
    console.error(result.stderr || result.stdout || '❌ emuUdidIos.sh 执行失败');
    process.exit(result.status || 1);
  }
  return (result.stdout || '').trim();
}

/** 前置步骤；dry-run 只打印。failHard=false 表示失败也继续（等价 shell 的 `;`） */
function runStep(cmd, args, { failHard = false } = {}) {
  if (dryRun) {
    console.log(`▸ ${[cmd, ...args].join(' ')}`);
    return;
  }
  const result = spawnSync(cmd, args, { stdio: 'inherit' });
  if (result.status !== 0 && failHard) process.exit(result.status || 1);
}

const flutter = (args, options) => ({ command: 'flutter', args, ...options });

const iosRunArgs = (udid) => [
  'run',
  '-d',
  udid,
  '--flavor',
  app,
  '-t',
  entry,
  '--dart-define',
  `API_BASE=${apiBase}`,
  '--pid-file',
  path.join(tmpDir, `pex_flutter_ios_${app}.pid`),
];

const commands = {
  'webserver-run-local': () =>
    flutter(['run', '-d', 'web-server', '--web-port', brand.webPort, '-t', entry, '--dart-define', `API_BASE=${apiBase}`]),
  'webapp-run-local': () =>
    flutter(['run', '-d', 'chrome', '-t', entry, '--dart-define', `API_BASE=${apiBase}`], {
      env: chromeExecutable ? { ...process.env, CHROME_EXECUTABLE: chromeExecutable } : undefined,
    }),
  'macos-run-local': () =>
    flutter(['run', '-d', 'macos', '-t', entry, '--dart-define', `API_BASE=${apiBase}`]),

  'web-build-local': () => flutter(['build', 'web', '--release', '-t', entry, '--dart-define', `API_BASE=${apiBase}`]),
  'web-build-prod': () => flutter(['build', 'web', '--release', '-t', entry, '--dart-define', `API_BASE=${apiBase}`]),
  'web-deploy-cf': () => ({ command: 'wrangler', args: ['pages', 'deploy', 'build/web', '--project-name', `user-${app}-com`] }),
  'web-serve-local': () => ({ command: 'python3', args: ['-m', 'http.server', '8090'], cwd: 'build/web' }),

  'apk-build-local': () => flutter(['build', 'apk', '--flavor', app, '-t', entry, '--dart-define', `API_BASE=${apiBase}`]),
  'apk-build-prod': () => flutter(['build', 'appbundle', '--flavor', app, '-t', entry, '--dart-define', `API_BASE=${apiBase}`]),

  'ios-build-local': () => flutter(['build', 'ios', '--flavor', app, '-t', entry, '--dart-define', `API_BASE=${apiBase}`, '--simulator']),
  'ios-build-prod': () => flutter(['build', 'ios', '--flavor', app, '-t', entry, '--dart-define', `API_BASE=${apiBase}`]),
  'ipa-build-prod': () =>
    flutter(['build', 'ipa', '--flavor', app, '-t', entry, '--dart-define', `API_BASE=${apiBase}`, '--export-options-plist', 'ios/ExportOptions-appstore.plist']),

  'ios-boot': () => ({ command: 'bash', args: [path.join(WO_SCRIPTS, 'emuBootIos.sh'), ...extra] }),
  'ios-run-local': () => flutter(iosRunArgs(resolveUdid())),
  'ios-run-local-new': () => {
    const udid = resolveUdid();
    // 先卸载旧包再装，避免新旧混淆；卸载失败无所谓（本来可能就没装），等价 shell 的 `;`
    runStep('xcrun', ['simctl', 'uninstall', udid, brand.iosBundleId]);
    return flutter(iosRunArgs(udid));
  },
};

if (!commands[command]) {
  console.error(`❌ 未知任务：${command || '(空)'}\n可用任务：\n  ${Object.keys(commands).join('\n  ')}`);
  process.exit(1);
}

const task = commands[command]();

if (dryRun) {
  console.log([task.command, ...task.args].join(' '));
  process.exit(0);
}

const child = spawn(task.command, task.args, {
  stdio: 'inherit',
  env: task.env || process.env,
  cwd: task.cwd || process.cwd(),
});
child.on('exit', (code) => process.exit(code || 0));
