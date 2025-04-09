import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart'; // For Clipboard usage
import '../utils/app_guide.dart';
import 'game_lobby_screen.dart'; // <-- Newly added import
import 'package:intl/intl.dart';


class GameMenuScreen extends StatefulWidget {
  const GameMenuScreen({super.key});

  @override
  _GameMenuScreenState createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  final String backendUrl = 'https://epsilon-poc-2.onrender.com/api';
  List<dynamic> gameSessions = [];
  bool loading = true;
  String? currentSessionId;
  String clientId = "";

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    initializeClientId().then((_) {
      checkClientSessionState();
      fetchGameSessions();
    });
  }

  Future<void> initializeClientId() async {
    clientId = await getOrCreateClientId();
    setState(() {});
  }

  Future<String> getOrCreateClientId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedClientId = prefs.getString('client_id');
    if (storedClientId == null) {
      storedClientId = const Uuid().v4();
      await prefs.setString('client_id', storedClientId);
    }
    return storedClientId;
  }

  Future<void> checkClientSessionState() async {
    final response =
    await http.get(Uri.parse('$backendUrl/game_sessions/client_state/$clientId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['connected_session'] != null) {
        setState(() {
          currentSessionId = data['connected_session'];
        });
        showMessage("Restored session: ${data['connected_session']}");
      } else {
        setState(() => currentSessionId = null);
      }
    } else {
      showMessage("Failed to check session state");
    }
  }

  Future<void> fetchGameSessions() async {
    setState(() => loading = true);

    final response = await http.get(Uri.parse('$backendUrl/game_sessions'));
    if (response.statusCode == 200) {
      setState(() {
        gameSessions = jsonDecode(response.body)['sessions'];
        loading = false;
      });
    } else {
      setState(() => loading = false);
      showMessage("Failed to load sessions");
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> joinGameSession(String sessionId) async {
    if (currentSessionId != null) {
      showMessage("Already connected to session: $currentSessionId");
      return;
    }

    final response = await http.post(
      Uri.parse('$backendUrl/game_sessions/$sessionId/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'client_id': clientId}),
    );

    if (response.statusCode == 200) {
      setState(() => currentSessionId = sessionId);
      showMessage("Successfully connected to session: $sessionId");
    } else {
      showMessage("Failed to connect: ${response.body}");
    }
  }

  Future<void> leaveGameSession() async {
    final response = await http.post(
      Uri.parse('$backendUrl/game_sessions/leave'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'client_id': clientId}),
    );

    if (response.statusCode == 200) {
      setState(() => currentSessionId = null);
      showMessage("Successfully left session.");
    } else {
      showMessage("Failed to leave session: ${response.body}");
    }
  }

  void showGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("App Guide"),
        content: SingleChildScrollView(
          child: Text(gameMenuGuide),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: showGuideDialog,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.grey[200],
              child: ListTile(
                title: Text('Client ID: $clientId'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: Colors.grey[300],
              child: ListTile(
                title: const Text("Session Actions"),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: createGameSession,
                      child: const Text('Create'),
                    ),
                    ElevatedButton(
                      onPressed: fetchGameSessions,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: gameSessions
                    .map(
                      (session) => Card(
                    color: currentSessionId == session['id'] ? Colors.green[100] : null,
                    child: ListTile(
                      title: Text('Session ${session['id']}'),
                      onTap: () => showSessionDetails(session),
                    ),
                  ),
                )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showSessionDetails(dynamic session) async {
    // Re-check client state each time dialog is opened
    await checkClientSessionState();
    if (!mounted) return; // Safety check

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext dialogContext, void Function(void Function()) setDialogState) {

            // 1. Define a custom ordering (and labels) for certain keys.
            //    Adjust or extend this as needed.
            final orderedKeys = <String>[
              'owner',
              'status',
              'createdAt',
              'updatedAt',
              'players', // or 'playersCount'
              'maxPlayers',
              // etc.
            ];

            // 2. Prepare session entries, excluding 'id'.
            //    You can also exclude or rename other fields if desired.
            List<MapEntry<String, dynamic>> entries = session.entries
                .where((e) => e.key != 'id' && e.value != null)
                .toList();

            // 3. Sort them using our custom ordering.
            //    Any key not in orderedKeys can go at the end or be ignored.
            entries.sort((a, b) {
              final indexA = orderedKeys.indexOf(a.key);
              final indexB = orderedKeys.indexOf(b.key);
              // If the key doesn't appear in orderedKeys, push it to the end.
              final safeIndexA = (indexA == -1) ? 999 : indexA;
              final safeIndexB = (indexB == -1) ? 999 : indexB;
              return safeIndexA.compareTo(safeIndexB);
            });

            // 4. A helper to format date strings (short day & hour).
            String formatShortDate(String isoString) {
              try {
                final date = DateTime.parse(isoString);
                // Adjust the pattern as you prefer: e.g. "MMM d, HH:mm"
                final formatter = DateFormat("MMM d, HH:mm");
                return formatter.format(date);
              } catch (_) {
                // If parsing fails, return the original string.
                return isoString;
              }
            }

            // 5. A small helper widget to display "Label: Value" lines.
            Widget buildDataRow(String label, String value) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$label: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(child: Text(value)),
                  ],
                ),
              );
            }

            // 6. Build a list of widgets from the sorted entries.
            List<Widget> detailWidgets = [];
            for (final entry in entries) {
              String label = entry.key;
              String value = entry.value.toString();

              // If it’s a date field, format it:
              if (entry.key == 'createdAt' || entry.key == 'updatedAt') {
                value = formatShortDate(value);
              }

              // Optionally rename any labels to be more user-friendly
              switch (entry.key) {
                case 'owner':
                  label = 'Owner'; // capitalized
                  break;
                case 'status':
                  label = 'Status';
                  break;
                case 'createdAt':
                  label = 'Created';
                  break;
                case 'updatedAt':
                  label = 'Updated';
                  break;
                case 'players':
                  label = 'Players';
                  // You might want to convert from list to a comma‐separated string
                  // if it's a list of player names, e.g. value = (entry.value as List).join(", ");
                  break;
                default:
                // No special rename
                  break;
              }

              detailWidgets.add(buildDataRow(label, value));
            }

            Widget buildActionButtons() {
              if (currentSessionId == session['id']) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await leaveGameSession();
                        setDialogState(() {});  // Rebuild inside dialog
                        if (mounted) setState(() {}); // Rebuild parent
                      },
                      child: const Text('Leave'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // Close dialog first
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameLobbyScreen(
                              sessionId: session['id'],
                              clientId: clientId,
                            ),
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
                    await joinGameSession(session['id']);
                    setDialogState(() {});
                    if (mounted) setState(() {});
                  },
                  child: const Text('Join'),
                );
              } else {
                // The user is in another session, show nothing or a placeholder
                return const SizedBox();
              }
            }

            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Session ID: ${session['id']}',
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.bodyMedium!.fontSize! + 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: session['id']));
                      showMessage("Session ID copied to clipboard.");
                    },
                  ),
                ],
              ),

              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show the session details in a clearer, sorted format
                    ...detailWidgets,
                    const SizedBox(height: 16),
                    // Buttons for Join/Leave/Enter
                    buildActionButtons(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }



  Future<void> createGameSession() async {
    final response = await http.post(
      Uri.parse('$backendUrl/game_sessions/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'size': 5}), // Default size is 5
    );

    if (response.statusCode == 200) {
      final sessionData = jsonDecode(response.body);
      showMessage("Session created: ${sessionData['session_id']}");
      await fetchGameSessions();
    } else {
      showMessage("Failed to create session: ${response.body}");
    }
  }
}
