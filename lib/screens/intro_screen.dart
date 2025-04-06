import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';
import 'video_screen.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  Future<String> loadMarkdown() async {
    return await rootBundle.loadString('assets/backstories/epsilon267_intro.md');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Epsilon 267 Intro')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: loadMarkdown(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Markdown(data: snapshot.data ?? '');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const VideoScreen()),
                );
              },
              child: const Text('Reload'),
            ),
          ),
        ],
      ),
    );
  }
}
