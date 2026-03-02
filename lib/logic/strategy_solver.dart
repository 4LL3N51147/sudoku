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
    var result = findHiddenSingle();
    if (result != null) return result;
    result = findNakedPair();
    if (result != null) return result;
    result = findHiddenPair();
    if (result != null) return result;
    result = findNakedTriple();
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

  /// Find naked pairs in the board
  StrategyResult? findNakedPair() {
    // Check rows
    for (int r = 0; r < 9; r++) {
      final cells = {for (int c = 0; c < 9; c++) (r, c)};
      final result = _checkUnitForNakedPair(cells, UnitType.row);
      if (result != null) return result;
    }
    // Check columns
    for (int c = 0; c < 9; c++) {
      final cells = {for (int r = 0; r < 9; r++) (r, c)};
      final result = _checkUnitForNakedPair(cells, UnitType.column);
      if (result != null) return result;
    }
    // Check boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final cells = {
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final result = _checkUnitForNakedPair(cells, UnitType.box);
        if (result != null) return result;
      }
    }
    return null;
  }

  /// Check a unit for naked pairs
  StrategyResult? _checkUnitForNakedPair(
      Set<(int, int)> unitCells, UnitType unitType) {
    final emptyCells = unitCells
        .where((rc) => candidates[rc] != null && candidates[rc]!.length >= 2)
        .toList();

    // Find pairs: cells with exactly the same 2 candidates
    final seen = <Set<int>, List<(int, int)>>{};
    for (final cell in emptyCells) {
      final cellCandidates = candidates[cell]!;
      if (cellCandidates.length == 2) {
        seen.putIfAbsent(cellCandidates, () => []).add(cell);
      }
    }

    for (final entry in seen.entries) {
      if (entry.value.length >= 2) {
        final pairCells = entry.value.take(2).toSet();
        final pairDigits = entry.key;

        // Find elimination cells (other empty cells in unit that contain these digits)
        final eliminationCells = <(int, int)>{};
        for (final cell in emptyCells) {
          if (!pairCells.contains(cell)) {
            final cellCand = candidates[cell]!;
            for (final d in pairDigits) {
              if (cellCand.contains(d)) {
                eliminationCells.add(cell);
              }
            }
          }
        }

        if (eliminationCells.isNotEmpty) {
          return StrategyResult(
            type: StrategyType.nakedPair,
            phase: StrategyPhase.elimination,
            unitType: unitType,
            unitCells: unitCells,
            patternCells: pairCells,
            patternDigits: pairDigits,
            eliminationCells: eliminationCells,
          );
        }
      }
    }
    return null;
  }

  /// Find hidden pairs in the board
  StrategyResult? findHiddenPair() {
    // Check rows
    for (int r = 0; r < 9; r++) {
      final cells = {for (int c = 0; c < 9; c++) (r, c)};
      final result = _checkUnitForHiddenPair(cells, UnitType.row);
      if (result != null) return result;
    }
    // Check columns
    for (int c = 0; c < 9; c++) {
      final cells = {for (int r = 0; r < 9; r++) (r, c)};
      final result = _checkUnitForHiddenPair(cells, UnitType.column);
      if (result != null) return result;
    }
    // Check boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final cells = {
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final result = _checkUnitForHiddenPair(cells, UnitType.box);
        if (result != null) return result;
      }
    }
    return null;
  }

  /// Check a unit for hidden pairs
  StrategyResult? _checkUnitForHiddenPair(
      Set<(int, int)> unitCells, UnitType unitType) {
    final emptyCells = unitCells
        .where((rc) => candidates[rc] != null && candidates[rc]!.isNotEmpty)
        .toList();

    // Build digit -> cells mapping
    final digitToCells = <int, List<(int, int)>>{};
    for (final cell in emptyCells) {
      for (final d in candidates[cell]!) {
        digitToCells.putIfAbsent(d, () => []).add(cell);
      }
    }

    // Find all digit pairs
    final digits = digitToCells.keys.toList();
    for (int i = 0; i < digits.length; i++) {
      for (int j = i + 1; j < digits.length; j++) {
        final d1 = digits[i];
        final d2 = digits[j];
        final cells1 = digitToCells[d1]!;
        final cells2 = digitToCells[d2]!;

        // Both digits appear in exactly the same 2 cells
        if (cells1.length == 2 && cells2.length == 2) {
          final pairCells = cells1.toSet();
          if (pairCells.length == 2 && cells2.toSet().length == 2) {
            // Found hidden pair - eliminate other digits from these cells
            final eliminationCells = <(int, int)>{};
            for (final cell in emptyCells) {
              if (!pairCells.contains(cell)) {
                final cellCand = candidates[cell]!;
                if (cellCand.contains(d1) || cellCand.contains(d2)) {
                  eliminationCells.add(cell);
                }
              }
            }

            if (eliminationCells.isNotEmpty) {
              return StrategyResult(
                type: StrategyType.hiddenPair,
                phase: StrategyPhase.elimination,
                unitType: unitType,
                unitCells: unitCells,
                patternCells: pairCells,
                patternDigits: {d1, d2},
                eliminationCells: eliminationCells,
              );
            }
          }
        }
      }
    }
    return null;
  }

  /// Find naked triples in the board
  StrategyResult? findNakedTriple() {
    // Check rows
    for (int r = 0; r < 9; r++) {
      final cells = {for (int c = 0; c < 9; c++) (r, c)};
      final result = _checkUnitForNakedTriple(cells, UnitType.row);
      if (result != null) return result;
    }
    // Check columns
    for (int c = 0; c < 9; c++) {
      final cells = {for (int r = 0; r < 9; r++) (r, c)};
      final result = _checkUnitForNakedTriple(cells, UnitType.column);
      if (result != null) return result;
    }
    // Check boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final cells = {
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final result = _checkUnitForNakedTriple(cells, UnitType.box);
        if (result != null) return result;
      }
    }
    return null;
  }

  /// Check a unit for naked triples
  StrategyResult? _checkUnitForNakedTriple(
      Set<(int, int)> unitCells, UnitType unitType) {
    final emptyCells = unitCells
        .where((rc) => candidates[rc] != null && candidates[rc]!.isNotEmpty)
        .toList();

    // Find all combinations of 3 cells
    for (int i = 0; i < emptyCells.length; i++) {
      for (int j = i + 1; j < emptyCells.length; j++) {
        for (int k = j + 1; k < emptyCells.length; k++) {
          final triple = [emptyCells[i], emptyCells[j], emptyCells[k]];
          final combinedCandidates = <int>{};
          for (final cell in triple) {
            combinedCandidates.addAll(candidates[cell]!);
          }

          // Naked triple: exactly 3 combined candidates
          if (combinedCandidates.length == 3) {
            // Find elimination cells
            final eliminationCells = <(int, int)>{};
            for (final cell in emptyCells) {
              if (!triple.contains(cell)) {
                final cellCand = candidates[cell]!;
                for (final d in combinedCandidates) {
                  if (cellCand.contains(d)) {
                    eliminationCells.add(cell);
                  }
                }
              }
            }

            if (eliminationCells.isNotEmpty) {
              return StrategyResult(
                type: StrategyType.nakedTriple,
                phase: StrategyPhase.elimination,
                unitType: unitType,
                unitCells: unitCells,
                patternCells: triple.toSet(),
                patternDigits: combinedCandidates,
                eliminationCells: eliminationCells,
              );
            }
          }
        }
      }
    }
    return null;
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
