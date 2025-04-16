import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_character.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<List<GameCharacter>> fetchAvailableCharacters(String sessionId) async {
    final response = await http.get(Uri.parse('$baseUrl/game_sessions/$sessionId/available_characters'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['available_characters'] as List;
      return data.map((characterJson) => GameCharacter.fromJson(characterJson)).toList();
    } else {
      throw Exception('Failed to load characters');
    }
  }

// Corrected method sending parameters explicitly as query parameters:
  Future<void> selectCharacter(String sessionId, String clientId, String entityId) async {
    final url = Uri.parse(
      '$baseUrl/game_sessions/$sessionId/select_character'
          '?client_id=${Uri.encodeComponent(clientId)}'
          '&entity_id=${Uri.encodeComponent(entityId)}',
    );

    print('ApiService explicitly sending GET request to URL: $url');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'}, // headers remain valid
      // No body is explicitly needed here since backend expects query parameters
    );

    if (response.statusCode != 200) {
      print('Backend response explicitly: ${response.statusCode}, ${response.body}');
      throw Exception('Failed to select character: ${response.body}');
    }
  }


}
