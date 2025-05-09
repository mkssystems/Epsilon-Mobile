import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:epsilon_mobile/services/api_service.dart';

class TilePlacementScreen extends StatefulWidget {
  final String sessionId;
  final String clientId;

  const TilePlacementScreen({
    super.key,
    required this.sessionId,
    required this.clientId,
  });

  @override
  _TilePlacementScreenState createState() => _TilePlacementScreenState();
}

class _TilePlacementScreenState extends State<TilePlacementScreen> {
  late WebSocketChannel channel;
  List<dynamic> players = [];
  bool allReady = false;
  bool countdownStarted = false;
  int countdown = 5;

  @override
  void initState() {
    super.initState();

    // Establish WebSocket connection using ApiService.baseUrl explicitly
    final websocketUrl = Uri.parse(
      "${ApiService.baseUrl.replaceAll('http', 'ws')}/ws/${widget.sessionId}/${widget.clientId}",
    );

    channel = IOWebSocketChannel.connect(websocketUrl);

    // Explicitly handle incoming WebSocket messages
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

    // Explicitly notify backend that intro is completed
    channel.sink.add(jsonEncode({"type": "intro_completed"}));
  }

  // Explicit countdown logic for temporary testing
  void startCountdown() {
    countdownStarted = true;
    Future.periodic(const Duration(seconds: 1), (timer) {
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
      appBar: AppBar(title: const Text('Tile Placement')),
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
