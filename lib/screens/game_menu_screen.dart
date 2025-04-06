// lib/screens/game_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';

class GameMenuScreen extends StatefulWidget {
  @override
  _GameMenuScreenState createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  bool isConnected = false;
  String sessionId = '';
  String mapSeed = '';
  String labyrinthId = '';
  final String backendUrl = 'https://yourbackend.com/api'; // your backend url

  Future<void> joinGameSession(int targetSessionId) async {
    final clientId = Uuid().v4(); // unique identifier for mobile client

    final response = await http.post(
      Uri.parse('$backendUrl/game_sessions/$targetSessionId/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'client_id': clientId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        isConnected = true;
        sessionId = data['session_id'].toString();
        mapSeed = data['map_seed'];
        labyrinthId = data['labyrinth_id'].toString();
      });
    } else {
      // Handle errors accordingly
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Game Menu')),
      body: Center(
        child: isConnected
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Connected to Session: $sessionId'),
            Text('Map Seed: $mapSeed'),
            Text('Labyrinth ID: $labyrinthId'),
          ],
        )
            : ElevatedButton(
          onPressed: () => joinGameSession(1), // example session ID
          child: Text('Join Game'),
        ),
      ),
    );
  }
}
