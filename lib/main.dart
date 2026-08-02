// Flutter Under the Hood — Hardening & High-Speed Architecture
// Proof-of-concept demo app. Each screen demonstrates a technique from the
// companion article series, with live, measurable results on screen.

import 'package:flutter/material.dart';
import 'widgets/secure_app_wrapper.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HardeningPocApp());
}

class HardeningPocApp extends StatelessWidget {
  const HardeningPocApp({super.key});

  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hardening PoC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2962FF)),
        useMaterial3: true,
      ),
      // Article 1 — screen protection wraps the entire app.
      home: const SecureAppWrapper(child: HomeScreen()),
    );
  }
}
