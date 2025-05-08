// lib/screens/intro_screen.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:epsilon_mobile/screens/tile_placement.dart'; // Explicit import of new screen

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late VideoPlayerController controller;
  bool showText = false;         // Start explicitly with video
  String markdownContent = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMarkdown();                  // Load markdown explicitly on init
    initializeAndPlayVideo();        // Initialize and play video immediately
  }

  // Explicitly load markdown content
  Future<void> loadMarkdown() async {
    final String content = await rootBundle.loadString('assets/backstories/epsilon267_intro.md');
    setState(() {
      markdownContent = content;
      isLoading = false;
    });
  }

  // Explicitly initialize video playback immediately
  void initializeAndPlayVideo() {
    controller = VideoPlayerController.asset('assets/videos/epsilon_intro.mp4')
      ..initialize().then((_) {
        setState(() {});
        controller.play();
      });

    // Explicitly handle video completion to show text
    controller.addListener(() {
      if (controller.value.position >= controller.value.duration) {
        setState(() {
          showText = true; // Switch explicitly to showing markdown text
        });
      }
    });
  }

  // Explicit placeholder for sending readiness confirmation (backend integration in next steps)
  void sendReadyConfirmation() {
    // TODO: Implement explicit backend API/WebSocket call to send readiness confirmation
    print("Player confirmed ready. Placeholder for backend call.");
  }

  @override
  void dispose() {
    controller.dispose();  // Explicit cleanup of video controller
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
                  sendReadyConfirmation();  // Explicit readiness call placeholder

                  // Explicit navigation to the TilePlacementScreen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const TilePlacementScreen(),
                    ),
                  );
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