import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/game_menu_service.dart';
import '../widgets/game_session_list_widget.dart';
import '../widgets/create_game_session_dialog.dart';
import '../widgets/game_session_details_dialog.dart';
import 'game_lobby_screen.dart';

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
    sessions = await service.fetchGameSessions(clientId);
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

  void showSessionDetails(dynamic session) async {
    await refreshSessions(); // Ensure session state is updated
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext dialogContext, void Function(void Function()) setDialogState) {
            Widget buildActionButtons() {
              if (currentSessionId == session['id']) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await service.leaveGameSession(clientId);
                        await refreshSessions();
                        setDialogState(() {});
                      },
                      child: const Text('Leave'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GameLobbyScreen(sessionId: session['id'], clientId: clientId),
                          ),
                        );
                      },
                      child: const Text('Enter Game'),
                    ),
                  ],
                );
              } else if (currentSessionId == null) {
                return ElevatedButton(
                  onPressed: () async {
                    await service.joinGameSession(clientId, session['id']);
                    await refreshSessions();
                    setDialogState(() {}); // Only refresh dialog UI, do not close it
                  },
                  child: const Text('Join'),
                );
              }
              return const SizedBox();
            }

            return GameSessionDetailsDialog(
              session: session,
              actionButtons: buildActionButtons(),
            );
          },
        );
      },
    );
  }


  Widget buildActionButtons(dynamic session) {
    if (currentSessionId == session['id']) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () async {
              await service.leaveGameSession(clientId);
              refreshSessions();
              Navigator.pop(context);
            },
            child: const Text('Leave'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameLobbyScreen(sessionId: session['id'], clientId: clientId),
                ),
              );
            },
            child: const Text('Enter Game'),
          ),
        ],
      );
    } else if (currentSessionId == null) {
      return ElevatedButton(
        onPressed: () async {
          await service.joinGameSession(clientId, session['id']);
          refreshSessions();
          Navigator.pop(context);
        },
        child: const Text('Join'),
      );
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Menu'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: refreshSessions),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: GameSessionListWidget(
              sessions: sessions,
              currentSessionId: currentSessionId,
              onTapSession: showSessionDetails,
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