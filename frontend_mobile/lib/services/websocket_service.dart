import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Servizio WebSocket generico: connessione, invio/ricezione JSON, riconnessione opzionale.
/// Base URL WS: ws://localhost:8000/ws (auction, live, match).
class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final void Function(dynamic data)? onMessage;
  final void Function()? onDone;
  final void Function(Object error)? onError;

  WebSocketService({
    this.onMessage,
    this.onDone,
    this.onError,
  });

  bool get isConnected => _channel != null;

  void connect(String url, {void Function(dynamic)? onMessage}) {
    disconnect();
    final handler = onMessage ?? this.onMessage;
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _subscription = _channel!.stream.listen(
      (data) {
        try {
          final decoded = data is String ? jsonDecode(data) : data;
          handler?.call(decoded);
        } catch (_) {
          handler?.call(data);
        }
      },
      onDone: () {
        _channel = null;
        _subscription = null;
        onDone?.call();
      },
      onError: (e) {
        onError?.call(e);
      },
    );
  }

  void send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
  }
}
