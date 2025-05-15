// lib/services/sync_manager.dart
import 'dart:convert';
import 'package:epsilon_mobile/services/websocket_service.dart';

typedef SyncCallback = void Function();

class SyncManager {
  // Instance of WebSocket service for communication
  final WebSocketService _webSocketService = WebSocketService();

  // Internal tracking of player readiness statuses
  Map<String, bool> playerStatuses = {};

  // Indicates if all players are ready
  bool allReady = false;

  // Registered listeners to react to state changes
  final List<SyncCallback> _listeners = [];

  bool _initialized = false;

  SyncManager() {
    // Listen to incoming WebSocket messages explicitly
    _webSocketService.addListener(_handleWebSocketMessage);
  }

  /// Initialize synchronization explicitly
  void initializeSync() {
    if (_initialized) return; // Explicitly avoid double initialization
    _initialized = true;

    playerStatuses.clear();
    allReady = false;

    // Explicitly request current readiness status from backend
    _webSocketService.sendMessage({
      "type": "request_readiness",
    });
  }

  /// Checks explicitly if everyone is ready
  bool isEveryoneReady() {
    return allReady;
  }

  /// Register UI listeners to be explicitly notified of status changes
  void registerListener(SyncCallback callback) {
    _listeners.add(callback);
  }

  /// Remove listeners explicitly to prevent memory leaks
  void unregisterListener(SyncCallback callback) {
    _listeners.remove(callback);
  }

  /// Internal handler for incoming WebSocket messages explicitly
  void _handleWebSocketMessage(dynamic message) {
    print('[FRONTEND DEBUG] Raw WebSocket message: $message');
    try {
      final decodedMessage = message is String ? jsonDecode(message) : message;
      print('[FRONTEND DEBUG] Decoded message: $decodedMessage');

      if (decodedMessage['type'] == 'readiness_status') {
        final playersList = decodedMessage['players'] as List<dynamic>;
        playerStatuses = {
          for (var player in playersList)
            player['client_id']: player['ready'] as bool
        };

        print('[FRONTEND DEBUG] playerStatuses updated: $playerStatuses');

        allReady = decodedMessage['all_ready'] as bool;
        _notifyListeners();
      }
      // Explicit handling for backend events
      else if (decodedMessage['event'] == 'all_players_ready') {
        allReady = true;

        // Explicitly set all players to ready
        playerStatuses.updateAll((key, value) => true);

        print("[FRONTEND DEBUG] Explicitly marked all players as ready: $playerStatuses");
        _notifyListeners();
      }
      else if (decodedMessage['event'] == 'phase_transition') {
        _notifyListeners();
      }
    } catch (e) {
      print('[SyncManager] Error decoding WebSocket message: $e');
    }
  }


  /// Explicitly notify all registered listeners
  void _notifyListeners() {
    print("[SyncManager DEBUG] Explicitly notifying ${_listeners.length} listeners");
    for (var listener in _listeners) {
      listener();
    }
  }

  /// Dispose resources explicitly when not needed anymore
  void dispose() {
    _webSocketService.removeListener(_handleWebSocketMessage);
    _listeners.clear();
    _initialized = false;
  }
}
