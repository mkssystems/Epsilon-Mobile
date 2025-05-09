// lib/services/game_menu_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class GameMenuService {
  final String backendUrl = 'https://epsilon-poc-2.onrender.com/api';

  /// Retrieves existing clientId from shared preferences or generates and stores a new one.
  Future<String> getOrCreateClientId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedClientId = prefs.getString('client_id');
    if (storedClientId == null) {
      storedClientId = const Uuid().v4();
      await prefs.setString('client_id', storedClientId);
    }
    return storedClientId;
  }

  /// Retrieves clientId from shared preferences, returns null if not set.
  Future<String?> getClientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('client_id');
  }

  /// Stores sessionId explicitly into shared preferences.
  Future<void> setSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_id', sessionId);
  }

  /// Retrieves sessionId explicitly from shared preferences.
  Future<String?> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_id');
  }

  /// Fetches available game sessions from the backend for the given clientId.
  Future<List<dynamic>> fetchGameSessions(String clientId) async {
    final response = await http.get(Uri.parse('$backendUrl/game_sessions/user/$clientId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['sessions'];
    } else {
      throw Exception('Failed to load sessions');
    }
  }

  /// Fetches game sessions joined by the given clientId from the backend.
  Future<List<dynamic>> fetchJoinedGameSessions(String clientId) async {
    final response = await http.get(Uri.parse('$backendUrl/game_sessions/user/$clientId/joined'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['sessions'];
    } else {
      throw Exception('Failed to load joined sessions');
    }
  }

  /// Creates a new game session with specified parameters.
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

  /// Joins an existing game session identified by sessionId for the given clientId.
  Future<void> joinGameSession(String clientId, String sessionId) async {
    final response = await http.post(
      Uri.parse('$backendUrl/game_sessions/$sessionId/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'client_id': clientId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to join session: ${response.body}');
    }
  }

  /// Leaves the currently joined game session for the given clientId.
  Future<void> leaveGameSession(String clientId) async {
    final response = await http.post(
      Uri.parse('$backendUrl/game_sessions/leave'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'client_id': clientId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to leave session: ${response.body}');
    }
  }

  /// Checks and retrieves the current session state for the clientId.
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
