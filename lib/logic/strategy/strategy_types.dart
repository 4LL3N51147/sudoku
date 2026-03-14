enum StrategyPhase { scan, elimination, target }

enum UnitType { row, column, box }

/// Represents a single step in the hint animation sequence
class HintStep {
  final StrategyPhase phase;
  final String? message;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> patternCells;
  final Set<(int, int)> eliminatorCells;
  final (int, int)? targetCell;
  final UnitType? unitType;
  final Set<int> patternDigits;
  final Map<(int, int), Set<int>> eliminationCandidates;
  final Set<int> eliminationRows;
  final Set<int> eliminationCols;
  final Set<int> eliminationBoxes;
  final Set<(int, int)> resultCells;

  const HintStep({
    required this.phase,
    this.message,
    this.unitCells = const {},
    this.patternCells = const {},
    this.eliminatorCells = const {},
    this.targetCell,
    this.unitType,
    this.patternDigits = const {},
    this.eliminationCandidates = const {},
    this.eliminationRows = const {},
    this.eliminationCols = const {},
    this.eliminationBoxes = const {},
    this.resultCells = const {},
  });
}
