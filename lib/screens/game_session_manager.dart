// lib/screens/game_session_manager.dart

import 'package:flutter/material.dart';
import 'package:epsilon_mobile/services/websocket_service.dart';
import 'package:epsilon_mobile/screens/intro_screen.dart';
import 'package:epsilon_mobile/screens/game_lobby_screen.dart';

class GameSessionManager extends StatefulWidget {
  final String sessionId;
  final String clientId;

  const GameSessionManager({
    super.key,
    required this.sessionId,
    required this.clientId,
  });

  @override
  _GameSessionManagerState createState() => _GameSessionManagerState();
}

class _GameSessionManagerState extends State<GameSessionManager> {
  final webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();

    // Establish connection to the WebSocket service
    webSocketService.connect(
      sessionId: widget.sessionId,
      clientId: widget.clientId,
    );

    // Register listener to handle incoming messages
    webSocketService.addListener(handleWebSocketMessage);
  }

  // Handle incoming WebSocket messages (already JSON-decoded in WebSocketService)
  void handleWebSocketMessage(dynamic message) {
    // Directly use 'message' as a Map (already decoded)
    if (message is Map<String, dynamic> && message['event'] == 'game_started') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const IntroScreen(), // explicitly navigate to intro screen
        ),
      );
    }
  }

  @override
  void dispose() {
    // Explicitly remove the WebSocket listener before disposing
    webSocketService.removeListener(handleWebSocketMessage);

    // Disconnect from WebSocket
    webSocketService.disconnect();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build the GameLobbyScreen explicitly with the provided session and client IDs
    return GameLobbyScreen(
      sessionId: widget.sessionId,
      clientId: widget.clientId,
    );
  }
}
