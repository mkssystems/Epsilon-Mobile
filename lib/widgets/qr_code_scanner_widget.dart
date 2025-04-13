import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScannerWidget extends StatefulWidget {
  final void Function(String) onScanned;

  const QRCodeScannerWidget({required this.onScanned, Key? key}) : super(key: key);

  @override
  _QRCodeScannerWidgetState createState() => _QRCodeScannerWidgetState();
}

class _QRCodeScannerWidgetState extends State<QRCodeScannerWidget> {
  MobileScannerController controller = MobileScannerController();

  bool isScanningComplete = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void handleBarcode(BarcodeCapture capture) async {
    if (isScanningComplete) return;

    final barcode = capture.barcodes.first;
    final sessionId = barcode.rawValue;

    if (sessionId == null) return;

    isScanningComplete = true;

    // Stop camera immediately before navigating away
    await controller.stop();

    // Small delay to ensure camera resources are released
    await Future.delayed(const Duration(milliseconds: 200));

    // Safely navigate back to previous screen
    if (!mounted) return;
    Navigator.pop(context);

    widget.onScanned(sessionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        controller: controller,
        onDetect: handleBarcode,
      ),
    );
  }
}
