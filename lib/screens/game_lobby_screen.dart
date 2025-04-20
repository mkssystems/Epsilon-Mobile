// lib/screens/game_lobby_screen.dart

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'game.dart'; // Add this import at the top
import 'package:epsilon_mobile/models/game_character.dart';
import 'package:epsilon_mobile/services/api_service.dart';
import 'package:epsilon_mobile/screens/intro_screen.dart';



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
// Now tracks both the entity_id and locked status explicitly.
  Map<String, Map<String, dynamic>> selectedCharactersByClient = {};


  late ApiService apiService;

// Checks explicitly if a character is confirmed (locked) by any player.
  bool isCharacterConfirmed(String characterId) {
    return selectedCharactersByClient.values.any((selection) =>
    selection['entity_id'] == characterId && selection['locked'] == true);
  }



// Fetch selected characters along with their locked (confirmed) status explicitly.
  // Explicitly fetch currently selected characters from the backend
  Future<void> fetchSelectedCharacters() async {
    final response = await http.get(
      Uri.parse('$backendUrl/game_sessions/${widget.sessionId}/selected_characters'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        selectedCharactersByClient.clear();

        for (var item in data['selected_characters']) {
          if (item['entity_id'] != null) {
            selectedCharactersByClient[item['client_id']] = {
              'entity_id': item['entity_id'],
              'locked': item['locked'],
            };
          }
        }

        // Explicitly validate if the previously selected character is still valid
        final currentSelection = selectedCharactersByClient[widget.clientId]?['entity_id'];
        if (currentSelection == null || (selectedCharacterId != null && currentSelection != selectedCharacterId)) {
          selectedCharacterId = null;  // Explicitly reset local selection
        }
      });
    } else {
      showMessage('Failed to fetch selected characters.');
    }
  }





  Future<void> handleCharacterSelection() async {
    if (selectedCharacterId == null) {
      showMessage('Please select a character first.');
      return;
    }

    // Check explicitly if the currently selected character matches what is recorded in the backend
    bool isAlreadySelected = selectedCharactersByClient[widget.clientId]?['entity_id'] == selectedCharacterId;

    if (isAlreadySelected) {
      // Explicitly request backend to release character selection for this client
      final response = await http.post(
        Uri.parse('$backendUrl/game_sessions/${widget.sessionId}/release_character?client_id=${widget.clientId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        showMessage('Character deselected successfully!');

        setState(() {
          selectedCharacterId = null;
          selectedCharactersByClient.remove(widget.clientId);
        });

        await fetchSelectedCharacters();
        await fetchCharacters();
      } else {
        // Explicitly handle backend message
        final error = jsonDecode(response.body)['detail'] ?? response.body;
        showMessage('Failed to deselect character: $error');
        await fetchSelectedCharacters(); // Refresh explicitly even if failed
      }
    } else {
      // Explicitly handle confirming a new character selection
      try {
        await apiService.selectCharacter(
          widget.sessionId,
          widget.clientId,
          selectedCharacterId!,
        );
        showMessage('Character selected successfully!');

        // Explicitly refresh immediately after backend confirmation
        await fetchSelectedCharacters();
        await fetchCharacters();
      } catch (e) {
        showMessage('Failed to select character: $e');
      }
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
    fetchCharacters();
    fetchSelectedCharacters(); // <-- explicitly added this line
  }


  Future<void> fetchCharacters() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/game_sessions/${widget.sessionId}/all_characters'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          availableCharacters = (data['all_characters'] as List)
              .map((json) => GameCharacter.fromJson(json))
              .toList();
          isLoadingCharacters = false;
        });
      } else {
        throw Exception('Failed to load all characters');
      }
    } catch (e) {
      setState(() => isLoadingCharacters = false);
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

        // Explicitly refresh selected characters on every player update
        fetchSelectedCharacters();
      }

      if (data != null && data['event'] == 'game_started') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IntroScreen()),
        );

      }

      // Explicit refresh on character selection/release events
      if (data != null &&
          (data['event'] == 'character_selected' || data['event'] == 'character_released')) {
        fetchSelectedCharacters();
        fetchCharacters(); // refresh available characters explicitly
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

    final payload = {
      'client_id': widget.clientId,
      'ready': newReadyStatus,
    };

    print('Sending toggle readiness payload explicitly: ${jsonEncode(payload)}');

    final response = await http.post(
      Uri.parse('$backendUrl/game_sessions/${widget.sessionId}/toggle_readiness'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        players = data['players'];
        allReady = data['all_ready'];
        myReadyStatus = newReadyStatus;
      });
    } else {
      final error = jsonDecode(response.body)['detail'] ?? response.body;
      showMessage('Failed to update readiness: $error');
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
                // ONLY trigger backend broadcast, no direct navigation here
                await http.post(Uri.parse('$backendUrl/game_sessions/${widget.sessionId}/start_game'));
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
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableCharacters.length,
                  itemBuilder: (context, index) {
                    final character = availableCharacters[index];
                    bool isSelectedByMe = character.id == selectedCharacterId;

                    // Explicitly check if the character is confirmed by any player
                    bool isConfirmed = isCharacterConfirmed(character.id);

                    // Explicitly checks if the character is selected (confirmed or unconfirmed) by another client.
                    bool isTakenByOthers = selectedCharactersByClient.entries.any(
                          (entry) => entry.value['entity_id'] == character.id && entry.key != widget.clientId,
                    );


                    // Explicitly handle tap functionality correctly
                    final bool selectable = !isConfirmed && !isTakenByOthers;

                    return GestureDetector(
                      // Only allow selecting a character if it is selectable and the player is NOT ready
                      onTap: (selectable && !myReadyStatus)
                          ? () {
                        // Explicitly update local selection state
                        setState(() {
                          selectedCharacterId = character.id;
                        });
                      }
                          : null,  // explicitly disable tap if player is ready or character isn't selectable
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelectedByMe ? Colors.blueAccent : Colors.transparent,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: selectable ? Colors.white : Colors.grey.shade300,
                        ),
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                Expanded(
                                  child: Opacity(
                                    opacity: selectable ? 1.0 : 0.4, // explicitly safer opacity-based greying-out
                                    child: Image.asset(
                                      character.portraitPath,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                                Text(
                                  character.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isSelectedByMe ? FontWeight.bold : FontWeight.normal,
                                    color: selectable
                                        ? (isSelectedByMe ? Colors.blueAccent : Colors.black)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            if (isConfirmed)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.white.withOpacity(0.6),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Confirmed ✔️',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            if (!isConfirmed && isTakenByOthers)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.white.withOpacity(0.6),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Taken',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
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
                  final clientId = player['client_id'];

                  // Explicitly get the selected character ID and lock status for each client.
                  final characterInfo = selectedCharactersByClient[clientId];
                  final characterId = characterInfo?['entity_id'];
                  final locked = characterInfo?['locked'] ?? false;

                  // Explicitly handle the case where no character matches by returning null safely.
                  final matchedCharacter = availableCharacters.cast<GameCharacter?>().firstWhere(
                        (char) => char!.id == characterId,
                    orElse: () => null,
                  );


                  final characterName = matchedCharacter?.name ?? "Not selected";
                  final characterStatus = locked ? " (Confirmed)" : characterId != null ? " (Selected)" : "";

                  return ListTile(
                    // Shows an icon indicating if the player is ready or not
                    leading: Icon(
                      player['ready'] ? Icons.check_circle : Icons.cancel,
                      color: player['ready'] ? Colors.green : Colors.red,
                    ),

                    // The player's Client ID displayed in a special styled container if it's the current user's ID
                    title: clientId == widget.clientId
                        ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Padding around the Client ID
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent, width: 2), // Blue accent border
                        borderRadius: BorderRadius.circular(8), // Rounded corners for aesthetic appeal
                        color: Colors.blueAccent.withOpacity(0.1), // Light blue background for subtle emphasis
                      ),
                      child: Text(
                        'Client ID: $clientId',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, // Keep bold for further distinction
                          color: Colors.blueAccent, // Match the border with blue accent color
                        ),
                      ),
                    )
                        : Text('Client ID: $clientId'), // Regular text style for other player IDs

                    // Subtitle showing the player's selected character and its status (selected/confirmed)
                    subtitle: Text('Character: $characterName$characterStatus'),
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
                  if (!myReadyStatus) ...[
                    ElevatedButton(
                      // Disable button explicitly if no character selected or if player is ready
                      onPressed: (selectedCharacterId == null || myReadyStatus)
                          ? null
                          : handleCharacterSelection,
                      child: Text(
                        // Explicitly update button text based on selection status
                        selectedCharacterId != null &&
                            selectedCharactersByClient[widget.clientId]?['entity_id'] == selectedCharacterId
                            ? 'Deselect Character'
                            : 'Confirm Character Selection',
                      ),
                    ),


                  ],


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