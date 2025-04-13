import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/game_menu_service.dart';
import '../widgets/game_session_list_widget.dart';
import '../widgets/create_game_session_dialog.dart';

class GameMenuScreen extends StatefulWidget {
  const GameMenuScreen({super.key});

  @override
  _GameMenuScreenState createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  final GameMenuService service = GameMenuService();
  List<dynamic> sessions = [];
  String? currentSessionId;
  String clientId = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    service.getOrCreateClientId().then((id) {
      clientId = id;
      refreshSessions();
    });
  }

  Future<void> refreshSessions() async {
    setState(() => loading = true);
    sessions = await service.fetchGameSessions();
    currentSessionId = await service.checkClientSessionState(clientId);
    setState(() => loading = false);
  }

  void showCreateSession() {
    showDialog(
      context: context,
      builder: (_) => CreateGameSessionDialog(
        onCreate: (size, scenario, maxPlayers) async {
          await service.createGameSession(
            size: size,
            creatorClientId: clientId,
            scenarioName: scenario,
            difficulty: 'baseline_difficulty',
            maxPlayers: maxPlayers,
          );
          refreshSessions();
        },
      ),
    );
  }

  void onTapSession(dynamic session) {
    // Implement your logic here for tapping a session.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Menu')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: GameSessionListWidget(
              sessions: sessions,
              currentSessionId: currentSessionId,
              onTapSession: onTapSession,
            ),
          ),
          ElevatedButton(
            onPressed: showCreateSession,
            child: const Text('Create Game Session'),
          ),
        ],
      ),
    );
  }
}
