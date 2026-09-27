import 'package:flutter/material.dart';
import 'ui/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Storage initialization bypassed for ALife V3 Phase 3
  runApp(const BrainFlyApp());
}

class BrainFlyApp extends StatelessWidget {
  const BrainFlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrainFly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.deepPurpleAccent,
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
