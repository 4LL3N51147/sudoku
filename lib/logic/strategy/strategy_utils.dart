/// Returns the box index (0-8) for a given row and column.
int getBoxIndex(int row, int col) => (row ~/ 3) * 3 + (col ~/ 3);

/// Returns the starting row of a box (0, 3, or 6).
int getBoxRow(int boxIndex) => (boxIndex ~/ 3) * 3;

/// Returns the starting column of a box (0, 3, or 6).
int getBoxCol(int boxIndex) => (boxIndex % 3) * 3;

/// Check if placing a digit at the given position is legal (no conflicts).
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

/// Get all cells in a row (0-8).
Set<(int, int)> getRowCells(int row) {
  return {for (int c = 0; c < 9; c++) (row, c)};
}

/// Get all cells in a column (0-8).
Set<(int, int)> getColumnCells(int col) {
  return {for (int r = 0; r < 9; r++) (r, col)};
}

/// Get all cells in a box (0-8).
Set<(int, int)> getBoxCells(int boxIndex) {
  final br = getBoxRow(boxIndex);
  final bc = getBoxCol(boxIndex);
  return {
    for (int r = br; r < br + 3; r++)
      for (int c = bc; c < bc + 3; c++) (r, c),
  };
}

/// Get all 9 row cell sets.
List<Set<(int, int)>> getAllRows() {
  return [for (int r = 0; r < 9; r++) getRowCells(r)];
}

/// Get all 9 column cell sets.
List<Set<(int, int)>> getAllColumns() {
  return [for (int c = 0; c < 9; c++) getColumnCells(c)];
}

/// Get all 9 box cell sets.
List<Set<(int, int)>> getAllBoxes() {
  return [for (int b = 0; b < 9; b++) getBoxCells(b)];
}

/// Get empty cells with non-empty candidates from a unit.
List<(int, int)> getEmptyCellsWithCandidates(
  Set<(int, int)> unitCells,
  Map<(int, int), Set<int>> candidates,
) {
  return unitCells
      .where((cell) => candidates[cell]?.isNotEmpty ?? false)
      .toList();
}

/// Build a map from digit to list of cells containing that digit in candidates.
Map<int, List<(int, int)>> buildDigitToCellsMap(
  List<(int, int)> emptyCells,
  Map<(int, int), Set<int>> candidates,
) {
  final digitToCells = <int, List<(int, int)>>{};
  for (final cell in emptyCells) {
    final cellCandidates = candidates[cell];
    if (cellCandidates == null) continue;
    for (final digit in cellCandidates) {
      digitToCells.putIfAbsent(digit, () => []).add(cell);
    }
  }
  return digitToCells;
}
