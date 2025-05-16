
// lib/screens/game_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/game_menu_service.dart';
import '../widgets/game_session_list_widget.dart';
import '../widgets/create_game_session_dialog.dart';
import '../widgets/game_session_details_dialog.dart';
import '../widgets/qr_code_scanner_widget.dart';
import 'game_session_manager.dart';
import '../services/api_service.dart';
import '../widgets/game_state_router_widget.dart';
import 'game_lobby_screen.dart';


class GameMenuScreen extends StatefulWidget {
  const GameMenuScreen({super.key});

  @override
  _GameMenuScreenState createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  final GameMenuService service = GameMenuService();
  String? currentSessionId;
  String clientId = '';
  bool loading = true;

  List<dynamic> createdSessions = [];
  List<dynamic> joinedSessions = [];

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

    createdSessions = await service.fetchGameSessions(clientId);
    joinedSessions = await service.fetchJoinedGameSessions(clientId);
    currentSessionId = await service.checkClientSessionState(clientId);

    setState(() => loading = false);
  }

  void showCreateSession() {
    showDialog(
      context: context,
      builder: (_) => CreateGameSessionDialog(
        userId: clientId,
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
    await refreshSessions();
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
                        await service.clearSessionAndClientId();
                        print('Cleared sessionId explicitly');
                        await refreshSessions();
                        setDialogState(() {});
                      },
                      child: const Text('Leave'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final gamePhase = (await ApiService.getGameSessionStatus(session['id']))['game_phase'] as String?;

                        if (!mounted) return;
                        Navigator.pop(dialogContext);

                        if (gamePhase == null || gamePhase.trim().isEmpty) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GameLobbyScreen(sessionId: session['id'], clientId: clientId),
                            ),
                          );
                        } else {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => GameStateRouterWidget(sessionId: session['id']),
                            ),
                          );
                        }
                      },
                      child: const Text('Enter Game'),
                    ),
                  ],
                );
              } else if (currentSessionId == null) {
                return ElevatedButton(
                  onPressed: () async {
                    await service.joinGameSession(clientId, session['id']);
                    await service.storeSessionAndClientId(session['id'], clientId);
                    print('Stored sessionId: ${session['id']} and clientId: $clientId explicitly');
                    await refreshSessions();
                    setDialogState(() {});
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


  void scanQrAndJoinSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRCodeScannerWidget(
          onScanned: (sessionId) async {
            bool confirmJoin = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext ctx) => AlertDialog(
                title: const Text("Join Game Session"),
                content: Text("Do you want to join session: $sessionId?"),
                actions: [
                  TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                  ElevatedButton(
                    child: const Text("Join"),
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              ),
            ) ?? false;

            if (confirmJoin) {
              try {
                await service.joinGameSession(clientId, sessionId);
                await service.storeSessionAndClientId(sessionId, clientId);
                print('Stored sessionId: $sessionId and clientId: $clientId explicitly via QR');
                await refreshSessions();

                if (!mounted) return;
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameSessionManager(sessionId: sessionId, clientId: clientId),
                  ),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully joined session $sessionId')),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to join session: $e')),
                );
              }
            } else {
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Join cancelled')),
              );
            }
          },
          onCancel: () {
            if (mounted) Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('QR scan cancelled')),
            );
          },
        ),
      ),
    );
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
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Sessions I Created', style: Theme.of(context).textTheme.titleLarge),
            ),
            GameSessionListWidget(
              sessions: createdSessions,
              currentSessionId: currentSessionId,
              onTapSession: showSessionDetails,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Sessions I Joined', style: Theme.of(context).textTheme.titleLarge),
            ),
            GameSessionListWidget(
              sessions: joinedSessions,
              currentSessionId: currentSessionId,
              onTapSession: showSessionDetails,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
            const Divider(),
            ElevatedButton(onPressed: showCreateSession, child: const Text('Create Game Session')),
            ElevatedButton(onPressed: scanQrAndJoinSession, child: const Text('Join via QR Code')),
          ],
        ),
      ),
    );
  }
}
