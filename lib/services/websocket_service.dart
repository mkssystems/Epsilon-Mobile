// lib/services/websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

// Type definition for a handler to process WebSocket messages
typedef WebSocketMessageHandler = void Function(dynamic message);

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IOWebSocketChannel? _channel;
  bool _isConnected = false;
  final List<WebSocketMessageHandler> _listeners = [];
  Timer? _heartbeatTimer;

  void connect({required String sessionId, required String clientId}) {
    if (_isConnected) {
      print("[INFO] WebSocket already connected.");
      return;
    }

    final websocketUri = Uri.parse(
      'wss://epsilon-poc-2.onrender.com/ws/$sessionId/$clientId',
    );

    print("[DEBUG] Attempting WebSocket connection to: $websocketUri");

    try {
      _channel = IOWebSocketChannel.connect(websocketUri);
      print("[INFO] WebSocket connection initiated.");

      _channel?.stream.listen(
            (message) {
          print("[DEBUG] Raw message received: $message");
          dynamic decodedMessage;
          try {
            decodedMessage = jsonDecode(message);
            print("[DEBUG] Decoded message: $decodedMessage");
          } catch (e) {
            print("[ERROR] Failed to decode WebSocket message: $e");
            return;
          }

          for (var listener in _listeners) {
            listener(decodedMessage);
          }
        },
        onDone: () {
          _isConnected = false;
          _heartbeatTimer?.cancel();
          print("[INFO] WebSocket connection closed by server.");
        },
        onError: (error) {
          _isConnected = false;
          _heartbeatTimer?.cancel();
          print("[ERROR] WebSocket error occurred: $error");
        },
      );

      _isConnected = true;

      _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        sendMessage({"type": "ping"});
        print("[DEBUG] Sent heartbeat (ping).");
      });
    } catch (e) {
      _isConnected = false;
      print("[ERROR] Exception while establishing WebSocket connection: $e");
    }
  }

  void sendMessage(dynamic message) {
    if (_isConnected && _channel != null) {
      try {
        final encodedMessage = jsonEncode(message);
        print("[DEBUG] Sending message: $encodedMessage");
        _channel!.sink.add(encodedMessage);
      } catch (e) {
        print("[ERROR] Error sending message: $e");
      }
    } else {
      print("[WARN] Attempted to send message while WebSocket is disconnected.");
    }
  }

  void disconnect() {
    if (_isConnected && _channel != null) {
      _channel!.sink.close(status.normalClosure);
      _isConnected = false;
      _heartbeatTimer?.cancel();
      print("[INFO] WebSocket disconnected explicitly by client.");
    }
  }

  bool get isConnected => _isConnected;

  void addListener(WebSocketMessageHandler listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      print("[INFO] Listener added. Total listeners: ${_listeners.length}");
    }
  }

  void removeListener(WebSocketMessageHandler listener) {
    _listeners.remove(listener);
    print("[INFO] Listener removed. Total listeners: ${_listeners.length}");
  }
}
