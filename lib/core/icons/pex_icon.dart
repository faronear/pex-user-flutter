/// 图标渲染组件：用图标字体的码点绘制字形。
///
/// 替代源项目的 `<uni-icons>` 与 `class="icont-xxx"`。
library;

import 'package:flutter/widgets.dart';

import 'icont_icons.dart';

class PexIcon extends StatelessWidget {
  const PexIcon(this.glyph, {super.key, this.size = 16, this.color});

  /// 字形（由 [PexIcons] 解析得到）；为 null 时不渲染。
  final PexGlyph? glyph;

  final double size;
  final Color? color;

  /// 由 `<uni-icons type="...">` 的 type 构造。
  factory PexIcon.uni(String? type, {Key? key, double size = 16, Color? color}) =>
      PexIcon(PexIcons.uni(type), key: key, size: size, color: color);

  /// 由 icont 类名构造。
  factory PexIcon.icont(String? type, {Key? key, double size = 16, Color? color}) =>
      PexIcon(PexIcons.icont(type), key: key, size: size, color: color);

  @override
  Widget build(BuildContext context) {
    final PexGlyph? value = glyph;
    if (value == null) return SizedBox(width: size, height: size);
    return Text(
      String.fromCharCode(value.codepoint),
      style: TextStyle(
        fontFamily: value.fontFamily,
        fontSize: size,
        color: color,
        height: 1,
      ),
    );
  }
}
