/// 关闭按钮，对应源项目 `parts/partCloseButton.vue`。
///
/// 弹窗右上角的圆形关闭按钮（`uni-icons type="close"`）。
library;

import 'package:flutter/material.dart';

import '../core/icons/pex_icon.dart';
import '../theme/app_theme.dart';

class PartCloseButton extends StatelessWidget {
  const PartCloseButton({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
        onPressed: onClose,
        iconSize: 28,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        tooltip: '',
        icon: PexIcon.uni('close', size: 28, color: PexColors.greyA),
      ),
    );
  }
}
