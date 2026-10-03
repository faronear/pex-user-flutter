#!/usr/bin/env python3
"""用各品牌官方 logo 生成 iOS / Android 应用图标。

源图（一次性生成，产物已提交；如需换新 logo 改这里重跑）：
- agidin : pex-app-doc/agidin-爱奇点/图标/logo-circle-closed-bgWhite-appicon-1024.png
- babelyx: pex-app-doc/babelyx-巴贝历/logo_标志/logo-babely-bgWhite-fgRedWhite-appicon-1024.png

产物：
- ios/Runner/Assets.xcassets/AppIcon-<brand>.appiconset/（配合 flavor 配置的
  ASSETCATALOG_COMPILER_APPICON_NAME）
- android/app/src/<brand>/res/mipmap-*/ic_launcher.png（flavor res 覆盖 main）
"""
import json
import os
import subprocess
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PEX = os.path.dirname(ROOT)  # monorepo 根

PIL_PYTHON = "/tmp/pexicons/bin/python"  # 已安装的 Pillow venv

BRANDS = [
    ("agidin", "Agidin", os.path.join(PEX, "pex-app-doc", "agidin-爱奇点", "图标", "logo-circle-closed-bgWhite-appicon-1024.png")),
    ("babelyx", "Babelyx", os.path.join(PEX, "pex-app-doc", "babelyx-巴贝历", "logo_标志", "logo-babely-bgWhite-fgRedWhite-appicon-1024.png")),
]

# (size 标识, scale, 实际像素)
IOS_SIZES = [
    ("20x20", 1, 20), ("20x20", 2, 40), ("20x20", 3, 60),
    ("29x29", 1, 29), ("29x29", 2, 58), ("29x29", 3, 87),
    ("40x40", 1, 40), ("40x40", 2, 80), ("40x40", 3, 120),
    ("60x60", 2, 120), ("60x60", 3, 180),
    ("76x76", 1, 76), ("76x76", 2, 152),
    ("83.5x83.5", 2, 167),
    ("1024x1024", 1, 1024),
]

ANDROID_DENSITIES = [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]


def sips_resize(src, dst, px):
    subprocess.run(["sips", "-z", str(px), str(px), src, "--out", dst],
                   check=True, capture_output=True)


def normalize_src(src):
    """把源图（可能是 RGBA/带透明）压平成不透明的白底 RGB 图。

    iOS 在渲染 App 图标时会把 alpha 压平为黑色，导致透明区域发黑。
    agidin 源图本就是白底不透明；babelyx 源图带透明，
    这里统一先铺白底再去掉 alpha，保证三品牌图标在 iOS 上都干净。
    """
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
        tmp = f.name
    code = (
        "import sys,PIL.Image as I\n"
        "im=I.open(sys.argv[1]).convert('RGBA')\n"
        "bg=I.new('RGBA',im.size,(255,255,255,255))\n"
        "im=I.alpha_composite(bg,im).convert('RGB')\n"
        "im.save(sys.argv[2])\n"
    )
    subprocess.run([PIL_PYTHON, "-c", code, src, tmp], check=True, capture_output=True)
    return tmp


def main():
    tpl_dir = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    tpl_json = json.load(open(os.path.join(tpl_dir, "Contents.json")))

    for key, cap, src in BRANDS:
        assert os.path.exists(src), "源图不存在: " + src
        opaque = normalize_src(src)  # 白底不透明版本，供后续 resize

        # ---- iOS appiconset ----
        out_dir = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon-%s.appiconset" % key)
        os.makedirs(out_dir, exist_ok=True)
        images = []
        for size, scale, px in IOS_SIZES:
            fn = "Icon-%s-%s@%dx.png" % (cap, size, scale)
            sips_resize(opaque, os.path.join(out_dir, fn), px)
            images.append({"size": size, "idiom": None, "filename": fn, "scale": "%dx" % scale})
        # 复刻原 Contents.json 的 idiom 分配（按原文件顺序：iphone → ipad → marketing）
        tpl_idioms = [i["idiom"] for i in tpl_json["images"]]
        for entry, idiom in zip(images, tpl_idioms):
            entry["idiom"] = idiom
        json.dump({"images": images, "info": tpl_json["info"]},
                  open(os.path.join(out_dir, "Contents.json"), "w"), indent=2, ensure_ascii=False)

        # ---- Android flavor mipmaps ----
        for density, px in ANDROID_DENSITIES:
            d = os.path.join(ROOT, "android", "app", "src", key, "res", "mipmap-%s" % density)
            os.makedirs(d, exist_ok=True)
            sips_resize(opaque, os.path.join(d, "ic_launcher.png"), px)

        os.remove(opaque)
        print("OK %s <- %s" % (key, os.path.basename(src)))


if __name__ == "__main__":
    main()
