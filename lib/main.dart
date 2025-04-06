import 'package:flutter/material.dart';
import 'app.dart';

void main() => runApp(const EpsilonApp());

routes: {
'/': (context) => IntroVideoScreen(),
'/menu': (context) => GameMenuScreen(),
}

// Example video controller completion event
controller.addListener(() {
if (controller.value.position == controller.value.duration) {
Navigator.of(context).pushReplacementNamed('/menu');
}
});
