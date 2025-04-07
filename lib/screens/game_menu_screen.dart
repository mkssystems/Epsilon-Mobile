import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class GameMenuScreen extends StatefulWidget {
  const GameMenuScreen({super.key});

  @override
  _GameMenuScreenState createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  bool isConnected = false;
  String connectionMessage = "";

  final String backendUrl = 'https://epsilon-poc-2.onrender.com/api';
  List<dynamic> gameSessions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // Keep screen awake
    fetchGameSessions();
  }

  Future<String> getOrCreateClientId() async {
    final prefs = await SharedPreferences.getInstance();
    String? clientId = prefs.getString('client_id');
    if (clientId == null) {
      clientId = const Uuid().v4();
      await prefs.setString('client_id', clientId);
    }
    return clientId;
  }

  Future<void> fetchGameSessions() async {
    setState(() {
      loading = true;
      connectionMessage = "";
    });
    final response = await http.get(Uri.parse('$backendUrl/game_sessions'));
    if (response.statusCode == 200) {
      setState(() {
        gameSessions = jsonDecode(response.body)['sessions'];
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
        connectionMessage = "Failed to load sessions";
      });
    }
  }

  Future<void> joinGameSession(String targetSessionId) async {
    final clientId = await getOrCreateClientId();
    final response = await http.post(
      Uri.parse('$backendUrl/game_sessions/$targetSessionId/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'client_id': clientId}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        isConnected = true;
        connectionMessage =
        "Successfully connected! Session ID: ${responseData['session_id']}";
      });

      showSessionDetails(responseData);
    } else {
      setState(() {
        isConnected = false;
        connectionMessage = "Failed to connect: ${response.body}";
      });
    }
  }

  Future<void> createGameSession() async {
    int? mapSize = 5; // default value
    final controller = TextEditingController(text: '5');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Game Session"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Enter Map Size (4-10)"),
          onChanged: (value) {
            mapSize = int.tryParse(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Create"),
          ),
        ],
      ),
    );

    if (mapSize == null || mapSize! < 4 || mapSize! > 10) {
      setState(() {
        connectionMessage = "Invalid map size. Please enter a value between 4 and 10.";
      });
      return;
    }

    final response = await http.post(
      Uri.parse('$backendUrl/game_sessions/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'size': mapSize}),
    );

    if (response.statusCode == 200) {
      setState(() {
        connectionMessage = "Game session created successfully!";
      });
      fetchGameSessions();
    } else {
      setState(() {
        connectionMessage = "Failed to create session: ${response.body}";
      });
    }
  }

  void showSessionDetails(Map<String, dynamic> details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Session Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Session ID: ${details['session_id']}"),
            Text("Map Seed: ${details['map_seed']}"),
            Text("Labyrinth ID: ${details['labyrinth_id']}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
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
            icon: const Icon(Icons.refresh),
            onPressed: fetchGameSessions,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: createGameSession,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: gameSessions.isEmpty
                ? const Center(child: Text('No available game sessions.'))
                : ListView.builder(
              itemCount: gameSessions.length,
              itemBuilder: (context, index) {
                final session = gameSessions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    title: Text(session['name'] ?? session['id'].toString()),
                    trailing: ElevatedButton(
                      onPressed: () => joinGameSession(session['id'].toString()),
                      child: const Text('Join'),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              connectionMessage,
              style: TextStyle(
                color: connectionMessage.toLowerCase().contains('fail')
                    ? Colors.red
                    : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}