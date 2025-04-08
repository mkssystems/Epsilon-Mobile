import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart'; // For Clipboard usage
import '../utils/app_guide.dart';
import 'game_lobby_screen.dart'; // <-- Newly added import

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
    await checkClientSessionState();  // Re-check client state clearly each time dialog is opened

    if (!mounted) return; // Safety check

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Session Details"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Session ID: ${session['id']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
              const Divider(),
              ...session.entries
                  .where((entry) => entry.key != 'id')
                  .map((entry) => Text("${entry.key}: ${entry.value}"))
                  .toList(),
              const SizedBox(height: 20),

              // Action buttons clearly based on refreshed state
              if (currentSessionId == null || currentSessionId != session['id'])
                ElevatedButton(
                  onPressed: () => joinGameSession(session['id']),
                  child: const Text('Join'),
                ),
              if (currentSessionId == session['id']) ...[
                ElevatedButton(
                  onPressed: leaveGameSession,
                  child: const Text('Leave'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog first
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
            ],
          ),
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
