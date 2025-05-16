// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_character.dart';

class ApiService {
  /// Static base URL explicitly defined for general use (e.g., WebSocket connections)
  static const String baseUrl = 'https://epsilon-poc-2.onrender.com/api';

  /// Instance-specific base URL (allows flexibility for future customization)
  final String instanceBaseUrl;

  /// Constructor explicitly initializes the instance base URL,
  /// defaulting to the static baseUrl if not provided
  ApiService({this.instanceBaseUrl = baseUrl});

  /// Fetches available game characters explicitly from backend for a given session
  Future<List<GameCharacter>> fetchAvailableCharacters(String sessionId) async {
    final response = await http.get(Uri.parse(
        '$instanceBaseUrl/game_sessions/$sessionId/available_characters'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['available_characters'] as List;
      return data
          .map((characterJson) => GameCharacter.fromJson(characterJson))
          .toList();
    } else {
      throw Exception('Failed to load characters');
    }
  }

  /// Selects a character explicitly for a given session, client, and entity
  /// Sends parameters explicitly as query parameters due to backend expectations
  Future<void> selectCharacter(
      String sessionId, String clientId, String entityId) async {
    final url = Uri.parse(
      '$instanceBaseUrl/game_sessions/$sessionId/select_character'
          '?client_id=${Uri.encodeComponent(clientId)}'
          '&entity_id=${Uri.encodeComponent(entityId)}',
    );

    // Explicitly logs the constructed URL for debugging purposes
    print('ApiService explicitly sending POST request to URL: $url');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'}, // Content type explicitly set
      // No body explicitly included, as backend expects parameters via query
    );

    if (response.statusCode != 200) {
      print('Backend response explicitly: ${response.statusCode}, ${response.body}');
      throw Exception('Failed to select character: ${response.body}');
    }
  }

  /// Explicitly added method to fetch the current game session status from backend.
  /// Static method allows easy access without instantiating ApiService.
  static Future<Map<String, dynamic>> getGameSessionStatus(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/game_sessions/$sessionId/status'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load game session status: ${response.body}');
    }
  }
}
