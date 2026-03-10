import 'package:flutter/material.dart';
import '../logic/strategy_solver.dart';
import '../app_settings.dart';
import 'hint_banner.dart';

/// Controller widget for hint functionality.
/// Displays the hint banner when active and provides the hint button.
class HintController extends StatelessWidget {
  final StrategyHighlight? strategyHighlight;
  final String? hintMessage;
  final int? hintPhase;
  final bool isAnimating;
  final bool isPaused;
  final bool isCompleted;
  final AppSettings settings;
  final VoidCallback onHintRequested;
  final VoidCallback onAdvanceHint;

  const HintController({
    super.key,
    this.strategyHighlight,
    this.hintMessage,
    this.hintPhase,
    required this.isAnimating,
    required this.isPaused,
    required this.isCompleted,
    required this.settings,
    required this.onHintRequested,
    required this.onAdvanceHint,
  });

  bool get _isDisabled => isPaused || isAnimating || isCompleted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hint banner - shown when hintMessage is not null
        if (hintMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: HintBanner(
              message: hintMessage!,
              hasNextButton: hintPhase != null && hintPhase! < 4,
              onNextPressed: _isDisabled ? null : onAdvanceHint,
            ),
          ),
        // Hint button with isAnimating guard
        OutlinedButton.icon(
          onPressed: isAnimating ? null : onHintRequested,
          icon: const Icon(Icons.lightbulb_outline),
          label: const Text('Hint'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1A237E),
            side: const BorderSide(color: Color(0xFF1A237E)),
          ),
        ),
      ],
    );
  }

  /// Shows the strategy picker bottom sheet.
  static void showStrategyPicker({
    required BuildContext context,
    required void Function(StrategyType) onStrategySelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Choose a Strategy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            _strategyTile(
              context,
              'Hidden Single',
              'Find a digit that can only go in one cell within a row, column, or box',
              () => onStrategySelected(StrategyType.hiddenSingle),
            ),
            _strategyTile(
              context,
              'Naked Pair',
              'Find two cells in a unit with the same two candidates',
              () => onStrategySelected(StrategyType.nakedPair),
            ),
            _strategyTile(
              context,
              'Hidden Pair',
              'Find two cells in a unit that are the only ones for two digits',
              () => onStrategySelected(StrategyType.hiddenPair),
            ),
            _strategyTile(
              context,
              'Naked Triple',
              'Find three cells in a unit with the same three candidates',
              () => onStrategySelected(StrategyType.nakedTriple),
            ),
            _strategyTile(
              context,
              'Hidden Triple',
              'Find three cells in a unit that are the only ones for three digits',
              () => onStrategySelected(StrategyType.hiddenTriple),
            ),
            _strategyTile(
              context,
              'Naked Quad',
              'Find four cells in a unit with the same four candidates',
              () => onStrategySelected(StrategyType.nakedQuad),
            ),
            _strategyTile(
              context,
              'Hidden Quad',
              'Find four cells in a unit that are the only ones for four digits',
              () => onStrategySelected(StrategyType.hiddenQuad),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _strategyTile(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: const Icon(Icons.lightbulb_outline, color: Color(0xFF1A237E)),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
