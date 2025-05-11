// lib/services/websocket_service.dart
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'dart:async';

typedef WebSocketMessageHandler = void Function(dynamic message);

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService() {
    return _instance;
  }

  WebSocketService._internal();

  late IOWebSocketChannel _channel;
  bool _isConnected = false;

  final List<WebSocketMessageHandler> _listeners = [];

  Timer? _heartbeatTimer;

  void connect({required String sessionId, required String clientId}) {
    if (_isConnected) {
      print("[INFO] WebSocket already explicitly connected.");
      return;
    }

    final uri = Uri.parse('wss://epsilon-poc-2.onrender.com/ws/$sessionId/$clientId');
    _channel = IOWebSocketChannel.connect(uri);

    _channel.stream.listen(
          (message) {
        dynamic decodedMessage;

        if (message is String) {
          try {
            decodedMessage = jsonDecode(message);
          } catch (e) {
            print("[ERROR] Failed to decode incoming WebSocket message: $e");
            return;
          }
        } else if (message is Map<String, dynamic>) {
          decodedMessage = message;
        } else {
          print("[ERROR] Unknown message type received: ${message.runtimeType}");
          return;
        }

        for (var listener in _listeners) {
          listener(decodedMessage);
        }
      },
      onDone: () {
        _isConnected = false;
        _heartbeatTimer?.cancel();
        print("[INFO] WebSocket explicitly closed by server.");
      },
      onError: (error) {
        _isConnected = false;
        _heartbeatTimer?.cancel();
        print("[ERROR] WebSocket explicitly error occurred: $error");
      },
    );

    _isConnected = true;
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      sendMessage({"type": "ping"});
    });
  }

  void sendMessage(dynamic message) {
    if (_isConnected) {
      try {
        final encodedMessage = jsonEncode(message);
        _channel.sink.add(encodedMessage);
      } catch (e) {
        print("[ERROR] Failed to encode outgoing WebSocket message: $e");
      }
    } else {
      print("[WARN] Attempted explicitly to send message but WebSocket is disconnected.");
    }
  }

  void disconnect() {
    if (_isConnected) {
      _channel.sink.close();
      _isConnected = false;
      _heartbeatTimer?.cancel();
      print("[INFO] WebSocket explicitly disconnected by client.");
    }
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
