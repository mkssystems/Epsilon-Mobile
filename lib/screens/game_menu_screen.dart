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

  final String backendUrl = 'https://epsilon-poc-2.onrender.com'; // Updated backend URL

  Future<void> joinGameSession(int targetSessionId) async {
    final clientId = Uuid().v4(); // Unique identifier for mobile client
    final response = await http.post(
      Uri.parse('$backendUrl/game_sessions/$targetSessionId/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'client_id': clientId}),
    );

    if (response.statusCode == 200) {
      // Handle successful connection
      setState(() {
        isConnected = true;
        // Parse and assign other relevant data from response if needed
      });
    } else {
      // Handle connection error
      setState(() {
        isConnected = false;
      });
      // Optionally, display an error message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build your widget tree here
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Menu'),
      ),
      body: Center(
        child: isConnected
            ? Text('Connected to game session.')
            : ElevatedButton(
          onPressed: () {
            // Replace 'yourSessionId' with the actual session ID you want to join
            joinGameSession(yourSessionId);
          },
          child: Text('Join Game Session'),
        ),
      ),
    );
  }
}
