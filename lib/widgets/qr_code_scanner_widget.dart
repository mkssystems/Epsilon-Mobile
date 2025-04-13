import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScannerWidget extends StatefulWidget {
  const QRCodeScannerWidget({
    required this.onScanned,
    required this.onCancel,
    Key? key,
  }) : super(key: key);

  final void Function(String sessionId) onScanned;
  final VoidCallback onCancel;

  @override
  _QRCodeScannerWidgetState createState() => _QRCodeScannerWidgetState();
}

class _QRCodeScannerWidgetState extends State<QRCodeScannerWidget> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanningComplete = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> handleBarcode(BarcodeCapture capture) async {
    if (isScanningComplete) return;

    final barcode = capture.barcodes.first;
    final sessionId = barcode.rawValue;

    if (sessionId == null || sessionId.isEmpty) return;

    isScanningComplete = true;

    await controller.stop();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.of(context).pop();
    widget.onScanned(sessionId);
  }

  void _cancelScanning() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) { // ← fixed here
        if (!didPop) {
          _cancelScanning();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _cancelScanning,
          ),
        ),
        body: MobileScanner(
          controller: controller,
          onDetect: handleBarcode,
        ),
      ),
    );
  }
}
