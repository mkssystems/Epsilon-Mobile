//lib/widgets/session_qr_code_widget.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SessionQrCodeWidget extends StatelessWidget {
  final String sessionId;

  const SessionQrCodeWidget({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Session QR Code",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        QrImageView(
          data: sessionId,
          version: QrVersions.auto,
          size: 200.0,
        ),
      ],
    );
  }
}
