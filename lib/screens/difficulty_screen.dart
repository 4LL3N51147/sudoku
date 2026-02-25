import 'package:flutter/material.dart';
import '../logic/sudoku_generator.dart';
import 'game_screen.dart';

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Text(
                'SUDOKU',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                  letterSpacing: 10,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a difficulty to begin',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const Spacer(flex: 2),
              _DifficultyButton(
                label: 'EASY',
                subtitle: '46 given numbers',
                color: const Color(0xFF43A047),
                difficulty: Difficulty.easy,
              ),
              const SizedBox(height: 16),
              _DifficultyButton(
                label: 'MEDIUM',
                subtitle: '35 given numbers',
                color: const Color(0xFFFB8C00),
                difficulty: Difficulty.medium,
              ),
              const SizedBox(height: 16),
              _DifficultyButton(
                label: 'HARD',
                subtitle: '29 given numbers',
                color: const Color(0xFFE53935),
                difficulty: Difficulty.hard,
              ),
              const Spacer(flex: 3),
            ],
          ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final Difficulty difficulty;

  const _DifficultyButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          minimumSize: const Size(double.infinity, 68),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: Color(0xFF1A237E), width: 2),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GameScreen(difficulty: difficulty),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: color.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
