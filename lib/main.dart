import 'package:flutter/material.dart';
import 'features2/StageGame/pages/splash_screen.dart';

void main() {
  runApp(const StageSetupApp());
}

class StageSetupApp extends StatelessWidget {
  const StageSetupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stage Setup Challenge',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
