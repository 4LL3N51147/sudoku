enum StrategyPhase { scan, elimination, target }

enum UnitType { row, column, box }

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
  final Set<(int, int)> unitCells;
  final Set<(int, int)> patternCells;
  final Set<int> patternDigits;
  final Set<(int, int)> eliminationCells;
  final (int, int)? targetCell;

  const StrategyResult({
    required this.type,
    required this.phase,
    this.unitType,
    this.unitCells = const {},
    this.patternCells = const {},
    this.patternDigits = const {},
    this.eliminationCells = const {},
    this.targetCell,
  });
}

class HiddenSingleResult {
  final int row;
  final int col;
  final int digit;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final UnitType unitType;

  const HiddenSingleResult({
    required this.row,
    required this.col,
    required this.digit,
    required this.unitCells,
    required this.eliminatorCells,
    required this.unitType,
  });
}

class StrategyHighlight {
  final StrategyPhase phase;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final (int, int)? targetCell;
  final UnitType? unitType;

  const StrategyHighlight({
    required this.phase,
    this.unitCells = const {},
    this.eliminatorCells = const {},
    this.targetCell,
    this.unitType,
  });
}

bool _isLegal(List<List<int>> board, int row, int col, int digit) {
  for (int c = 0; c < 9; c++) {
    if (board[row][c] == digit) return false;
  }
  for (int r = 0; r < 9; r++) {
    if (board[r][col] == digit) return false;
  }
  final br = (row ~/ 3) * 3;
  final bc = (col ~/ 3) * 3;
  for (int r = br; r < br + 3; r++) {
    for (int c = bc; c < bc + 3; c++) {
      if (board[r][c] == digit) return false;
    }
  }
  return true;
}

/// Computes all candidates for each empty cell on the board.
Map<(int, int), Set<int>> computeCandidates(List<List<int>> board) {
  final candidates = <(int, int), Set<int>>{};
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      if (board[r][c] == 0) {
        final cellCandidates = <int>{};
        for (int d = 1; d <= 9; d++) {
          if (_isLegal(board, r, c, d)) {
            cellCandidates.add(d);
          }
        }
        candidates[(r, c)] = cellCandidates;
      }
    }
  }
  return candidates;
}

class StrategySolver {
  final List<List<int>> board;
  final Map<(int, int), Set<int>> candidates;

  StrategySolver(this.board) : candidates = computeCandidates(board);

  StrategyResult? findNextStrategy() {
    // Try strategies in order: singles -> pairs -> triples -> quads
    final result = findHiddenSingle();
    if (result != null) return result;
    return null;
  }

  StrategyResult? findHiddenSingle() {
    // Rows
    for (int r = 0; r < 9; r++) {
      final cells = {for (int c = 0; c < 9; c++) (r, c)};
      final result = _checkUnitForHiddenSingle(cells, UnitType.row);
      if (result != null) return result;
    }
    // Columns
    for (int c = 0; c < 9; c++) {
      final cells = {for (int r = 0; r < 9; r++) (r, c)};
      final result = _checkUnitForHiddenSingle(cells, UnitType.column);
      if (result != null) return result;
    }
    // Boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final cells = {
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final result = _checkUnitForHiddenSingle(cells, UnitType.box);
        if (result != null) return result;
      }
    }
    return null;
  }

  StrategyResult? _checkUnitForHiddenSingle(
      Set<(int, int)> unitCells, UnitType unitType) {
    final presentDigits = {
      for (final (r, c) in unitCells)
        if (board[r][c] != 0) board[r][c],
    };

    for (int digit = 1; digit <= 9; digit++) {
      if (presentDigits.contains(digit)) continue;

      final cellsWithDigit = unitCells
          .where((rc) => candidates[rc]?.contains(digit) ?? false)
          .toList();

      if (cellsWithDigit.length == 1) {
        final (tr, tc) = cellsWithDigit.first;
        final eliminators = <(int, int)>{};
        for (final (r, c) in unitCells) {
          if ((r, c) == (tr, tc)) continue;
          if (board[r][c] != 0) continue;
          eliminators.addAll(_findBlockers(r, c, digit));
        }
        return StrategyResult(
          type: StrategyType.hiddenSingle,
          phase: StrategyPhase.target,
          unitType: unitType,
          unitCells: unitCells,
          patternCells: {(tr, tc)},
          patternDigits: {digit},
          eliminationCells: eliminators,
          targetCell: (tr, tc),
        );
      }
    }
    return null;
  }

  Set<(int, int)> _findBlockers(int row, int col, int digit) {
    final blockers = <(int, int)>{};
    for (int c = 0; c < 9; c++) {
      if (board[row][c] == digit) blockers.add((row, c));
    }
    for (int r = 0; r < 9; r++) {
      if (board[r][col] == digit) blockers.add((r, col));
    }
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        if (board[r][c] == digit) blockers.add((r, c));
      }
    }
    return blockers;
  }
}

/// Returns the first hidden single found on the board, or null if none.
/// Maintains backward compatibility with existing tests.
HiddenSingleResult? findHiddenSingle(List<List<int>> board) {
  final solver = StrategySolver(board);
  final result = solver.findHiddenSingle();
  if (result == null) return null;

  return HiddenSingleResult(
    row: result.targetCell!.$1,
    col: result.targetCell!.$2,
    digit: result.patternDigits.first,
    unitCells: result.unitCells,
    eliminatorCells: result.eliminationCells,
    unitType: result.unitType!,
  );
}
