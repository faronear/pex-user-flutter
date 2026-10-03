#!/usr/bin/env python3
"""给 iOS 工程注入三品牌 flavors（与 Android productFlavors 对齐）。

产物：
- ios/Flutter/<Brand>-Debug.xcconfig / <Brand>-Release.xcconfig
  （include Pods 配置 + Generated.xcconfig，覆盖 PRODUCT_BUNDLE_IDENTIFIER / PRODUCT_NAME）
- project.pbxproj 里新增各 flavor 的 XCBuildConfiguration（Project / Runner / RunnerTests 三套列表都要）
- 共享 scheme：ios/Runner.xcodeproj/xcshareddata/xcschemes/<brand>.xcscheme

注意：仅改原生工程；Dart 侧品牌仍由 -t lib/main_<brand>.dart 决定。
"""
import os
import re
import random

ROOT = "ios"
PBX = os.path.join(ROOT, "Runner.xcodeproj", "project.pbxproj")
SCHEME_DIR = os.path.join(ROOT, "Runner.xcodeproj", "xcshareddata", "xcschemes")

# (flavor key, bundle id, display name) — 与 android/app/build.gradle.kts 的 productFlavors 对齐
FLAVORS = [
    ("agidin", "cc.tic.agidin", "Agidin"),
    ("babelyx", "cc.tic.babelyx", "Babelyx"),
]


def uid():
    return "".join(random.choices("0123456789ABCDEF", k=24))


def main():
    s = open(PBX).read()

    xc = {}  # (flavor, 'debug'|'release') -> (uid, filename)
    new_blocks = []
    runner_uids = []  # (uid, name) 进 Runner target 列表
    proj_uids = []    # 进 Project 列表
    test_uids = []    # 进 RunnerTests 列表

    for fkey, bundle, name in FLAVORS:
        cap = fkey.capitalize()  # Agidin / Babelyx
        for kind, podcfg in [("debug", "debug"), ("release", "release")]:
            u = uid()
            fn = "%s-%s.xcconfig" % (cap, kind.capitalize())
            xc[(fkey, kind)] = (u, fn)
            content = (
                '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.%s.xcconfig"\n' % podcfg
                + '#include "Generated.xcconfig"\n'
                + "PRODUCT_BUNDLE_IDENTIFIER = %s\n" % bundle
                + "PRODUCT_NAME = %s\n" % name
            )
            with open(os.path.join(ROOT, "Flutter", fn), "w") as f:
                f.write(content)

        def make_cfg(tpl_uid, new_name, basecfg=None, bundle=None, pname=None):
            m = re.search(
                r"^\t\t" + re.escape(tpl_uid) + r" /\* .*? \*/ = \{.*?\n\t\t\};",
                s,
                re.S | re.M,
            )
            if not m:
                raise SystemExit("template not found: " + tpl_uid)
            blk = m.group(0)
            blk = re.sub(
                r"^\t\t" + re.escape(tpl_uid) + r" /\* .*? \*/",
                "\t\t" + uid() + " /* " + new_name + " */",
                blk,
                flags=re.M,
            )
            blk = re.sub(r"\n\t\tname = .*?;", '\n\t\tname = "%s";' % new_name, blk)
            if basecfg:
                blk = re.sub(
                    r"baseConfigurationReference = [0-9A-F]+ /\* .*? \*/;",
                    "baseConfigurationReference = %s /* %s */;" % (basecfg[0], basecfg[1]),
                    blk,
                )
            if bundle:
                blk = re.sub(
                    r"PRODUCT_BUNDLE_IDENTIFIER = .*?;",
                    "PRODUCT_BUNDLE_IDENTIFIER = %s;" % bundle,
                    blk,
                )
            if pname:
                blk = re.sub(r"PRODUCT_NAME = .*?;", "PRODUCT_NAME = %s;" % pname, blk)
            # 取回刚生成的 uid
            mu = re.match(r"^\t\t([0-9A-F]+) /\* ", blk, re.M).group(1)
            new_blocks.append(blk)
            return mu

        cap = fkey.capitalize()
        # Runner target：带 baseConfigurationReference（指向 flavor xcconfig）
        r_dbg = make_cfg(
            "97C147061CF9000F007C117D",
            "Debug-%s" % fkey,
            basecfg=xc[(fkey, "debug")],
            bundle=bundle,
            pname=name,
        )
        r_rel = make_cfg(
            "97C147071CF9000F007C117D",
            "Release-%s" % fkey,
            basecfg=xc[(fkey, "release")],
            bundle=bundle,
            pname=name,
        )
        runner_uids.append((r_dbg, "Debug-%s" % fkey))
        runner_uids.append((r_rel, "Release-%s" % fkey))
        # Project level：仅改 name
        p_dbg = make_cfg("97C147031CF9000F007C117D", "Debug-%s" % fkey)
        p_rel = make_cfg("97C147041CF9000F007C117D", "Release-%s" % fkey)
        proj_uids.append((p_dbg, "Debug-%s" % fkey))
        proj_uids.append((p_rel, "Release-%s" % fkey))
        # RunnerTests：改 name + bundle
        t_dbg = make_cfg(
            "331C8088294A63A400263BE5",
            "Debug-%s" % fkey,
            bundle=bundle + ".RunnerTests",
        )
        t_rel = make_cfg(
            "331C8089294A63A400263BE5",
            "Release-%s" % fkey,
            bundle=bundle + ".RunnerTests",
        )
        test_uids.append((t_dbg, "Debug-%s" % fkey))
        test_uids.append((t_rel, "Release-%s" % fkey))

    # 1) 注入新 XCBuildConfiguration 块（在 End XCBuildConfiguration section 之前）
    insert = "\n".join(new_blocks) + "\n"
    s = s.replace("/* End XCBuildConfiguration section */", insert + "/* End XCBuildConfiguration section */", 1)

    # 2) PBXFileReference：在 Release.xcconfig 那行后追加 6 个 flavor xcconfig
    fileref_lines = []
    for (fkey, kind), (u, fn) in xc.items():
        fileref_lines.append(
            '\t\t%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = %s; path = Flutter/%s; sourceTree = "<group>"; };'
            % (u, fn, fn, fn)
        )
    s = s.replace(
        '7AFA3C8E1D35360C0083082E /* Release.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = Release.xcconfig; path = Flutter/Release.xcconfig; sourceTree = "<group>"; };',
        '7AFA3C8E1D35360C0083082E /* Release.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = Release.xcconfig; path = Flutter/Release.xcconfig; sourceTree = "<group>"; };\n'
        + "\n".join(fileref_lines),
        1,
    )

    # 3) Flutter group children：在 Generated.xcconfig 后追加
    child_lines = []
    for (fkey, kind), (u, fn) in xc.items():
        child_lines.append("\t\t\t\t%s /* %s */," % (u, fn))
    s = s.replace(
        "9740EEB31CF90195004384FC /* Generated.xcconfig */,",
        "9740EEB31CF90195004384FC /* Generated.xcconfig */,\n" + "\n".join(child_lines),
        1,
    )

    # 4) 三个 XCConfigurationList 各追加对应 uid
    def add_to_list(list_uid, uids):
        nonlocal s
        m = re.search(
            r"^\t\t" + re.escape(list_uid) + r" /\* Build configuration list.*? = \{\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = \(\n(.*?)\n\t\t\t\);",
            s,
            re.S | re.M,
        )
        if not m:
            raise SystemExit("list not found: " + list_uid)
        body = m.group(1)
        additions = "".join("\n\t\t\t\t%s /* %s */," % (u, n) for u, n in uids)
        s = s[: m.start(1)] + body + additions + s[m.end(1):]

    add_to_list("97C147051CF9000F007C117D", runner_uids)  # Runner target
    add_to_list("97C146E91CF9000F007C117D", proj_uids)    # Project
    add_to_list("331C8087294A63A400263BE5", test_uids)    # RunnerTests

    with open(PBX, "w") as f:
        f.write(s)

    # 5) 共享 scheme
    os.makedirs(SCHEME_DIR, exist_ok=True)
    tmpl = open(os.path.join(SCHEME_DIR, "Runner.xcscheme")).read()
    for fkey, bundle, name in FLAVORS:
        scheme = (
            tmpl.replace('buildConfiguration = "Debug"', 'buildConfiguration = "Debug-%s"' % fkey)
            .replace('buildConfiguration = "Release"', 'buildConfiguration = "Release-%s"' % fkey)
            .replace('buildConfiguration = "Profile"', 'buildConfiguration = "Release-%s"' % fkey)
        )
        with open(os.path.join(SCHEME_DIR, "%s.xcscheme" % fkey), "w") as f:
            f.write(scheme)

    print("OK: generated iOS flavors for", [f[0] for f in FLAVORS])


if __name__ == "__main__":
    main()
