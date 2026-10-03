// 开发辅助工具：按一批路由逐个打开页面，收集控制台报错/异常与白屏情况。
//
// 用法：
//   node tool/webSmoke.js <baseUrl> <passtoken> <route1> [route2 ...]
// 例：
//   node tool/webSmoke.js http://localhost:8090 "$TOKEN" homePortal menuUzone umyFund
//
// 说明：
// - 无 token（传 `-`）则以游客身份打开；
// - 每个路由打开后等 `--wait`（默认 6000ms），记录 console error / 未捕获异常；
// - 通过 `Page.captureScreenshot` 取一帧，按**非纯色像素比例**粗略判断是否白屏；
// - 结论行：`OK` / `ERR(n)` / `BLANK`。
const { spawn } = require('child_process');
const fs = require('fs');

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const PORT = 9291;
const PROFILE = '/tmp/pexSmokeProfile';
const WAIT_MS = Number(process.env.SMOKE_WAIT || 6000);

const [baseUrl, tokenArg, ...routes] = process.argv.slice(2);
if (!baseUrl || routes.length === 0) {
  console.error('用法：node tool/webSmoke.js <baseUrl> <passtoken|-> <route...>');
  process.exit(1);
}
const token = tokenArg === '-' ? '' : tokenArg;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  fs.rmSync(PROFILE, { recursive: true, force: true });
  const chrome = spawn(CHROME, [
    '--headless=new', '--disable-gpu', '--no-sandbox', '--hide-scrollbars',
    '--window-size=500,900', `--user-data-dir=${PROFILE}`,
    `--remote-debugging-port=${PORT}`, 'about:blank',
  ], { stdio: 'ignore' });

  let target = null;
  for (let i = 0; i < 40 && !target; i++) {
    await sleep(250);
    try {
      const list = await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json();
      target = list.find((t) => t.type === 'page' && !t.url.startsWith('chrome-extension'));
    } catch (_) { /* 还没起来 */ }
  }
  if (!target) { console.error('FAIL  没拿到 DevTools target'); chrome.kill(); process.exit(1); }

  const ws = new WebSocket(target.webSocketDebuggerUrl);
  let id = 0;
  const pending = new Map();
  let errors = [];
  ws.onmessage = (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg.result); pending.delete(msg.id); return; }
    if (msg.method === 'Runtime.consoleAPICalled' && msg.params.type === 'error') {
      const text = msg.params.args.map((a) => a.value ?? a.description ?? '').join(' ').slice(0, 200);
      // 忽略与本项目无关的噪音
      if (!/gles2|gl_utils|WebGL|swiftshader|favicon/i.test(text)) errors.push(text);
    }
    if (msg.method === 'Runtime.exceptionThrown') {
      errors.push(('未捕获异常: ' + (msg.params.exceptionDetails.exception?.description || msg.params.exceptionDetails.text || '')).slice(0, 200));
    }
  };
  const send = (method, params = {}) => new Promise((resolve) => {
    const mid = ++id;
    pending.set(mid, resolve);
    ws.send(JSON.stringify({ id: mid, method, params }));
  });
  await new Promise((r) => { ws.onopen = r; });
  await send('Runtime.enable');
  await send('Page.enable');

  const results = [];
  for (const route of routes) {
    errors = [];
    const url = token
      ? `${baseUrl}/__seed.html?t=${encodeURIComponent(token)}&p=${encodeURIComponent(route)}`
      : `${baseUrl}/#/${route}`;
    await send('Page.navigate', { url });
    await sleep(WAIT_MS);

    let verdict = 'OK';
    if (errors.length) verdict = `ERR(${errors.length})`;

    // 粗略白屏判断：截图里出现足够多“非纯色”像素就算渲染出来了
    try {
      const shot = await Promise.race([
        send('Page.captureScreenshot', { format: 'png' }),
        sleep(8000).then(() => null),
      ]);
      if (shot) {
        const buf = Buffer.from(shot.data, 'base64');
        const size = buf.length;
        // PNG 压缩后过小说明基本是纯色（Flutter web 画布渲染后会明显变大）
        if (size < 15000) verdict = verdict === 'OK' ? 'BLANK' : `${verdict}+BLANK`;
      }
    } catch (_) { /* 截图失败不影响结论 */ }

    results.push({ route, verdict, errors: [...errors] });
    console.log(`${verdict.padEnd(14)} ${route}`);
    for (const e of errors.slice(0, 2)) console.log(`                 ↳ ${e}`);
  }

  const bad = results.filter((r) => r.verdict !== 'OK');
  console.log('');
  console.log(bad.length === 0
    ? `PASS  ${results.length} 个路由全部正常`
    : `注意  ${bad.length}/${results.length} 个路由有问题：${bad.map((b) => b.route).join(', ')}`);

  chrome.kill();
  process.exit(0);
})();
