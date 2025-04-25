// lib/services/websocket_service.dart

import 'package:web_socket_channel/io.dart';
import 'dart:convert';

typedef WebSocketMessageHandler = void Function(dynamic message);

class WebSocketService {
  late IOWebSocketChannel _channel;
  late WebSocketMessageHandler _messageHandler;

  bool _isConnected = false;

  // Explicitly establish a connection to the WebSocket server
  void connect({
    required String sessionId,
    required String clientId,
    required WebSocketMessageHandler onMessage,
  }) {
    final uri = Uri.parse(
      'wss://epsilon-poc-2.onrender.com/ws/$sessionId/$clientId',
    );

    _channel = IOWebSocketChannel.connect(uri);
    _messageHandler = onMessage;

    _channel.stream.listen(
          (message) {
        _isConnected = true;
        _messageHandler(message);
      },
      onDone: () {
        _isConnected = false;
        print("[INFO] WebSocket connection explicitly closed by server.");
      },
      onError: (error) {
        _isConnected = false;
        print("[ERROR] WebSocket error explicitly occurred: $error");
      },
    );
  }

  // Explicitly send a JSON-formatted message through the WebSocket
  void sendMessage(dynamic message) {
    if (_isConnected) {
      _channel.sink.add(jsonEncode(message));
    } else {
      print("[WARN] Attempted explicitly to send a message but WebSocket is disconnected.");
    }
  }

  // Explicitly disconnect from the WebSocket server
  void disconnect() {
    if (_isConnected) {
      _channel.sink.close();
      _isConnected = false;
      print("[INFO] WebSocket explicitly disconnected by client.");
    }
  }

  // Check explicitly if WebSocket is currently connected
  bool get isConnected => _isConnected;
}
