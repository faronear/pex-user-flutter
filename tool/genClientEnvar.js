// 生成「客户端本地预置配置」（方案 E 第 1 层）。
//
// 目的（老板澄清后的定位）：
//   1) 客户端专属块 —— 服务端**永不**下发（受 `inUniapp` 控制，服务端求值时恒为 false），
//      如 pactDict / uiStatDict / Creation / 扩展名列表 / tucSymbol 等，必须前端预置；
//   2) 首屏在 first_touch 返回前就已渲染，需要一份**稳定**的默认值避免空白闪烁。
//
// 做法：在 node 里模拟客户端上下文（inUniapp=true）求值 envar-config.js，
//       与后端 first_touch 实际下发的 envarBase 做**差集**，得到「客户端专属」键；
//       再按品牌合并 AK* 块并删除品牌键（与源项目 App.data.js 一致）。
//
// 输出：assets/clientEnvar.json = { "AKAGIDIN": {...}, "AKBABELY": {...} }
//
// 运行：node tool/genClientEnvar.js [baseUrl]

const fs = require('fs');
const path = require('path');
const http = require('http');

const UNIAPP_DIR = '/Volumes/repodisk/productX/pex/pex-user-uniapp';
const OUT_FILE = path.join(__dirname, '..', 'assets', 'clientEnvar.json');
const BASE_URL = (process.argv[2] || 'http://127.0.0.1:7739').replace('localhost', '127.0.0.1');
const APPKEYS = ['AKAGIDIN', 'AKBABELY'];

function requestFirstTouch(baseUrl, appkey) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      _clientInfo: {
        appkey,
        lang: 'enUS',
        uniPlatform: 'app',
        deviceType: 'phone',
        osName: 'ios',
        webDomain: 'localhost',
      },
      _passtoken: '',
    });
    const req = http.request(
      {
        host: new URL(baseUrl).hostname,
        port: new URL(baseUrl).port,
        path: '/api/User/first_touch',
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
      },
      (res) => {
        let data = '';
        res.on('data', (c) => (data += c));
        res.on('end', () => {
          try {
            resolve(JSON.parse(data).envarBase || {});
          } catch (e) {
            reject(e);
          }
        });
      },
    );
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function main() {
  // 1) 客户端上下文求值 envar-config.js
  globalThis.uni = {
    getSystemInfoSync: () => ({
      uniPlatform: 'app',
      deviceType: 'phone',
      osName: 'ios',
      browserName: '',
      appVersionCode: 26092900,
      statusBarHeight: 44,
      windowWidth: 414,
    }),
  };
  globalThis.getApp = () => ({});
  const mod = require(path.join(UNIAPP_DIR, 'envar-config.js'));
  const clientEnvar = typeof mod === 'function' ? mod() : mod;

  // 2) 与服务端实际下发做差集 → 客户端专属键
  //    后端未启动时回退到缓存文件（tool 目录或 /tmp），保证生成器可离线运行。
  let serverEnvar = {};
  try {
    serverEnvar = await requestFirstTouch(BASE_URL, 'AKAGIDIN');
    fs.writeFileSync('/tmp/pex_firstTouch_cache.json', JSON.stringify({ envarBase: serverEnvar }), 'utf8');
    console.log('差集基准：实时拉取后端');
  } catch (e) {
    const cached = fs.existsSync('/tmp/pex_firstTouch_cache.json')
      ? '/tmp/pex_firstTouch_cache.json'
      : '/tmp/ft.json';
    if (fs.existsSync(cached)) {
      serverEnvar = JSON.parse(fs.readFileSync(cached, 'utf8')).envarBase || {};
      console.log('差集基准：缓存（后端未启动）→', cached);
    } else {
      throw new Error('后端未启动且无缓存，无法计算差集: ' + e.message);
    }
  }
  const clientOnlyKeys = Object.keys(clientEnvar).filter(
    (k) => !(k in serverEnvar) && !APPKEYS.includes(k),
  );

  // 3) 按品牌合并 AK* 块并删除品牌键（对齐 App.data.js）
  const out = {};
  for (const appkey of APPKEYS) {
    const merged = {};
    for (const k of clientOnlyKeys) merged[k] = clientEnvar[k];
    if (clientEnvar[appkey]) Object.assign(merged, clientEnvar[appkey]);
    for (const k of APPKEYS) delete merged[k];
    // 稳定标量：品牌名（服务端也会发，但预置可避免首屏闪烁）
    merged.tucSymbol = clientEnvar.tucSymbol;
    merged.callnames = clientEnvar.callnames;
    out[appkey] = merged;
  }

  fs.writeFileSync(OUT_FILE, JSON.stringify(out, null, 1), 'utf8');
  const size = fs.statSync(OUT_FILE).size;
  const zlib = require('zlib');
  const gz = zlib.gzipSync(fs.readFileSync(OUT_FILE)).length;
  console.log('客户端专属键（' + clientOnlyKeys.length + '）:', clientOnlyKeys.join(', '));
  console.log('输出:', OUT_FILE);
  console.log('体积:', size, 'bytes =', (size / 1024).toFixed(1), 'KB  | gzip', (gz / 1024).toFixed(1), 'KB');
}

main().catch((e) => {
  console.error('生成失败:', e && e.message ? e.message : e);
  if (e && e.stack) console.error(e.stack.split('\n').slice(0, 6).join('\n'));
  process.exit(1);
});
