import 'package:flutter/material.dart';
import 'screens/game_menu_screen.dart';
import 'screens/video_screen.dart';

void main() {
  runApp(const EpsilonApp());
}

class EpsilonApp extends StatelessWidget {
  const EpsilonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Epsilon Game',
      initialRoute: '/',
      routes: {
        '/': (context) => const VideoScreen(),
        '/menu': (context) => GameMenuScreen(), // <-- removed const here
      },
    );
  }
}
