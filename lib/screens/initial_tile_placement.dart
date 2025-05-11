// lib/screens/initial_tile_placement.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:epsilon_mobile/services/websocket_service.dart';
import 'package:epsilon_mobile/services/api_service.dart'; // explicitly added
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;


class InitialTilePlacementScreen extends StatefulWidget {
  const InitialTilePlacementScreen({super.key});

  @override
  _InitialTilePlacementScreenState createState() => _InitialTilePlacementScreenState();
}

class _InitialTilePlacementScreenState extends State<InitialTilePlacementScreen> {
  final webSocketService = WebSocketService();
  final apiService = ApiService(); // Explicitly use ApiService

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

    await sendIntroCompleted();
    setState(() {
      loading = false;
    });
  }

  Future<void> sendIntroCompleted() async {
    final url = Uri.parse(
      '${apiService.instanceBaseUrl}/game/$sessionId/player-ready',
    );

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
      setState(() {
        if (decodedMessage['event'] == 'all_players_ready') {
          allReady = true;
          startCountdown();
        } else if (decodedMessage['players'] != null) {
          players = decodedMessage['players'];
        }
      });
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
        child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 18)),
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!allReady && players.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Waiting for players...', style: TextStyle(fontSize: 20)),
              ),
            ),
          if (!allReady && players.isNotEmpty)
            Expanded(
              child: ListView.builder(
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
          if (allReady && countdownStarted && countdown > 0)
            Center(
              child: Text(
                'Place your first tile in $countdown seconds...',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          if (countdown == 0)
            const Center(
              child: Text(
                'Lay the first tile on the table!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
