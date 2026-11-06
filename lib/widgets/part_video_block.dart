/// 内联视频块（对应源项目故事段落里的 video 槽位）。
///
/// [url] 取故事段落里存的原始值：相对路径（如 `_filestore/xxx.mp4`）、
/// 裸 cid 或完整 URL，按 [makeServerUrl] 与 [ServerImage] 一致地解析成
/// 可播放地址；初始化中显示加载占位，失败显示错误卡片（可重试）。
/// 参考 productX/einz 的 `_VideoPreview` 实现模式。
library;

import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../core/state/envar_provider.dart';
import '../core/util/server_url.dart';

class PartVideoBlock extends ConsumerStatefulWidget {
  const PartVideoBlock({super.key, required this.url, this.title});

  /// 视频地址（段落原始值：相对路径 / 裸 cid / 完整 URL）。
  final String url;

  /// 可选标题（失败卡片里展示；通常为原始文件名）。
  final String? title;

  @override
  ConsumerState<PartVideoBlock> createState() => _PartVideoBlockState();
}

class _PartVideoBlockState extends ConsumerState<PartVideoBlock> {
  VideoPlayerController? _controller;
  bool _failed = false;

  /// 最近一次解析出的实际播放地址（失败卡片上显示，便于定位）。
  String _lastResolved = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant PartVideoBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller?.dispose();
      _controller = null;
      _init();
    }
  }

  /// 解析为可播放地址：本地文件路径直接用（与 [makeServerUrl] 的网络语义
  /// 区分开），其余按 [makeServerUrl] 拼前缀（相对路径 → 服务器，裸 cid → ipfsLens）。
  String _resolvedUrl() {
    final String raw = widget.url.trim();
    if (!raw.contains('/') && File(raw).existsSync()) return raw;
    final String resolved = makeServerUrl(raw, ref.read(envarProvider));
    return resolved.isNotEmpty ? resolved : raw;
  }

  Future<void> _init() async {
    if (_failed && mounted) setState(() => _failed = false);
    final VideoPlayerController controller;
    try {
      final String url = _resolvedUrl();
      _lastResolved = url;
      final bool isLocal =
          !url.startsWith('http://') && !url.startsWith('https://');
      controller = isLocal
          ? VideoPlayerController.file(File(url))
          : VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
    } catch (e) {
      debugPrint('PartVideoBlock 初始化失败（${widget.url} → $_lastResolved）：$e');
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFDCDFE6)),
        ),
        padding: const EdgeInsets.all(6),
        child: Row(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.videocam, size: 22),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.title ?? widget.url,
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    _lastResolved,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF909399)),
                  ),
                  const Text(
                    '视频加载失败',
                    style: TextStyle(fontSize: 12, color: Color(0xFF909399)),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _init,
              child: const Text('重试', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
    }
    final VideoPlayerController? controller = _controller;
    if (controller == null) {
      return SizedBox(
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          GestureDetector(
            onTap: () => setState(() {
              // video_player 的 VideoPlayer 组件不带控制界面，点击画面切换播放/暂停
              controller.value.isPlaying ? controller.pause() : controller.play();
            }),
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  VideoPlayer(controller),
                  if (!controller.value.isPlaying)
                    const Icon(Icons.play_circle_fill, size: 48, color: Colors.white70),
                ],
              ),
            ),
          ),
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            padding: const EdgeInsets.only(top: 12),
          ),
        ],
      ),
    );
  }
}
