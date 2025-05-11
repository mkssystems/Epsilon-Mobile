// lib/services/game_menu_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class GameMenuService {
  final String backendUrl = 'https://epsilon-poc-2.onrender.com/api';

  /// Retrieves existing clientId or generates a new one if not present.
  Future<String> getOrCreateClientId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedClientId = prefs.getString('client_id');
    if (storedClientId == null) {
      storedClientId = const Uuid().v4();
      await prefs.setString('client_id', storedClientId);
    }
    return storedClientId;
  }

  /// Gets stored clientId synchronously (without async calls after initialization).
  Future<String?> getClientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('client_id');
  }

  /// Explicitly stores sessionId.
  Future<void> setSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_id', sessionId);
  }

  /// Retrieves stored sessionId.
  Future<String?> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_id');
  }

  /// Stores both sessionId and clientId explicitly when a user joins a session.
  Future<void> storeSessionAndClientId(String sessionId, String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_id', sessionId);
    await prefs.setString('client_id', clientId);
  }

  /// Clears both sessionId and clientId explicitly when user leaves a session.
  Future<void> clearSessionAndClientId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_id');
    // Note: typically clientId might remain permanent; clear only if explicitly required.
  }

  /// Backend API methods (unchanged, provided for completeness):
  Future<List<dynamic>> fetchGameSessions(String clientId) async {
    final response = await http.get(Uri.parse('$backendUrl/game_sessions/user/$clientId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['sessions'];
    } else {
      throw Exception('Failed to load sessions');
    }
  }

  Future<List<dynamic>> fetchJoinedGameSessions(String clientId) async {
    final response = await http.get(Uri.parse('$backendUrl/game_sessions/user/$clientId/joined'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['sessions'];
    } else {
      throw Exception('Failed to load joined sessions');
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
