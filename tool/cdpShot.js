// 开发辅助工具：用 Chrome DevTools Protocol 打开页面、按坐标点击、截图。
//
// 为什么不用 `--screenshot` + `--virtual-time-budget`：
// 虚拟时间会让定时器立即触发，但**截图与弹窗首帧存在竞态**——
// 弹窗刚 push 的路由还没绘制，截到的就是旧画面（曾因此误判「弹窗没出来」）。
// 本脚本用真实时间等待，并可按顺序注入鼠标点击，适合验证弹窗/交互态。
//
// 用法：
//   node tool/cdpShot.js <url> <outPrefix> [step ...] [--w=500] [--h=800] [--wait=11000]
//   步骤：`x,y` = 点击该坐标；`type:文本` = 往当前焦点输入文本（通常接在点击输入框之后）
//   注意：坐标是 **CSS 像素**，不是截图上的设备像素（截图通常 dpr=2，要除以 2）！
// 例：
//   node tool/cdpShot.js "http://localhost:8090/#/menuUzone" /tmp/shot "142,31" "200,101"
//   node tool/cdpShot.js "http://localhost:8090/#/umyContact" /tmp/c "200,300" "type:你好"
//
// 依赖：Node 18+（自带 fetch 与 WebSocket）、macOS 上的 Google Chrome。
// 注意：CDP 的 `Input.dispatchMouseEvent` 坐标是 **CSS 像素**（不要乘 dpr）。
const { spawn } = require('child_process');
const fs = require('fs');

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const PROFILE_DIR = '/tmp/cdpShotProfile';
const PORT = 9412;

const argv = process.argv.slice(2);
const flag = (name, fallback) => {
  const hit = argv.find((a) => a.startsWith(`--${name}=`));
  return hit ? Number(hit.split('=')[1]) : fallback;
};
const positional = argv.filter((a) => !a.startsWith('--'));

const url = positional[0];
const outPrefix = positional[1] || '/tmp/cdpShot';
// 步骤：{kind:'click',x,y} 或 {kind:'type',text}
const steps = positional.slice(2).map((s) => s.startsWith('type:')
  ? { kind: 'type', text: s.slice(5) }
  : { kind: 'click', xy: s.split(',').map(Number) });
const width = flag('w', 500);
const height = flag('h', 800);
const waitMs = flag('wait', 11000);
const stepMs = flag('step', 2500);

if (!url) {
  console.error('用法：node tool/cdpShot.js <url> <outPrefix> [x,y | type:文本 ...]');
  process.exit(1);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function main() {
  // 每次清掉 profile：否则 service worker 会命中旧缓存，
  // 重建后的产物在截图里看不到变化（踩过一次）。
  try {
    fs.rmSync(PROFILE_DIR, { recursive: true, force: true });
  } catch (e) {}
  const chrome = spawn(CHROME, [
    '--headless=new',
    '--disable-gpu',
    '--no-sandbox',
    '--hide-scrollbars',
    `--remote-debugging-port=${PORT}`,
    `--window-size=${width},${height}`,
    `--user-data-dir=${PROFILE_DIR}`,
    'about:blank',
  ], { stdio: 'ignore' });

  let wsUrl = null;
  for (let i = 0; i < 40 && !wsUrl; i++) {
    await sleep(250);
    try {
      const list = await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json();
      const page = list.find((t) => t.type === 'page');
      if (page) wsUrl = page.webSocketDebuggerUrl;
    } catch (_) { /* 还没起来 */ }
  }
  if (!wsUrl) {
    console.error('FAIL  没拿到 DevTools target');
    chrome.kill();
    process.exit(1);
  }

  const ws = new WebSocket(wsUrl);
  let id = 0;
  const pending = new Map();
  ws.onmessage = (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.id && pending.has(msg.id)) {
      pending.get(msg.id)(msg.result);
      pending.delete(msg.id);
    }
  };
  const send = (method, params = {}) => new Promise((resolve) => {
    const mid = ++id;
    pending.set(mid, resolve);
    ws.send(JSON.stringify({ id: mid, method, params }));
  });
  await new Promise((r) => { ws.onopen = r; });

  await send('Page.enable');
  await send('Page.navigate', { url });
  await sleep(waitMs); // 等首屏 + 自动登录

  const shot = async (name) => {
    const res = await send('Page.captureScreenshot', { format: 'png' });
    const file = `${outPrefix}_${name}.png`;
    fs.writeFileSync(file, Buffer.from(res.data, 'base64'));
    console.log('shot', file);
  };
  await shot('0');

  for (let i = 0; i < steps.length; i++) {
    const step = steps[i];
    if (step.kind === 'click') {
      const [x, y] = step.xy;
      await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
      for (const type of ['mousePressed', 'mouseReleased']) {
        await send('Input.dispatchMouseEvent', {
          type, x, y, button: 'left', clickCount: 1,
        });
      }
    } else {
      // 往当前焦点插入文本（Flutter web 的输入框靠 key events 驱动）。
      await send('Input.insertText', { text: step.text });
    }
    await sleep(stepMs);
    await shot(String(i + 1));
  }

  ws.close();
  chrome.kill();
}

main().catch((e) => { console.error(e); process.exit(1); });
