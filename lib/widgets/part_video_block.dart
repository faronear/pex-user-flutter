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
  const PartVideoBlock({super.key, required this.url, this.title, this.fillCover = false});

  /// 视频地址（段落原始值：相对路径 / 裸 cid / 完整 URL）。
  final String url;

  /// 可选标题（失败卡片里展示；通常为原始文件名）。
  final String? title;

  /// true = 等比放大裁剪填满容器（封面场景，BoxFit.cover 语义）；
  /// false = 保持视频自身宽高比（编辑器/阅读器场景）。
  final bool fillCover;

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
    // 注意：macOS 实现里 controller.value.size 可能为零，不能用它判断；
    // aspectRatio（宽/高）初始化后必有值，用它构造基准尺寸给 FittedBox cover。
    final double ratio = controller.value.aspectRatio; // 宽/高
    final bool haveSize = ratio > 0;
    // fillCover：等比放大裁剪填满容器（不变形）；否则按视频自身宽高比显示
    final Widget video = haveSize && widget.fillCover
        ? FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: 1000 * ratio,
              height: 1000,
              child: VideoPlayer(controller),
            ),
          )
        : AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: widget.fillCover
          ? Stack(
              fit: StackFit.expand,
              children: <Widget>[
                GestureDetector(
                  onTap: () => setState(() {
                    controller.value.isPlaying ? controller.pause() : controller.play();
                  }),
                  // 内层 Stack 必须 expand：loose 约束下 FittedBox 退化为原比例居中（contain），cover 裁剪不生效
                  child: Stack(
                    alignment: Alignment.center,
                    fit: StackFit.expand,
                    children: <Widget>[
                      video,
                      if (!controller.value.isPlaying)
                        const Icon(Icons.play_circle_fill, size: 48, color: Colors.white70),
                    ],
                  ),
                ),
                // 封面模式不放进度条：其半透明背景会像蒙版盖住画面，
                // allowScrubbing 的拖动条也会露出红色段
              ],
            )
          : Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                GestureDetector(
                  onTap: () => setState(() {
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
