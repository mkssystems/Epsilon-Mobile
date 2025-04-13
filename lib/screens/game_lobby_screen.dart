import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'game.dart'; // Add this import at the top

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

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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
              (player) => player['client_id'].toString() == widget.clientId.toString(),
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
              (player) => player['client_id'].toString() == widget.clientId.toString(),
          orElse: () => {'ready': false},
        )['ready'];
        loading = false;
      });
    }
  }


  Future<void> toggleMyReadiness() async {
    final bool newReadyStatus = !myReadyStatus;

    final response = await http.post(
      Uri.parse('$backendUrl/game_sessions/${widget.sessionId}/toggle_readiness'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'client_id': widget.clientId,
        'ready': newReadyStatus,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        players = data['players'];
        allReady = data['all_ready'];
        myReadyStatus = players
            .firstWhere(
              (player) => player['client_id'].toString() == widget.clientId.toString(),
          orElse: () => {'ready': false},
        )['ready'];
      });
    } else {
      showMessage('Failed to update readiness.');
    }
  }

  void showStartGameDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Start Game"),
          content: const Text("Are you sure you want to start the game now?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Not yet..."),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Game(),
                  ),
                );
              },
              child: const Text("Yes, let's go!"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop && Navigator.canPop(context)) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Game Lobby'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.grey[300],
              padding: const EdgeInsets.all(12),
              child: Text(
                'Session ID: ${widget.sessionId}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
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
                            : FontWeight.normal,
                      ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myReadyStatus ? Colors.red : Colors.green,
                    ),
                    onPressed: toggleMyReadiness,
                    child: Text(myReadyStatus ? 'Not Ready' : 'I am Ready'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: allReady ? showStartGameDialog : null,
                    child: const Text('Start Game'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }





}