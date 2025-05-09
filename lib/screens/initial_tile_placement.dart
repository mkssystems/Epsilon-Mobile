// lib/screens/initial_tile_placement.dart

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'package:epsilon_mobile/services/api_service.dart';
import 'package:epsilon_mobile/services/game_menu_service.dart';

class InitialTilePlacementScreen extends StatefulWidget {
  const InitialTilePlacementScreen({super.key});

  @override
  _InitialTilePlacementScreenState createState() => _InitialTilePlacementScreenState();
}

class _InitialTilePlacementScreenState extends State<InitialTilePlacementScreen> {
  late WebSocketChannel channel;
  final GameMenuService gameMenuService = GameMenuService();
  List<dynamic> players = [];
  bool allReady = false;
  bool countdownStarted = false;
  int countdown = 5;

  String? sessionId;
  String? clientId;

  @override
  void initState() {
    super.initState();
    initializeIds();
  }

  Future<void> initializeIds() async {
    sessionId = await gameMenuService.getSessionId();
    clientId = await gameMenuService.getClientId();

    if (sessionId != null && clientId != null) {
      setupWebSocket();
    } else {
      print('Session or Client ID missing!');
    }
  }

  void setupWebSocket() {
    final websocketUrl = Uri.parse(
      "${ApiService.baseUrl.replaceAll('http', 'ws')}/ws/$sessionId/$clientId",
    );

    channel = IOWebSocketChannel.connect(websocketUrl);

    channel.stream.listen((message) {
      final decodedMessage = jsonDecode(message);
      setState(() {
        if (decodedMessage['event'] == 'all_players_ready') {
          allReady = true;
          startCountdown();
        } else if (decodedMessage['players'] != null) {
          players = decodedMessage['players'];
        }
      });
    });

    channel.sink.add(jsonEncode({"type": "intro_completed"}));
  }

  void startCountdown() {
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

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Initial Tile Placement')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!allReady)
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