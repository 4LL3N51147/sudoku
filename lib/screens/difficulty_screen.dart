import 'package:flutter/material.dart';
import '../logic/game_state.dart';
import '../logic/sudoku_generator.dart';
import 'game_screen.dart';

class DifficultyScreen extends StatefulWidget {
  const DifficultyScreen({super.key});

  @override
  State<DifficultyScreen> createState() => _DifficultyScreenState();
}

class _DifficultyScreenState extends State<DifficultyScreen> {
  final TextEditingController _importController = TextEditingController();

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  void _handleImport() async {
    _importController.clear();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Game'),
        content: TextField(
          controller: _importController,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Paste game JSON here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, _importController.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      _importGame(result);
    }
  }

  void _importGame(String jsonString) {
    try {
      final state = GameState.fromJsonString(jsonString);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              difficulty: state.difficulty,
              initialState: state,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid game file: $e')),
        );
      }
    }
  }

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
              const SizedBox(height: 16),
              _DifficultyButton(
                label: 'MASTER',
                subtitle: '25 given numbers',
                color: const Color(0xFF7B1FA2),
                difficulty: Difficulty.master,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: OutlinedButton.icon(
                  onPressed: _handleImport,
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Import Game'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A237E),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
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
