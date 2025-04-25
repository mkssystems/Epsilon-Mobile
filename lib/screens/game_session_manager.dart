// lib/screens/game_session_manager.dart

import 'package:flutter/material.dart';
import 'package:epsilon_mobile/services/websocket_service.dart';
import 'package:epsilon_mobile/screens/intro_screen.dart';
import 'package:epsilon_mobile/screens/game_lobby_screen.dart';
import 'dart:convert';

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
  late final WebSocketService webSocketService;

  @override
  void initState() {
    super.initState();
    webSocketService = WebSocketService();

    webSocketService.connect(
      sessionId: widget.sessionId,
      clientId: widget.clientId,
      onMessage: handleWebSocketMessage,
    );
  }

  void handleWebSocketMessage(dynamic message) {
    final data = jsonDecode(message);

    if (data != null && data['event'] == 'game_started') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => IntroScreen(webSocketService: webSocketService),
        ),
      );
    }
  }

  @override
  void dispose() {
    webSocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameLobbyScreen(
      sessionId: widget.sessionId,
      clientId: widget.clientId,
      webSocketService: webSocketService,
    );
  }
}
