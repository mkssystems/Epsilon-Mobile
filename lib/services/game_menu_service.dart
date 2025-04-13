import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class GameMenuService {
  final String backendUrl = 'https://epsilon-poc-2.onrender.com/api';

  Future<String> getOrCreateClientId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedClientId = prefs.getString('client_id');
    if (storedClientId == null) {
      storedClientId = const Uuid().v4();
      await prefs.setString('client_id', storedClientId);
    }
    return storedClientId;
  }

  Future<List<dynamic>> fetchGameSessions() async {
    final response = await http.get(Uri.parse('$backendUrl/game_sessions'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['sessions'];
    } else {
      throw Exception('Failed to load sessions');
    }
  }

  Future<void> createGameSession({
    required int size,
    required String creatorClientId,
    required String scenarioName,
    required String difficulty,
    required int maxPlayers,
  }) async {
    final response = await http.post(
      Uri.parse('$backendUrl/game_sessions/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'size': size,
        'creator_client_id': creatorClientId,
        'scenario_name': scenarioName,
        'difficulty': difficulty,
        'max_players': maxPlayers,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create session: ${response.body}');
    }
  }

  Future<String?> checkClientSessionState(String clientId) async {
    final response = await http.get(Uri.parse('$backendUrl/game_sessions/client_state/$clientId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['connected_session'];
    } else {
      throw Exception('Failed to check session state');
    }
  }
}
