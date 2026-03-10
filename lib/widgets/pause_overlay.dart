import 'package:flutter/material.dart';

/// An overlay displayed when the game is paused.
class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onQuit;

  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            elevation: 12,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pause_circle_filled_rounded,
                      size: 64, color: Color(0xFF1A237E)),
                  const SizedBox(height: 12),
                  const Text(
                    'Game Paused',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Resume',
                        style: TextStyle(fontSize: 17)),
                    onPressed: onResume,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onQuit,
                    child: const Text(
                      'Quit',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
