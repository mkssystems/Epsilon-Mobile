// lib/widgets/game_state_router_widget.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/intro_screen.dart';
import '../screens/initial_tile_placement.dart';
import '../screens/game_lobby_screen.dart';
import '../services/game_menu_service.dart';

class GameStateRouterWidget extends StatefulWidget {
  final String sessionId;

  const GameStateRouterWidget({super.key, required this.sessionId});

  @override
  _GameStateRouterWidgetState createState() => _GameStateRouterWidgetState();
}

class _GameStateRouterWidgetState extends State<GameStateRouterWidget> {
  late Future<Map<String, dynamic>> _gameStateFuture;
  String clientId = '';
  final GameMenuService service = GameMenuService();

  @override
  void initState() {
    super.initState();
    fetchGameStateAndClientId();
  }

  void fetchGameStateAndClientId() async {
    clientId = await service.getOrCreateClientId();
    debugPrint("Fetched clientId explicitly: $clientId");

    setState(() {
      _gameStateFuture = ApiService.getGameSessionStatus(widget.sessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _gameStateFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching game state: ${snapshot.error}'));
          }

          final gamePhase = snapshot.data?['game_phase'] as String?;
          debugPrint("Fetched gamePhase explicitly: '$gamePhase'");

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (gamePhase == null || gamePhase.trim().isEmpty) {
              debugPrint("Game phase is null or empty, routing explicitly to GameLobbyScreen");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => GameLobbyScreen(sessionId: widget.sessionId, clientId: clientId)),
              );
            } else {
              switch (gamePhase) {
                case 'TURN_0':
                  debugPrint("Routing explicitly to IntroScreen (TURN_0 phase)");
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const IntroScreen()),
                  );
                  break;

                case 'INITIAL_PLACEMENT':
                  debugPrint("Routing explicitly to InitialTilePlacementScreen (INITIAL_PLACEMENT phase)");
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const InitialTilePlacementScreen()),
                  );
                  break;

                default:
                  debugPrint("Encountered unexpected game phase explicitly: '$gamePhase'");
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
