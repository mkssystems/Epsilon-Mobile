import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:epsilon_mobile/screens/game_menu_screen.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.asset('assets/videos/epsilon_intro.mp4')
      ..initialize().then((_) {
        setState(() {});
        controller.play();
      });

    controller.addListener(() {
      if (controller.value.position == controller.value.duration) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => GameMenuScreen()),
        );
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
      body: controller.value.isInitialized
          ? AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
