// lib/screens/initial_tile_placement.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:epsilon_mobile/services/sync_manager.dart';
import 'package:epsilon_mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:epsilon_mobile/widgets/tile_visualization_widget.dart';
import 'package:epsilon_mobile/widgets/hold_to_confirm_button.dart';

class InitialTilePlacementScreen extends StatefulWidget {
  const InitialTilePlacementScreen({super.key});

  @override
  _InitialTilePlacementScreenState createState() => _InitialTilePlacementScreenState();
}

class _InitialTilePlacementScreenState extends State<InitialTilePlacementScreen> {
  final apiService = ApiService();

  late SyncManager syncManager;

  List<dynamic> players = [];
  bool allReady = false;
  bool countdownStarted = false;
  int countdown = 5;

  late String sessionId;
  late String clientId;

  bool loading = true;
  String? errorMessage;

  Map<String, dynamic>? currentTile;

  @override
  void initState() {
    super.initState();
    syncManager = SyncManager();
    syncManager.initializeSync();
    syncManager.registerListener(updateSyncState); // Move here explicitly!
    loadIds();
  }


  Future<void> sendTilePlacementConfirmed() async {
    final url = Uri.parse('${apiService.instanceBaseUrl}/game/$sessionId/player-ready');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id': clientId,
          'turn_number': 0,
          'phase': 'initial_tile_placed'
        }),
      );

      if (response.statusCode != 200) {
        setState(() {
          errorMessage = 'HTTP error: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to confirm tile placement: $e';
      });
    }
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
      return;
    }

    syncManager.initializeSync();

    await sendIntroCompleted();
    await fetchTilesToPlace();


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

      if (response.statusCode != 200) {
        setState(() {
          errorMessage = 'HTTP error: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to send intro completed message: $e';
      });
    }
  }

  Future<void> fetchTilesToPlace() async {
    final url = Uri.parse('${apiService.instanceBaseUrl}/game-state/$sessionId/tiles-to-place');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tilesToPlace = data['tiles_to_place'];

        if (tilesToPlace.isNotEmpty) {
          setState(() {
            currentTile = tilesToPlace.first;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to fetch tiles: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch tiles: $e';
      });
    }
  }

  void updateSyncState() {
    setState(() {
      players = syncManager.playerStatuses.entries.map((entry) => {
        'client_id': entry.key,
        'ready': entry.value,
      }).toList();

      allReady = syncManager.isEveryoneReady();

      print("[DEBUG SCREEN] allReady status: $allReady");
      print("[DEBUG SCREEN] players: $players");

      // Explicitly handle countdown start immediately upon all players ready
      if (allReady && !countdownStarted) {
        print("[DEBUG SCREEN] Starting countdown explicitly");
        startCountdown();
      }
    });
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
    syncManager.unregisterListener(updateSyncState);
    syncManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Initial Tile Placement')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 18)))
          : Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (allReady && countdownStarted && countdown > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Place your first tile in $countdown seconds...',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          if (currentTile != null)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Please place tile at (${currentTile!["x"]}, ${currentTile!["y"]}), type: ${currentTile!["type"]}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                TileVisualizationWidget(tileCode: currentTile!['tile_code'], size: 150),
              ],
            ),
          if (currentTile != null && countdown == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: HoldToConfirmButton(
                onConfirmed: () async {
                  await sendTilePlacementConfirmed();
                },
              ),
            ),
          Expanded(
            child: players.isEmpty
                ? const Center(child: Text('Waiting for players...', style: TextStyle(fontSize: 20)))
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
