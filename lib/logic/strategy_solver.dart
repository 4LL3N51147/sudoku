enum StrategyPhase { none, scan, elimination, target }

class HiddenSingleResult {
  final int row;
  final int col;
  final int digit;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;

  const HiddenSingleResult({
    required this.row,
    required this.col,
    required this.digit,
    required this.unitCells,
    required this.eliminatorCells,
  });
}

class StrategyHighlight {
  final StrategyPhase phase;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final (int, int)? targetCell;

  const StrategyHighlight({
    required this.phase,
    this.unitCells = const {},
    this.eliminatorCells = const {},
    this.targetCell,
  });
}

/// Returns the first hidden single found on the board, or null if none.
/// Scans rows → columns → boxes in order.
HiddenSingleResult? findHiddenSingle(List<List<int>> board) {
  // rows
  for (int r = 0; r < 9; r++) {
    final cells = {for (int c = 0; c < 9; c++) (r, c)};
    final result = _checkUnit(board, cells);
    if (result != null) return result;
  }
  // columns
  for (int c = 0; c < 9; c++) {
    final cells = {for (int r = 0; r < 9; r++) (r, c)};
    final result = _checkUnit(board, cells);
    if (result != null) return result;
  }
  // boxes
  for (int br = 0; br < 3; br++) {
    for (int bc = 0; bc < 3; bc++) {
      final cells = {
        for (int r = br * 3; r < br * 3 + 3; r++)
          for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
      };
      final result = _checkUnit(board, cells);
      if (result != null) return result;
    }
  }
  return null;
}

HiddenSingleResult? _checkUnit(
    List<List<int>> board, Set<(int, int)> unitCells) {
  final presentDigits = {
    for (final (r, c) in unitCells)
      if (board[r][c] != 0) board[r][c],
  };

  for (int digit = 1; digit <= 9; digit++) {
    if (presentDigits.contains(digit)) continue;

    final candidates = <(int, int)>[];
    for (final (r, c) in unitCells) {
      if (board[r][c] == 0 && _isLegal(board, r, c, digit)) {
        candidates.add((r, c));
      }
    }

    if (candidates.length == 1) {
      final (tr, tc) = candidates.first;
      final eliminators = <(int, int)>{};
      for (final (r, c) in unitCells) {
        if ((r, c) == (tr, tc)) continue;
        if (board[r][c] != 0) continue;
        eliminators.addAll(_findBlockers(board, r, c, digit));
      }
      return HiddenSingleResult(
        row: tr,
        col: tc,
        digit: digit,
        unitCells: unitCells,
        eliminatorCells: eliminators,
      );
    }
  }
  return null;
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

Set<(int, int)> _findBlockers(
    List<List<int>> board, int row, int col, int digit) {
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
