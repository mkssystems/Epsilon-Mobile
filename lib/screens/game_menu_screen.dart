import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';

class GameMenuScreen extends StatefulWidget {
  const GameMenuScreen({super.key});

  @override
  _GameMenuScreenState createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  bool isConnected = false;
  final TextEditingController sessionIdController = TextEditingController();
  String connectionMessage = "";

  final String backendUrl = 'https://epsilon-poc-2.onrender.com/api'; // backend URL corrected earlier

  Future<void> joinGameSession(String targetSessionId) async {
    final clientId = const Uuid().v4(); // Unique client identifier
    final response = await http.post(
      Uri.parse('$backendUrl/game_sessions/$targetSessionId/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'client_id': clientId}),
    );

    if (response.statusCode == 200) {
      setState(() {
        isConnected = true;
        connectionMessage = "Successfully connected to session!";
      });
    } else {
      setState(() {
        isConnected = false;
        connectionMessage = "Failed to connect: ${response.body}";
      });
    }
  }

  @override
  void dispose() {
    sessionIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Menu')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: sessionIdController,
              decoration: const InputDecoration(
                labelText: "Enter Game Session ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final enteredId = sessionIdController.text.trim();
                if (enteredId.isNotEmpty) {
                  joinGameSession(enteredId);
                } else {
                  setState(() {
                    connectionMessage = "Please enter a valid session ID.";
                  });
                }
              },
              child: const Text('Join Game Session'),
            ),
            const SizedBox(height: 20),
            Text(
              connectionMessage,
              style: TextStyle(
                color: isConnected ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
