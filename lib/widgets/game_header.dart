import 'package:flutter/material.dart';

/// Header widget displaying timer and pause button.
class GameHeader extends StatelessWidget {
  final int elapsedSeconds;
  final bool isPaused;
  final bool isAnimating;
  final VoidCallback onPauseToggle;

  const GameHeader({
    super.key,
    required this.elapsedSeconds,
    required this.isPaused,
    required this.isAnimating,
    required this.onPauseToggle,
  });

  String get _formattedTime {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
    );
  }
}
