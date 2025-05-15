//lib/widgets/hold_to_confirm_button.dart
import 'package:flutter/material.dart';
import 'dart:async';


class HoldToConfirmButton extends StatefulWidget {
  final VoidCallback onConfirmed;
  final String label;
  final Duration holdDuration;

  const HoldToConfirmButton({
    super.key,
    required this.onConfirmed,
    this.label = 'Tile Placed',
    this.holdDuration = const Duration(seconds: 2),
  });

  @override
  _HoldToConfirmButtonState createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton> {
  double progress = 0;
  Timer? timer;

  void startHolding() {
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        progress += 0.05;
        if (progress >= 1.0) {
          timer.cancel();
          widget.onConfirmed();
        }
      });
    });
  }

  void resetHolding() {
    timer?.cancel();
    setState(() {
      progress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => startHolding(),
      onLongPressEnd: (_) => resetHolding(),
      child: Container(
        width: 250,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.blueGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Center(
              child: Text(
                widget.label,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
