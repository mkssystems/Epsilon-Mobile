// lib/widgets/game_state_router_widget.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/intro_screen.dart';
import '../screens/initial_tile_placement.dart';
import '../screens/game_lobby_screen.dart';
import '../services/game_menu_service.dart';
import '../services/websocket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final webSocketService = WebSocketService(); // Explicit singleton

class GameStateRouterWidget extends StatefulWidget {
  final String sessionId;

  const GameStateRouterWidget({super.key, required this.sessionId});

  @override
  _GameStateRouterWidgetState createState() => _GameStateRouterWidgetState();
}

class _GameStateRouterWidgetState extends State<GameStateRouterWidget> {
  Future<Map<String, dynamic>>? _gameStateFuture;
  String clientId = '';
  final GameMenuService service = GameMenuService();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    clientId = prefs.getString('client_id') ?? await service.getOrCreateClientId();

    // Explicitly initialize WebSocket if not already connected
    if (!webSocketService.isConnected) {
      webSocketService.connect(sessionId: widget.sessionId, clientId: clientId);
    }

    final response = await ApiService.getGameSessionStatus(widget.sessionId);
    setState(() {
      _gameStateFuture = Future.value(response);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_gameStateFuture == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _gameStateFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching game state: ${snapshot.error}'));
          }

          final gamePhase = snapshot.data?['phase']?['name'] as String?;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (gamePhase == null || gamePhase.trim().isEmpty) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => GameLobbyScreen(sessionId: widget.sessionId, clientId: clientId)),
              );
            } else {
              switch (gamePhase) {
                case 'TURN_0':
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const IntroScreen()),
                  );
                  break;

                case 'INITIAL_PLACEMENT':
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const InitialTilePlacementScreen()),
                  );
                  break;

                default:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Error')),
                        body: Center(
                          child: Text('Unexpected game state: "$gamePhase" - check logs.'),
                        ),
                      ),
                    ),
                  );
              }
            }
          });

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
