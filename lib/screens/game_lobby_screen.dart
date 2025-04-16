import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'game.dart'; // Add this import at the top
import 'package:epsilon_mobile/models/game_character.dart';
import 'package:epsilon_mobile/services/api_service.dart';


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
String creatorClientId = '';


class _GameLobbyScreenState extends State<GameLobbyScreen> {
  final String backendUrl = 'https://epsilon-poc-2.onrender.com/api';
  late IOWebSocketChannel channel;
  List<dynamic> players = [];
  List<GameCharacter> availableCharacters = [];
  bool isLoadingCharacters = true;
  bool allReady = false;
  bool myReadyStatus = false;
  bool loading = true;
  String? selectedCharacterId; // Explicitly track selected character

  late ApiService apiService;


  Future<void> submitCharacterSelection() async {
    if (selectedCharacterId == null) {
      showMessage('Please select a character first.');
      return;
    }

    try {
      await apiService.selectCharacter(
        widget.sessionId,
        widget.clientId,
        selectedCharacterId!,
      );
      showMessage('Character selected successfully!');
    } catch (e) {
      showMessage('Failed to select character: $e');
    }
  }


  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();

    apiService = ApiService(baseUrl: backendUrl);

    fetchCurrentStatus().then((_) {
      connectWebSocket();
    });
    fetchCharacters(); // clearly add this line to fetch characters explicitly
  }
  Future<void> fetchCharacters() async {
    try {
      final characters = await apiService.fetchAvailableCharacters(widget.sessionId);
      setState(() {
        availableCharacters = characters;
        isLoadingCharacters = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCharacters = false;
      });
      print('Error fetching characters: $e');
      showMessage('Failed to load available characters.');
    }
  }



  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  void connectWebSocket() {
    channel = IOWebSocketChannel.connect(
      Uri.parse('wss://epsilon-poc-2.onrender.com/ws/${widget.sessionId}/${widget.clientId}'),
    );

    channel.stream.listen((message) {
      final data = jsonDecode(message);

      if (data != null && data['players'] != null) {
        setState(() {
          players = List.from(data['players']);
          allReady = data['all_ready'] ?? false;
          myReadyStatus = players
              .firstWhere(
                (player) => player['client_id'].toString() == widget.clientId.toString(),
            orElse: () => {'ready': false},
          )['ready'];
          loading = false;
        });
      }

      // Explicitly handle new "game_started" event
      if (data != null && data['event'] == 'game_started') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Game()),
        );
      }
    }, onError: (error) {
      print("WebSocket error: $error");
    });

  }



  Future<void> fetchCurrentStatus() async {
    // Fetch the client state first to get the creatorClientId explicitly
    final response = await http.get(
      Uri.parse('$backendUrl/game_sessions/client_state/${widget.clientId}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        creatorClientId = data['session_details']['creator_client_id'] ?? '';
      });

      // Next, fetch current readiness status
      final statusResponse = await http.get(
        Uri.parse('$backendUrl/game_sessions/${widget.sessionId}/status'),
      );

      if (statusResponse.statusCode == 200) {
        final statusData = jsonDecode(statusResponse.body);
        setState(() {
          players = statusData['players'];
          allReady = statusData['all_ready'];
          myReadyStatus = players
              .firstWhere(
                (player) => player['client_id'].toString() == widget.clientId.toString(),
            orElse: () => {'ready': false},
          )['ready'];
          loading = false;
        });
      } else {
        setState(() => loading = false);
        showMessage('Failed to fetch readiness status.');
      }
    } else {
      setState(() => loading = false);
      showMessage('Failed to fetch session details.');
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
              onPressed: () async {
                Navigator.pop(context);
                // Call backend explicitly to broadcast the game start
                await http.post(Uri.parse('$backendUrl/game_sessions/${widget.sessionId}/start_game'));

                // The creator also directly moves into the game
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Game()),
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
            // <-- Inserted New Character Selection Widget here -->
            if (isLoadingCharacters)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableCharacters.length,
                  itemBuilder: (context, index) {
                    final character = availableCharacters[index];
                    bool isSelected = character.id == selectedCharacterId; // Check if selected
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCharacterId = character.id; // Set the selected character explicitly
                        });
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.blueAccent : Colors.transparent, // Highlight selected character
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.asset(character.portraitPath, fit: BoxFit.cover),
                            ),
                            Text(
                              character.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.blueAccent : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // End of New Widget
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
                    onPressed: submitCharacterSelection, // <-- Add this line explicitly
                    child: const Text('Confirm Character Selection'),
                  ),
                  const SizedBox(height: 10),
                  if (widget.clientId == creatorClientId) ...[
                    ElevatedButton(
                      onPressed: allReady ? showStartGameDialog : null,
                      child: const Text('Start Game'),
                    ),
                  ],
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

}