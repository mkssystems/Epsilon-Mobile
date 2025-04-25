// lib/services/websocket_service.dart
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'dart:async';  // explicitly needed for Timer

typedef WebSocketMessageHandler = void Function(dynamic message);

class WebSocketService {
  late IOWebSocketChannel _channel;
  bool _isConnected = false;

  final List<WebSocketMessageHandler> _listeners = [];

  Timer? _heartbeatTimer;  // explicitly for sending periodic pings

  void connect({
    required String sessionId,
    required String clientId,
  }) {
    final uri = Uri.parse(
      'wss://epsilon-poc-2.onrender.com/ws/$sessionId/$clientId',
    );

    _channel = IOWebSocketChannel.connect(uri);

    _channel.stream.listen(
          (message) {
        _isConnected = true;
        for (var listener in _listeners) {
          listener(message);
        }
      },
      onDone: () {
        _isConnected = false;
        print("[INFO] WebSocket explicitly closed by server.");
        _heartbeatTimer?.cancel();  // explicitly stop ping timer when connection closes
      },
      onError: (error) {
        _isConnected = false;
        print("[ERROR] WebSocket error explicitly occurred: $error");
        _heartbeatTimer?.cancel();  // explicitly stop ping timer on error
      },
    );

    // Explicitly initiate heartbeat ping every 30 seconds
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      sendMessage({"type": "ping"});  // explicit ping message
      print("[INFO] Sent explicit heartbeat ping to server.");
    });
  }

  void sendMessage(dynamic message) {
    if (_isConnected) {
      _channel.sink.add(jsonEncode(message));
    } else {
      print("[WARN] Attempted explicitly to send message but WebSocket is disconnected.");
    }
  }

  void disconnect() {
    if (_isConnected) {
      _channel.sink.close();
      _isConnected = false;
      print("[INFO] WebSocket explicitly disconnected by client.");
    }
    _heartbeatTimer?.cancel();  // explicitly stop heartbeat ping on disconnect
  }

  bool get isConnected => _isConnected;

  void addListener(WebSocketMessageHandler listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(WebSocketMessageHandler listener) {
    _listeners.remove(listener);
  }
}
