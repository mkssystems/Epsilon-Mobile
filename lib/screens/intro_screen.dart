// lib/screens/intro_screen.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:epsilon_mobile/screens/initial_tile_placement.dart';
import 'package:epsilon_mobile/services/game_menu_service.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late VideoPlayerController controller;
  bool showText = false;
  String markdownContent = '';
  bool isLoading = true;
  final GameMenuService gameMenuService = GameMenuService();
  String? sessionId;
  String? clientId;

  @override
  void initState() {
    super.initState();
    loadIds();
    loadMarkdown();
    initializeAndPlayVideo();
  }

  Future<void> loadIds() async {
    sessionId = await gameMenuService.getSessionId();
    clientId = await gameMenuService.getClientId();
    if (sessionId == null || clientId == null) {
      // Handle missing IDs explicitly here
      print('Session or Client ID missing!');
    }
  }

  Future<void> loadMarkdown() async {
    final String content =
    await rootBundle.loadString('assets/backstories/epsilon267_intro.md');
    setState(() {
      markdownContent = content;
      isLoading = false;
    });
  }

  void initializeAndPlayVideo() {
    controller = VideoPlayerController.asset('assets/videos/epsilon_intro.mp4')
      ..initialize().then((_) {
        setState(() {});
        controller.play();
      });

    controller.addListener(() {
      if (controller.value.position >= controller.value.duration) {
        setState(() {
          showText = true;
        });
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: showText
          ? isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Markdown(
                data: markdownContent,
                padding: const EdgeInsets.all(16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () {
                  if (sessionId != null && clientId != null) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>
                        const InitialTilePlacementScreen(),
                      ),
                    );
                  } else {
                    print('Cannot proceed, IDs missing');
                  }
                },
                child: const Text('Ready'),
              ),
            ),
          ],
        ),
      )
          : controller.value.isInitialized
          ? SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}