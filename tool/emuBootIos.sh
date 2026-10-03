#!/usr/bin/env bash
# 启动 iOS 模拟器 —— 「选哪一台」的复杂度和灵活性都集中在这里。
#
#   npm run emu:ios:boot                     # 默认 package.json config.emuDefault（ip16@26.3）
#   npm run emu:ios:boot -- ip16@26.3        # 短名@系统版本（推荐，跨机器通用）
#   npm run emu:ios:boot -- ip16pro@26.3     # iPhone 16 Pro / iOS 26.3
#   npm run emu:ios:boot -- ip16@18.1        # iPhone 16 / iOS 18.1
#   npm run emu:ios:boot -- "iPhone 16@26.3" # 写机型全名也行
#   npm run emu:ios:boot -- FF429526-A7EE-…  # 直接给 UDID
#   EMU=ip16@18.1 npm run emu:ios:boot       # 用环境变量改默认
#
# 短名表见 tool/emuResolveIos.js 的 builtinAlias（ip16 / ip16plus / ip16pro /
# ip16pm / ip17 / ip17pro / ip17pm / ipse3），也可以在 package.json 的 config 里加
# （"ipad": "iPad Pro 13-inch (M4)"）。
#
# 跑 App 永远打「当前已启动的那台」（纯 booted 语义）：
#   npm run run:ios:sim:agidin
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

spec="${1:-${EMU:-}}"
udid="$(node "${SCRIPT_DIR}/emuResolveIos.js" "${spec}")"

echo "▶ 模拟器 ${spec:-默认} → ${udid}"
if xcrun simctl boot "${udid}" 2>/dev/null; then
  echo "✅ 已启动"
else
  echo "（已在运行，跳过 boot）"
fi
open "$(xcode-select -p)/Applications/Simulator.app"
xcrun simctl list devices booted
