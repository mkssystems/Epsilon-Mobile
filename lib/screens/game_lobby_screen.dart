import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GameLobbyScreen extends StatefulWidget {
  final String sessionId;
  final String clientId;

  const GameLobbyScreen({
    super.key,
    required this.sessionId,
    required this.clientId,
  });

  @override
  _GameLobbyScreenState createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  final String backendUrl = 'https://epsilon-poc-2.onrender.com/api';
  late IOWebSocketChannel channel;
  List<dynamic> players = [];
  bool allReady = false;
  bool myReadyStatus = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    connectWebSocket();
    fetchCurrentStatus();
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  void connectWebSocket() {
    channel = IOWebSocketChannel.connect(
      Uri.parse('wss://epsilon-poc-2.onrender.com/ws/${widget.sessionId}'),
    );

    channel.stream.listen((message) {
      final data = jsonDecode(message);
      setState(() {
        players = data['players'];
        allReady = data['all_ready'];
        myReadyStatus = players
            .firstWhere(
              (player) => player['client_id'] == widget.clientId,
          orElse: () => {'ready': false},
        )['ready'];
        loading = false;
      });
    });
  }

  Future<void> fetchCurrentStatus() async {
    final response = await http.get(
      Uri.parse('$backendUrl/game_sessions/${widget.sessionId}/status'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        players = data['players'];
        allReady = data['all_ready'];
        myReadyStatus = players
            .firstWhere(
              (player) => player['client_id'] == widget.clientId,
          orElse: () => {'ready': false},
        )['ready'];
        loading = false;
      });
    }
  }

  Future<void> toggleMyReadiness() async {
    await http.post(
      Uri.parse('$backendUrl/game_sessions/${widget.sessionId}/toggle_readiness'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'client_id': widget.clientId,
        'ready': !myReadyStatus,
      }),
    );
    // Updates come automatically via WebSocket
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Lobby (${widget.sessionId})'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return ListTile(
                  leading: Icon(
                    player['ready'] ? Icons.check_circle : Icons.cancel,
                    color: player['ready'] ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    'Client ID: ${player['client_id']}',
                    style: TextStyle(
                        fontWeight: player['client_id'] == widget.clientId
                            ? FontWeight.bold
                            : FontWeight.normal),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: toggleMyReadiness,
                  child: Text(myReadyStatus ? 'Not Ready' : 'I am Ready'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: allReady ? () {} : null, // Disabled until all ready
                  child: const Text('Start Game'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
