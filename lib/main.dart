import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/difficulty_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Only initialize AdMob on mobile (not supported on web)
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }
  runApp(const SudokuApp());
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3949AB),
        ),
        useMaterial3: true,
      ),
      home: const DifficultyScreen(),
    );
  }
}
