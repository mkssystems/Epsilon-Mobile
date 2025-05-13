// lib/screens/initial_tile_placement.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:epsilon_mobile/services/websocket_service.dart';
import 'package:epsilon_mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class InitialTilePlacementScreen extends StatefulWidget {
  const InitialTilePlacementScreen({super.key});

  @override
  _InitialTilePlacementScreenState createState() => _InitialTilePlacementScreenState();
}

class _InitialTilePlacementScreenState extends State<InitialTilePlacementScreen> {
  final webSocketService = WebSocketService();
  final apiService = ApiService();

  List<dynamic> players = [];
  bool allReady = false;
  bool countdownStarted = false;
  int countdown = 5;

  late String sessionId;
  late String clientId;

  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadIds();
    webSocketService.addListener(handleWebSocketMessage);
  }

  Future<void> loadIds() async {
    final prefs = await SharedPreferences.getInstance();
    sessionId = prefs.getString('session_id') ?? '';
    clientId = prefs.getString('client_id') ?? '';

    if (sessionId.isEmpty || clientId.isEmpty) {
      setState(() {
        errorMessage = 'Session or Client ID missing!';
        loading = false;
      });
      print('Error: Session or Client ID missing!');
      return;
    }

    // Request initial readiness status explicitly
    webSocketService.sendMessage({"type": "request_readiness"});

    await sendIntroCompleted();
    setState(() {
      loading = false;
    });
  }

  Future<void> sendIntroCompleted() async {
    final url = Uri.parse('${apiService.instanceBaseUrl}/game/$sessionId/player-ready');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id': clientId,
          'turn_number': 0,
          'phase': 'initial_placement'
        }),
      );

      if (response.statusCode == 200) {
        print('[DEBUG] Player readiness confirmed explicitly via ApiService.');
      } else {
        setState(() {
          errorMessage = 'HTTP error: ${response.statusCode} - ${response.body}';
        });
        print('[ERROR] Failed explicitly to confirm readiness: ${response.body}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to send intro completed message: $e';
      });
      print('Error sending intro completed message: $e');
    }
  }

  void handleWebSocketMessage(dynamic message) {
    try {
      final decodedMessage = message is String ? jsonDecode(message) : message;

      if (decodedMessage['type'] == 'readiness_status') {
        setState(() {
          players = decodedMessage['players'];
          allReady = decodedMessage['all_ready'];
          if (allReady) {
            startCountdown();
          }
        });
        print('[INFO] Readiness status updated from WebSocket.');
      }
      // Explicitly handle the event when all players become ready
      else if (decodedMessage['event'] == 'all_players_ready') {
        setState(() {
          allReady = true;
          startCountdown();
        });
        print('[INFO] All players are now ready.');
      }
      // Explicitly handle general players list updates
      else if (decodedMessage['players'] != null) {
        setState(() {
          players = decodedMessage['players'];
        });
        print('[INFO] Players list updated from WebSocket.');
      }

      print('WebSocket message received: $decodedMessage');
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to handle WebSocket message: $e';
      });
      print('Error decoding WebSocket message: $e');
    }
  }

  void startCountdown() {
    if (!countdownStarted) {
      countdownStarted = true;
      Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          countdown--;
          if (countdown == 0) {
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    webSocketService.removeListener(handleWebSocketMessage);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Initial Tile Placement')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red, fontSize: 18),
        ),
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Display countdown timer clearly when all players are ready
          if (allReady && countdownStarted && countdown > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Place your first tile in $countdown seconds...',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

          // Display prompt when countdown finishes
          if (countdown == 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                'Lay the first tile on the table!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

          // Always display connected players
          Expanded(
            child: players.isEmpty
                ? const Center(
              child: Text(
                'Waiting for players...',
                style: TextStyle(fontSize: 20),
              ),
            )
                : ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return ListTile(
                  title: Text(player['client_id']),
                  trailing: Icon(
                    player['ready'] ? Icons.check_circle : Icons.hourglass_empty,
                    color: player['ready'] ? Colors.green : Colors.orange,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
