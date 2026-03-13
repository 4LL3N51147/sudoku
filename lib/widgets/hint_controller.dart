import 'package:flutter/material.dart';
import '../logic/strategy_solver.dart';
import '../app_settings.dart';
import 'hint_banner.dart';

/// Controller widget for hint functionality.
/// Displays the hint banner when active and provides the hint button.
class HintController extends StatelessWidget {
  static const _hintColor = Color(0xFF1A237E);

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
          onPressed: _isDisabled ? null : onHintRequested,
          icon: const Icon(Icons.lightbulb_outline),
          label: const Text('Hint'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _hintColor,
            side: BorderSide(color: _hintColor),
          ),
        ),
      ],
    );
  }

  /// Shows the strategy picker bottom sheet.
  static void showStrategyPicker({
    required BuildContext context,
    required void Function(StrategyType) onStrategySelected,
    bool showAdvancedHints = false,
  }) {
    // Basic strategies: Hidden Single, Naked Pair, Hidden Pair, Naked Triple, Hidden Triple
    final basicStrategies = [
      _StrategyItem(
        'Hidden Single',
        'Find a digit that can only go in one cell within a row, column, or box',
        StrategyType.hiddenSingle,
      ),
      _StrategyItem(
        'Naked Pair',
        'Find two cells in a unit with the same two candidates',
        StrategyType.nakedPair,
      ),
      _StrategyItem(
        'Hidden Pair',
        'Find two cells in a unit that are the only ones for two digits',
        StrategyType.hiddenPair,
      ),
      _StrategyItem(
        'Naked Triple',
        'Find three cells in a unit with the same three candidates',
        StrategyType.nakedTriple,
      ),
      _StrategyItem(
        'Hidden Triple',
        'Find three cells in a unit that are the only ones for three digits',
        StrategyType.hiddenTriple,
      ),
    ];

    // Advanced strategies: Naked Quad, Hidden Quad (controlled by showAdvancedHints switch)
    final advancedStrategies = [
      _StrategyItem(
        'Naked Quad',
        'Find four cells in a unit with the same four candidates',
        StrategyType.nakedQuad,
      ),
      _StrategyItem(
        'Hidden Quad',
        'Find four cells in a unit that are the only ones for four digits',
        StrategyType.hiddenQuad,
      ),
    ];

    final strategies = [
      ...basicStrategies,
      if (showAdvancedHints) ...advancedStrategies,
    ];

    final title = showAdvancedHints ? 'Choose a Strategy' : 'Choose a Strategy (Basic)';

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (!showAdvancedHints)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Enable 'Show Advanced Hints' in settings for more strategies",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const Divider(),
            ...strategies.map((item) => _strategyTile(
                  context,
                  item.title,
                  item.subtitle,
                  () => onStrategySelected(item.strategyType),
                )),
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
      leading: Icon(Icons.lightbulb_outline, color: _hintColor),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

/// Data class for strategy items.
class _StrategyItem {
  final String title;
  final String subtitle;
  final StrategyType strategyType;

  const _StrategyItem(this.title, this.subtitle, this.strategyType);
}
