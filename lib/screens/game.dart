import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class Game extends StatefulWidget {
  const Game({super.key});

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> {
  String storyText = "";
  PageController functionalPageController = PageController(initialPage: 1);
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    loadStory();
    functionalPageController.addListener(() {
      setState(() {
        currentPage = functionalPageController.page!.round();
      });
    });
  }

  Future<void> loadStory() async {
    final loadedStory =
    await rootBundle.loadString('assets/fpv_stories/FPV_tile_story_example.txt');
    setState(() {
      storyText = loadedStory;
    });
  }

  void navigateToFunctionalPage(int pageIndex) {
    functionalPageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Bar (5%)
            Flexible(
              flex: 5,
              child: Container(
                color: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Morgan Ashford",
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Turn: 1",
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Graphic Zone (40%)
            Flexible(
              flex: 40,
              child: PageView(
                controller: PageController(initialPage: 1),
                children: [
                  Container(color: Colors.grey[100], child: const Center(child: Text("Graphic Screen Left"))),
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: SizedBox(
                        width: 400,
                        height: 300,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset('assets/fpv_graphics/FPV_tile_rendering.png', fit: BoxFit.fill),
                            // Additional overlay images here
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(color: Colors.grey[200], child: const Center(child: Text("Graphic Screen Right"))),
                ],
              ),
            ),

            // Functional Zone (45%)
            Flexible(
              flex: 45,
              child: PageView(
                controller: functionalPageController,
                children: [
                  Container(color: Colors.grey[300], child: const Center(child: Text("Functional Screen Left"))),
                  Container(
                    color: Colors.grey[300],
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Text(
                        storyText,
                        style: const TextStyle(fontSize: 16, height: 1.4, color: Colors.black),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ),
                  functionalScreen("MOVE", Colors.green),
                  functionalScreen("FIGHT", Colors.red),
                  functionalScreen("STAY", Colors.blue),
                  functionalScreen("EXPL", Colors.purple),
                  functionalScreen("SPEC", Colors.teal),
                ],
              ),
            ),

            // Action Bar (5%)
            Flexible(
              flex: 5,
              child: Container(
                color: Colors.orangeAccent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    actionButton("DESC", Colors.grey[300]!, 1, Colors.black),
                    verticalDivider(),
                    actionButton("MOVE", Colors.green, 2, Colors.white),
                    verticalDivider(),
                    actionButton("FIGHT", Colors.red, 3, Colors.white),
                    verticalDivider(),
                    actionButton("STAY", Colors.blue, 4, Colors.white),
                    verticalDivider(),
                    actionButton("EXPL", Colors.purple, 5, Colors.white),
                    verticalDivider(),
                    actionButton("SPEC", Colors.teal, 6, Colors.white),
                  ],
                ),
              ),
            ),

            // Info Bar (5%)
            Flexible(
              flex: 5,
              child: Container(
                color: Colors.black87,
                child: const Center(
                  child: Text("Info Bar", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget actionButton(String text, Color color, int pageIndex, Color textColor) => Expanded(
    child: GestureDetector(
      onLongPress: () => navigateToFunctionalPage(pageIndex),
      child: Container(
        alignment: Alignment.center,
        color: color,
        child: Text(text, style: TextStyle(fontSize: 10, color: textColor)),
      ),
    ),
  );

  Widget functionalScreen(String title, Color color) => Container(
    color: color,
    child: Center(
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ),
  );

  Widget verticalDivider() => Container(width: 1, color: Colors.white);
}
