/// 统一的 flutter 构建/运行入口：`node tool/flutterApp.js <command>`
///
/// 环境变量：
/// - APP=agidin|babely（默认 agidin）
/// - SERVERMODE=local|prod：run 类命令默认 local，build 类默认 prod；显式设置则覆盖。
///   local 时注入 `--dart-define API_BASE=http://localhost:7739`；
///   prod 时不注入，由代码里的 `ApiEndpoint.production` 兜底。
/// - API_BASE=... 显式覆盖（优先于 SERVERMODE 的默认值，prod 下也可用）
/// - REINSTALL=1（仅 run-ios）先卸载模拟器上的旧包
/// - DRYRUN=1 只打印将要执行的命令，不真正执行
const { spawn, spawnSync } = require('child_process')
const fs = require('fs')

const APP_DEFAULT = 'agidin'
const API_BASE_LOCAL = 'http://localhost:7739' // 对应 ApiEndpoint.localDev
const BUNDLE_BY_APP = { agidin: 'cc.aizoi.app.dist.ios', babely: 'faronear.babely.app.ios.dist' }
const RUN_COMMANDS = new Set(['run-webserver', 'run-webapp', 'run-macos', 'run-ios'])

const app = process.env.APP || APP_DEFAULT
const command = process.argv[2]
const serverMode = process.env.SERVERMODE || (RUN_COMMANDS.has(command) ? 'local' : 'prod')

const flutterArgs = ['-t', `lib/main_${app}.dart`]

// API_BASE：显式 env 优先；local 模式默认指向本地后台；prod 模式不传（代码默认值即生产地址）
const apiBase = process.env.API_BASE || (serverMode === 'local' ? API_BASE_LOCAL : undefined)
if (apiBase) flutterArgs.push('--dart-define', `API_BASE=${apiBase}`)

/** 执行命令；DRYRUN=1 时只打印 */
function run (file, args, options = {}) {
  const line = [file, ...args].join(' ')
  if (process.env.DRYRUN) {
    console.log(`[dryrun] ${line}`)
    return 0
  }
  return spawn(file, args, { stdio: 'inherit', ...options }).on('exit', c => process.exit(c || 0))
}

/** 找到 iOS 模拟器 udid（用 wo_scripts 里的脚本），失败则退出 */
function resolveIosUdid () {
  const u = spawnSync('bash', [`node_modules/wo_scripts/emuUdidIos.sh`, process.env.EMU || ''], { encoding: 'utf8' })
  if (u.status !== 0) {
    process.stderr.write(u.stderr || u.stdout || '')
    process.exit(u.status || 1)
  }
  return u.stdout.trim()
}

switch (command) {
  case 'run-webserver': {
    const port = app === APP_DEFAULT ? '8081' : '8082'
    run('flutter', ['run', '-d', 'web-server', '--web-port', port, ...flutterArgs])
    break
  }
  case 'run-webapp': {
    const env = { ...process.env }
    const edge = '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge'
    if (fs.existsSync(edge)) env.CHROME_EXECUTABLE = edge
    run('flutter', ['run', '-d', 'chrome', ...flutterArgs], { env })
    break
  }
  case 'run-macos':
    run('flutter', ['run', '-d', 'macos', ...flutterArgs])
    break
  case 'run-ios': {
    const udid = resolveIosUdid()
    const args = ['run', '-d', udid, '--flavor', app, ...flutterArgs, '--pid-file', `/tmp/pex_flutter_ios_${app}.pid`]
    if (process.env.REINSTALL) spawnSync('xcrun', ['simctl', 'uninstall', udid, BUNDLE_BY_APP[app]], { stdio: 'inherit' })
    run('flutter', args)
    break
  }
  case 'build-web':
    run('flutter', ['build', 'web', '--release', ...flutterArgs])
    break
  case 'build-apk':
    run('flutter', ['build', 'apk', '--flavor', app, ...flutterArgs])
    break
  case 'build-appbundle':
    run('flutter', ['build', 'appbundle', '--flavor', app, ...flutterArgs])
    break
  case 'build-ios': {
    // 本地构建给模拟器用，需 --simulator；正式构建不带
    const args = ['build', 'ios', '--flavor', app, ...flutterArgs]
    if (serverMode === 'local') args.push('--simulator')
    run('flutter', args)
    break
  }
  case 'build-ipa':
    run('flutter', ['build', 'ipa', '--flavor', app, ...flutterArgs,
      '--export-options-plist', 'ios/ExportOptions-appstore.plist'])
    break
  default:
    console.error(`用法: node tool/flutterApp.js <command>
command: run-webserver | run-webapp | run-macos | run-ios | build-web | build-apk | build-appbundle | build-ios | build-ipa
环境变量: APP=${app} SERVERMODE=${serverMode} API_BASE=${apiBase || '(prod 默认)'} EMU REINSTALL DRYRUN`)
    process.exit(1)
}
