/// 未迁移页面的占位页：显示路由名，便于开发期导航验证。
library;

import 'package:flutter/material.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '「$title」尚未迁移',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
