import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_character.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<List<GameCharacter>> fetchAvailableCharacters(String sessionId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/game_sessions/$sessionId/available_characters'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['available_characters'] as List;
      return data.map((characterJson) => GameCharacter.fromJson(characterJson)).toList();
    } else {
      throw Exception('Failed to load characters');
    }
  }

  Future<void> selectCharacter(String sessionId, String clientId, String entityId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/game_sessions/$sessionId/select_character'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'client_id': clientId, 'entity_id': entityId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to select character');
    }
  }
}
