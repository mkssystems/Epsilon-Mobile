// lib/screens/intro_screen.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:epsilon_mobile/screens/game.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late VideoPlayerController controller;
  bool showText = true;          // Explicitly track whether intro text or video is shown
  String markdownContent = '';   // Content of the markdown file
  bool isLoading = true;         // Indicates if markdown content is loading

  @override
  void initState() {
    super.initState();
    loadMarkdown();  // Initially load the markdown content
  }

  // Explicitly loads markdown file content
  Future<void> loadMarkdown() async {
    final String content = await rootBundle.loadString('assets/backstories/epsilon267_intro.md');
    setState(() {
      markdownContent = content;
      isLoading = false;
    });
  }

  // Explicitly initialize and play video after user taps "OK"
  void initializeAndPlayVideo() {
    controller = VideoPlayerController.asset('assets/videos/epsilon_intro.mp4')
      ..initialize().then((_) {
        setState(() {});
        controller.play();
      });

    controller.addListener(() {
      if (controller.value.position >= controller.value.duration) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Game()),
        );
      }
    });
  }

  @override
  void dispose() {
    controller.dispose(); // Dispose video controller explicitly when done
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: showText
          ? isLoading
          ? const Center(child: CircularProgressIndicator()) // Loading indicator while markdown loads
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
                  setState(() {
                    showText = false;  // Switch explicitly to video mode
                  });
                  initializeAndPlayVideo(); // Initialize and play the video explicitly
                },
                child: const Text('OK'),
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
          : const Center(child: CircularProgressIndicator()), // Show loading indicator while video initializes
    );
  }
}
