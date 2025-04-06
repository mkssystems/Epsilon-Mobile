import 'package:flutter/material.dart';
import 'screens/video_screen.dart';

class EpsilonApp extends StatelessWidget {
  const EpsilonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Epsilon 267',
      theme: ThemeData.dark(),
      home: const VideoScreen(),
    );
  }
}
