// lib/services/sync_manager.dart
import 'dart:convert';
import 'package:epsilon_mobile/services/websocket_service.dart';

typedef SyncCallback = void Function();

class SyncManager {
  // Instance of WebSocket service for communication
  final WebSocketService _webSocketService = WebSocketService();

  // Internal tracking of player readiness statuses by node
  Map<String, Map<String, bool>> playerStatuses = {};

  // Indicates if all players are ready for a given node
  Map<String, bool> allReady = {};

  // Registered listeners to react to state changes
  final List<SyncCallback> _listeners = [];

  SyncManager() {
    // Listen to incoming WebSocket messages
    _webSocketService.addListener(_handleWebSocketMessage);
  }

  /// Initialize synchronization for a specific game node
  void initializeSyncNode(String nodeName) {
    playerStatuses[nodeName] = {};
    allReady[nodeName] = false;

    // Request current status explicitly from backend
    _webSocketService.sendMessage({
      "type": "request_readiness",
      "node": nodeName,
    });
  }

  /// Update the player's readiness status clearly to backend
  void updateMyReadiness(String nodeName, String clientId, bool isReady) {
    _webSocketService.sendMessage({
      "type": "player_readiness_update",
      "node": nodeName,
      "client_id": clientId,
      "is_ready": isReady
    });
  }

  /// Checks if everyone is ready for a given node
  bool isEveryoneReady(String nodeName) {
    return allReady[nodeName] ?? false;
  }

  /// Register UI listeners to be notified of status changes
  void registerListener(SyncCallback callback) {
    _listeners.add(callback);
  }

  /// Remove listeners when not needed to prevent memory leaks
  void unregisterListener(SyncCallback callback) {
    _listeners.remove(callback);
  }

  /// Internal handler for incoming WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      final decodedMessage = message is String ? jsonDecode(message) : message;

      if (decodedMessage['type'] == 'readiness_status') {
        final node = decodedMessage['node'];

        // Update player statuses clearly
        final playersList = decodedMessage['players'] as List<dynamic>;
        playerStatuses[node] = {
          for (var player in playersList)
            player['client_id']: player['is_ready'] as bool
        };

        // Update 'allReady' flag clearly
        allReady[node] = decodedMessage['all_ready'] as bool;

        // Notify listeners explicitly
        _notifyListeners();
      }
    } catch (e) {
      print('[SyncManager] Error decoding WebSocket message: $e');
    }
  }

  /// Explicitly notify all registered listeners
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  /// Dispose resources explicitly when not needed anymore
  void dispose() {
    _webSocketService.removeListener(_handleWebSocketMessage);
    _listeners.clear();
  }
}
