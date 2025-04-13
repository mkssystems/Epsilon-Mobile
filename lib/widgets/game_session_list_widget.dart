import 'package:flutter/material.dart';

class GameSessionListWidget extends StatelessWidget {
  final List<dynamic> sessions;
  final String? currentSessionId;
  final Function(dynamic) onTapSession;
  final bool shrinkWrap;
  final ScrollPhysics physics;

  const GameSessionListWidget({
    super.key,
    required this.sessions,
    required this.currentSessionId,
    required this.onTapSession,
    this.shrinkWrap = false, // Clearly added
    this.physics = const AlwaysScrollableScrollPhysics(), // Clearly added
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: shrinkWrap, // Explicitly used
      physics: physics,       // Explicitly used
      children: sessions.map((session) {
        return Card(
          color: currentSessionId == session['id'] ? Colors.green[100] : null,
          child: ListTile(
            title: Text('Session ${session['id']}'),
            onTap: () => onTapSession(session),
          ),
        );
      }).toList(),
    );
  }
}
