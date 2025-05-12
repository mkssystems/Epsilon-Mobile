// lib/services/websocket_service.dart
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'dart:async';

typedef WebSocketMessageHandler = void Function(dynamic message);

class WebSocketService {
  // Singleton instance
  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService() {
    return _instance;
  }

  WebSocketService._internal();

  // WebSocket channel instance
  late IOWebSocketChannel _channel;
  bool _isConnected = false;

  final List<WebSocketMessageHandler> _listeners = [];

  Timer? _heartbeatTimer;

  // Explicitly connects to the WebSocket with provided sessionId and clientId
  void connect({required String sessionId, required String clientId}) {
    if (_isConnected) {
      print("[INFO] WebSocket already explicitly connected.");
      return;
    }

    // Correctly constructing WebSocket URL explicitly
    final url = 'wss://epsilon-poc-2.onrender.com/ws/$sessionId/$clientId';

    // Explicit logging of constructed WebSocket URL for debugging
    print("[DEBUG] WebSocket URL explicitly generated: $url");

    // Connecting explicitly using the URL string directly
    _channel = IOWebSocketChannel.connect(url);

    // Listening for incoming WebSocket messages explicitly
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

        // Explicitly notify all registered listeners
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

    // Explicit heartbeat to maintain WebSocket connection
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      sendMessage({"type": "ping"});
    });
  }

  // Explicitly send message through WebSocket
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

  // Explicitly disconnect WebSocket
  void disconnect() {
    if (_isConnected) {
      _channel.sink.close();
      _isConnected = false;
      _heartbeatTimer?.cancel();
      print("[INFO] WebSocket explicitly disconnected by client.");
    }
  }

  bool get isConnected => _isConnected;

  // Explicitly add message handler
  void addListener(WebSocketMessageHandler listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  // Explicitly remove message handler
  void removeListener(WebSocketMessageHandler listener) {
    _listeners.remove(listener);
  }
}
