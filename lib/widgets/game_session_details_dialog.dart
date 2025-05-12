//lib/widgets/game_session_details_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GameSessionDetailsDialog extends StatelessWidget {
  final dynamic session;
  final Widget actionButtons;

  const GameSessionDetailsDialog({
    super.key,
    required this.session,
    required this.actionButtons,
  });

  @override
  Widget build(BuildContext context) {
    final orderedKeys = [
      'owner',
      'status',
      'createdAt',
      'updatedAt',
      'players',
      'maxPlayers',
      'scenario_name',
      'creator_client_id'
    ];

    List<MapEntry<String, dynamic>> entries = session.entries
        .where((e) => e.key != 'id' && !['seed', 'labyrinth_id', 'difficulty'].contains(e.key) && e.value != null)
        .toList()
      ..sort((a, b) {
        final indexA = orderedKeys.indexOf(a.key);
        final indexB = orderedKeys.indexOf(b.key);
        return (indexA == -1 ? 999 : indexA).compareTo(indexB == -1 ? 999 : indexB);
      });

    String formatLocalDate(String isoString) {
      try {
        DateTime parsedDate = DateTime.parse(isoString);
        DateTime localDate = parsedDate.toLocal();
        return DateFormat('yyyy-MM-dd, HH:mm').format(localDate);
      } catch (_) {
        return isoString;
      }
    }

    Widget buildDataRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Row(children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ]),
      );
    }

    List<Widget> detailWidgets = entries.map((entry) {
      String label = entry.key;
      String value = entry.value.toString();
      if (entry.key == 'createdAt' || entry.key == 'updatedAt') {
        value = formatLocalDate(value);
      }

      switch (entry.key) {
        case 'owner':
          label = 'Owner';
          break;
        case 'status':
          label = 'Status';
          break;
        case 'createdAt':
          label = 'Created';
          break;
        case 'updatedAt':
          label = 'Updated';
          break;
        case 'players':
          label = 'Players';
          break;
        case 'maxPlayers':
          label = 'Max Players';
          break;
        case 'scenario_name':
          label = 'Scenario';
          break;
        case 'creator_client_id':
          label = 'Creator';
          break;
        default:
          break;
      }

      return buildDataRow(label, value);
    }).toList();

    return AlertDialog(
      title: Row(children: [
        Expanded(
          child: Text(
            'Session ID: ${session['id']}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: session['id']));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Session ID copied to clipboard.")),
            );
          },
        ),
      ]),
      content: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ...detailWidgets,
          const SizedBox(height: 16),
          actionButtons,
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // safely close current dialog first
            Future.delayed(Duration.zero, () {
              showDialog(
                context: context,
                builder: (BuildContext qrContext) => AlertDialog(
                  content: SizedBox(
                    width: 250,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Session QR Code",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        QrImageView(
                          data: session['id'],
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Session ID:\n${session['id']}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(qrContext).pop(),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              );
            });
          },
          child: const Text("Show QR Code"),
        ),


      ],
    );
  }
}