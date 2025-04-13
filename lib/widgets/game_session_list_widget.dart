import 'package:flutter/material.dart';

class GameSessionListWidget extends StatelessWidget {
  final List<dynamic> sessions;
  final String? currentSessionId;
  final Function(dynamic) onTapSession;

  const GameSessionListWidget({
    super.key,
    required this.sessions,
    required this.currentSessionId,
    required this.onTapSession,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
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
