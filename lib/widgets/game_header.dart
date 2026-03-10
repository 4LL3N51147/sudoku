import 'package:flutter/material.dart';

/// Header widget displaying timer, difficulty, and control buttons.
class GameHeader extends StatelessWidget {
  final int elapsedSeconds;
  final String difficultyLabel;
  final bool isPaused;
  final bool isAnimating;
  final VoidCallback onPauseToggle;
  final VoidCallback onNewGame;

  const GameHeader({
    super.key,
    required this.elapsedSeconds,
    required this.difficultyLabel,
    required this.isPaused,
    required this.isAnimating,
    required this.onPauseToggle,
    required this.onNewGame,
  });

  String get _formattedTime {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // New game button
          IconButton(
            icon: const Icon(Icons.refresh, size: 24),
            onPressed: isAnimating ? null : onNewGame,
            color: const Color(0xFF1A237E),
            tooltip: 'New Game',
          ),
          // Difficulty label
          Text(
            difficultyLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          // Timer
          Text(
            _formattedTime,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
              fontFamily: 'monospace',
            ),
          ),
          // Pause/Resume button
          IconButton(
            icon: Icon(
              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 24,
            ),
            onPressed: isAnimating ? null : onPauseToggle,
            color: const Color(0xFF1A237E),
            tooltip: isPaused ? 'Resume' : 'Pause',
          ),
        ],
      ),
    );
  }
}
