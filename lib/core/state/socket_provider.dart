/// WebSocket 客户端，对应源项目 `wo.unisocket`（npm 包 `wo-user-websocket-uniapp`）。
///
/// 协议很简单（照搬源项目）：
/// - 连接地址 = `envar.servUrl`，把 `http` 换成 `ws`；
/// - 连上后若本地有 `_passtoken`，发 `SOCKET_OWNER_RECONNECT` 认领连接；
/// - 每 20 秒发一次 `{skevent:'PING'}` 心跳；断开后每 5 秒重连；
/// - 服务端消息按 `skevent` 派发（如 `RECHARGE_SUCCESS`）。
///
/// 登录成功后由调用方发一次 `SOCKET_OWNER`（见 `app_startup_notifier.setOnlineUser`）。
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'app_providers.dart';

class SocketState {
  const SocketState({this.alive = false, this.attempt = 0});

  /// 连接是否可用（源项目 `wo.ss.socketAlive`）。
  final bool alive;

  /// 已尝试的连接次数（含重连）。
  final int attempt;

  SocketState copyWith({bool? alive, int? attempt}) => SocketState(
        alive: alive ?? this.alive,
        attempt: attempt ?? this.attempt,
      );
}

final NotifierProvider<SocketNotifier, SocketState> socketProvider =
    NotifierProvider<SocketNotifier, SocketState>(SocketNotifier.new);

class SocketNotifier extends Notifier<SocketState> {
  static const Duration heartbeatInterval = Duration(seconds: 20);
  static const Duration reconnectInterval = Duration(seconds: 5);

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeat;
  Timer? _reconnect;
  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();
  final List<Map<String, dynamic>> _queue = <Map<String, dynamic>>[];
  String _baseUrl = '';

  /// 所有服务端事件的广播流（订阅方按 `skevent` 自行过滤）。
  Stream<Map<String, dynamic>> get events => _events.stream;

  @override
  SocketState build() {
    ref.onDispose(_dispose);
    return const SocketState();
  }

  /// 连接（可重复调用；已连上则忽略）。[baseUrl] 为 `http(s)://...`。
  Future<void> connect(String baseUrl) async {
    if (baseUrl.isEmpty) return;
    _baseUrl = baseUrl;
    if (_channel != null) return; // 已连接或正在重连
    await _open();
  }

  /// 发送一条消息；未连接时先入队，连上后自动补发（与源项目一致）。
  void sendObject(Map<String, dynamic> obj) {
    final WebSocketChannel? channel = _channel;
    if (channel == null || !state.alive) {
      _queue.add(obj);
      return;
    }
    channel.sink.add(jsonEncode(obj));
  }

  Future<void> _open() async {
    if (_baseUrl.isEmpty) return;
    final Uri? uri = Uri.tryParse(
      _baseUrl.replaceFirst(RegExp('^https?'), 'ws'),
    );
    if (uri == null) return;

    state = state.copyWith(attempt: state.attempt + 1);
    try {
      final WebSocketChannel channel = WebSocketChannel.connect(uri);
      await channel.ready;
      _channel = channel;
      _subscription = channel.stream.listen(
        _onMessage,
        onDone: _onClosed,
        onError: (Object _) => _onClosed(),
        cancelOnError: true,
      );
    } catch (_) {
      _channel = null;
      _scheduleReconnect();
      return;
    }

    _reconnect?.cancel();
    _reconnect = null;
    state = state.copyWith(alive: true);

    // 断线重连时补认领（源项目 `SOCKET_OWNER_RECONNECT`）。
    final String passtoken = ref.read(localStoreProvider).passtoken;
    if (passtoken.isNotEmpty) {
      sendObject(<String, dynamic>{
        'skevent': 'SOCKET_OWNER_RECONNECT',
        '_passtoken': passtoken,
      });
    }
    for (final Map<String, dynamic> pending in _queue) {
      _channel?.sink.add(jsonEncode(pending));
    }
    _queue.clear();

    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(heartbeatInterval, (Timer _) {
      final WebSocketChannel? channel = _channel;
      if (channel == null || !state.alive) {
        _heartbeat?.cancel();
        _heartbeat = null;
        return;
      }
      channel.sink.add(jsonEncode(<String, String>{'skevent': 'PING'}));
    });
  }

  void _onMessage(dynamic data) {
    if (data is! String) return;
    final dynamic decoded = jsonDecode(data);
    if (decoded is! Map) return;
    _events.add(decoded.cast<String, dynamic>());
  }

  void _onClosed() {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    if (state.alive) state = state.copyWith(alive: false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnect?.cancel();
    _reconnect = Timer(reconnectInterval, _open);
  }

  void _dispose() {
    _heartbeat?.cancel();
    _reconnect?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _events.close();
  }
}
