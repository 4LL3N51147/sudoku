import '../strategy_solver.dart';

enum StrategyType {
  hiddenSingle,
  nakedPair,
  hiddenPair,
  nakedTriple,
  hiddenTriple,
  nakedQuad,
  hiddenQuad,
}

class StrategyResult {
  final StrategyType type;
  final StrategyPhase phase;
  final UnitType? unitType;
  /// List of hint steps for animation - each step is a state change in the strategy
  final List<HintStep> hintSteps;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> patternCells;
  final Set<int> patternDigits;
  final Set<(int, int)> eliminationCells;
  final (int, int)? targetCell;
  /// Map of cell -> digits to eliminate from that cell (for visual strikethrough)
  final Map<(int, int), Set<int>> eliminationCandidates;
  /// Rows that contain the digit being eliminated (for red elimination zones)
  final Set<int> eliminationRows;
  /// Columns that contain the digit being eliminated (for red elimination zones)
  final Set<int> eliminationCols;
  /// Boxes (0-8) that contain the digit being eliminated (for red elimination zones)
  final Set<int> eliminationBoxes;
  /// Cells that now have only 1 candidate after elimination (for Naked strategies)
  final Set<(int, int)> resultCells;

  const StrategyResult({
    required this.type,
    required this.phase,
    this.unitType,
    this.unitCells = const {},
    this.patternCells = const {},
    this.patternDigits = const {},
    this.eliminationCells = const {},
    this.targetCell,
    this.eliminationCandidates = const {},
    this.eliminationRows = const {},
    this.eliminationCols = const {},
    this.eliminationBoxes = const {},
    this.resultCells = const {},
    this.hintSteps = const [],
  });
}

class StrategyHighlight {
  final StrategyPhase phase;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final Set<(int, int)> patternCells;
  final (int, int)? targetCell;
  final UnitType? unitType;
  /// The digits being eliminated (e.g., {2, 4} for naked pair)
  final Set<int> patternDigits;
  /// Map of cell -> digits to eliminate from that cell (for visual strikethrough)
  final Map<(int, int), Set<int>> eliminationCandidates;
  /// Rows that contain the digit being eliminated (for red elimination zones)
  final Set<int> eliminationRows;
  /// Columns that contain the digit being eliminated (for red elimination zones)
  final Set<int> eliminationCols;
  /// Boxes (0-8) that contain the digit being eliminated (for red elimination zones)
  final Set<int> eliminationBoxes;
  /// Cells that now have only 1 candidate after elimination (for Naked strategies)
  final Set<(int, int)> resultCells;

  const StrategyHighlight({
    required this.phase,
    this.unitCells = const {},
    this.eliminatorCells = const {},
    this.patternCells = const {},
    this.targetCell,
    this.unitType,
    this.patternDigits = const {},
    this.eliminationCandidates = const {},
    this.eliminationRows = const {},
    this.eliminationCols = const {},
    this.eliminationBoxes = const {},
    this.resultCells = const {},
  });

  /// Creates a StrategyHighlight from a HintStep
  factory StrategyHighlight.fromHintStep(HintStep step) {
    return StrategyHighlight(
      phase: step.phase,
      unitCells: step.unitCells,
      patternCells: step.patternCells,
      eliminatorCells: step.eliminatorCells,
      targetCell: step.targetCell,
      unitType: step.unitType,
      patternDigits: step.patternDigits,
      eliminationCandidates: step.eliminationCandidates,
      eliminationRows: step.eliminationRows,
      eliminationCols: step.eliminationCols,
      eliminationBoxes: step.eliminationBoxes,
      resultCells: step.resultCells,
    );
  }
}

abstract class Strategy {
  StrategyType get type;
  StrategyResult? find(List<List<int>> board, Map<(int, int), Set<int>> candidates);
}
