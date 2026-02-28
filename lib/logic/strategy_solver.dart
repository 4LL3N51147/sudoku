enum StrategyPhase { scan, elimination, target }

enum UnitType { row, column, box }

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

class NakedSingleResult {
  final int row;
  final int col;
  final int digit;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final UnitType unitType;

  const NakedSingleResult({
    required this.row,
    required this.col,
    required this.digit,
    required this.unitCells,
    required this.eliminatorCells,
    required this.unitType,
  });
}

class NakedPairResult {
  final Set<(int, int)> pairCells; // The two cells with the pair
  final Set<int> digits; // The two digits
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final UnitType unitType;

  const NakedPairResult({
    required this.pairCells,
    required this.digits,
    required this.unitCells,
    required this.eliminatorCells,
    required this.unitType,
  });
}

class HiddenPairResult {
  final Set<(int, int)> pairCells;
  final Set<int> digits;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final UnitType unitType;

  const HiddenPairResult({
    required this.pairCells,
    required this.digits,
    required this.unitCells,
    required this.eliminatorCells,
    required this.unitType,
  });
}

class NakedTripleResult {
  final Set<(int, int)> tripleCells;
  final Set<int> digits;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final UnitType unitType;

  const NakedTripleResult({
    required this.tripleCells,
    required this.digits,
    required this.unitCells,
    required this.eliminatorCells,
    required this.unitType,
  });
}

class NakedQuadResult {
  final Set<(int, int)> quadCells;
  final Set<int> digits;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final UnitType unitType;

  const NakedQuadResult({
    required this.quadCells,
    required this.digits,
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

/// Returns the first hidden single found on the board, or null if none.
/// Scans rows → columns → boxes in order.
HiddenSingleResult? findHiddenSingle(List<List<int>> board) {
  // rows
  for (int r = 0; r < 9; r++) {
    final cells = {for (int c = 0; c < 9; c++) (r, c)};
    final result = _checkUnit(board, cells, UnitType.row);
    if (result != null) return result;
  }
  // columns
  for (int c = 0; c < 9; c++) {
    final cells = {for (int r = 0; r < 9; r++) (r, c)};
    final result = _checkUnit(board, cells, UnitType.column);
    if (result != null) return result;
  }
  // boxes
  for (int br = 0; br < 3; br++) {
    for (int bc = 0; bc < 3; bc++) {
      final cells = {
        for (int r = br * 3; r < br * 3 + 3; r++)
          for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
      };
      final result = _checkUnit(board, cells, UnitType.box);
      if (result != null) return result;
    }
  }
  return null;
}

HiddenSingleResult? _checkUnit(
    List<List<int>> board, Set<(int, int)> unitCells, UnitType unitType) {
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
        unitType: unitType,
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

/// Finds a naked single: a cell with only one possible candidate.
/// Returns the cell position and digit, or null if none found.
/// Requires pencilMarks to determine candidates.
NakedSingleResult? findNakedSingle(
    List<List<int>> board, List<List<Set<int>>> pencilMarks) {
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      if (board[r][c] != 0) continue;
      final candidates = pencilMarks[r][c];
      if (candidates.length == 1) {
        final digit = candidates.first;
        // Include all three units (row, column, box) for highlighting
        // since a naked single has only one candidate overall
        final unitCells = <(int, int)>{};
        // Row
        for (int i = 0; i < 9; i++) {
          unitCells.add((r, i));
        }
        // Column
        for (int i = 0; i < 9; i++) {
          unitCells.add((i, c));
        }
        // Box
        final br = (r ~/ 3) * 3;
        final bc = (c ~/ 3) * 3;
        for (int i = br; i < br + 3; i++) {
          for (int j = bc; j < bc + 3; j++) {
            unitCells.add((i, j));
          }
        }
        // Find blockers for elimination animation
        final eliminators = _findBlockers(board, r, c, digit);
        return NakedSingleResult(
          row: r,
          col: c,
          digit: digit,
          unitCells: unitCells,
          eliminatorCells: eliminators,
          unitType: UnitType.row,
        );
      }
    }
  }
  return null;
}

/// Finds a naked pair: two cells in same unit with exactly the same two candidates.
NakedPairResult? findNakedPair(
    List<List<int>> board, List<List<Set<int>>> pencilMarks) {
  // Check rows
  for (int r = 0; r < 9; r++) {
    final cells = <(int, int), Set<int>>{};
    for (int c = 0; c < 9; c++) {
      if (board[r][c] == 0 && pencilMarks[r][c].length == 2) {
        cells[(r, c)] = pencilMarks[r][c];
      }
    }
    final result = _findMatchingPair(cells, UnitType.row, r, pencilMarks);
    if (result != null) return result;
  }

  // Check columns
  for (int c = 0; c < 9; c++) {
    final cells = <(int, int), Set<int>>{};
    for (int r = 0; r < 9; r++) {
      if (board[r][c] == 0 && pencilMarks[r][c].length == 2) {
        cells[(r, c)] = pencilMarks[r][c];
      }
    }
    final result = _findMatchingPair(cells, UnitType.column, c, pencilMarks);
    if (result != null) return result;
  }

  // Check boxes
  for (int br = 0; br < 3; br++) {
    for (int bc = 0; bc < 3; bc++) {
      final cells = <(int, int), Set<int>>{};
      for (int r = br * 3; r < br * 3 + 3; r++) {
        for (int c = bc * 3; c < bc * 3 + 3; c++) {
          if (board[r][c] == 0 && pencilMarks[r][c].length == 2) {
            cells[(r, c)] = pencilMarks[r][c];
          }
        }
      }
      final result = _findMatchingPair(cells, UnitType.box, br * 3 + bc, pencilMarks);
      if (result != null) return result;
    }
  }

  return null;
}

NakedPairResult? _findMatchingPair(
    Map<(int, int), Set<int>> cells, UnitType unitType, int unitIndex,
    List<List<Set<int>>> pencilMarks) {
  final entries = cells.entries.toList();
  for (int i = 0; i < entries.length; i++) {
    for (int j = i + 1; j < entries.length; j++) {
      if (entries[i].value.containsAll(entries[j].value) &&
          entries[j].value.containsAll(entries[i].value)) {
        final pairCells = {entries[i].key, entries[j].key};
        final digits = entries[i].value;

        // Get all cells in unit
        final unitCells = <(int, int)>{};
        if (unitType == UnitType.row) {
          for (int c = 0; c < 9; c++) {
            unitCells.add((unitIndex, c));
          }
        } else if (unitType == UnitType.column) {
          for (int r = 0; r < 9; r++) {
            unitCells.add((r, unitIndex));
          }
        } else {
          final br = unitIndex ~/ 3;
          final bc = unitIndex % 3;
          for (int r = br * 3; r < br * 3 + 3; r++) {
            for (int c = bc * 3; c < bc * 3 + 3; c++) {
              unitCells.add((r, c));
            }
          }
        }

        // Eliminators: other cells in unit that have these digits
        final eliminators = <(int, int)>{};
        for (final (er, ec) in unitCells) {
          if (pairCells.contains((er, ec))) continue;
          for (final d in digits) {
            if (pencilMarks[er][ec].contains(d)) {
              eliminators.add((er, ec));
              break;
            }
          }
        }

        return NakedPairResult(
          pairCells: pairCells,
          digits: digits,
          unitCells: unitCells,
          eliminatorCells: eliminators,
          unitType: unitType,
        );
      }
    }
  }
  return null;
}

/// Finds a hidden pair: two digits that only appear in exactly two cells in a unit.
HiddenPairResult? findHiddenPair(
    List<List<int>> board, List<List<Set<int>>> pencilMarks) {
  // Check rows
  for (int r = 0; r < 9; r++) {
    final result = _findHiddenPairInUnit(board, r, -1, pencilMarks, UnitType.row);
    if (result != null) return result;
  }
  // Check columns
  for (int c = 0; c < 9; c++) {
    final result = _findHiddenPairInUnit(board, -1, c, pencilMarks, UnitType.column);
    if (result != null) return result;
  }
  // Check boxes
  for (int br = 0; br < 3; br++) {
    for (int bc = 0; bc < 3; bc++) {
      final result = _findHiddenPairInBox(board, br, bc, pencilMarks);
      if (result != null) return result;
    }
  }
  return null;
}

HiddenPairResult? _findHiddenPairInUnit(
    List<List<int>> board, int row, int col,
    List<List<Set<int>>> pencilMarks, UnitType unitType) {
  // Count occurrences of each digit across cells in unit
  final digitPositions = <int, Set<(int, int)>>{};
  for (int i = 0; i < 9; i++) {
    final r = unitType == UnitType.row ? row : i;
    final c = unitType == UnitType.column ? col : i;
    if (board[r][c] != 0) continue;
    for (final d in pencilMarks[r][c]) {
      digitPositions.putIfAbsent(d, () => {}).add((r, c));
    }
  }

  // Find two digits that appear in exactly the same two cells
  final digits = digitPositions.keys.toList();
  for (int i = 0; i < digits.length; i++) {
    for (int j = i + 1; j < digits.length; j++) {
      final pos1 = digitPositions[digits[i]]!;
      final pos2 = digitPositions[digits[j]]!;
      if (pos1.length == 2 && pos2.length == 2 &&
          pos1.containsAll(pos2) && pos2.containsAll(pos1)) {
        final pairCells = pos1;

        // Get all cells in unit
        final unitCells = <(int, int)>{};
        for (int k = 0; k < 9; k++) {
          if (unitType == UnitType.row) {
            unitCells.add((row, k));
          } else {
            unitCells.add((k, col));
          }
        }

        // Eliminators: other cells in unit with these digits (to be removed)
        final eliminators = <(int, int)>{};
        for (final (er, ec) in unitCells) {
          if (pairCells.contains((er, ec))) continue;
          if (pencilMarks[er][ec].contains(digits[i]) ||
              pencilMarks[er][ec].contains(digits[j])) {
            eliminators.add((er, ec));
          }
        }

        return HiddenPairResult(
          pairCells: pairCells,
          digits: {digits[i], digits[j]},
          unitCells: unitCells,
          eliminatorCells: eliminators,
          unitType: unitType,
        );
      }
    }
  }
  return null;
}

// Similar for boxes
HiddenPairResult? _findHiddenPairInBox(
    List<List<int>> board, int br, int bc,
    List<List<Set<int>>> pencilMarks) {
  final digitPositions = <int, Set<(int, int)>>{};
  for (int r = br * 3; r < br * 3 + 3; r++) {
    for (int c = bc * 3; c < bc * 3 + 3; c++) {
      if (board[r][c] != 0) continue;
      for (final d in pencilMarks[r][c]) {
        digitPositions.putIfAbsent(d, () => {}).add((r, c));
      }
    }
  }

  final digits = digitPositions.keys.toList();
  for (int i = 0; i < digits.length; i++) {
    for (int j = i + 1; j < digits.length; j++) {
      final pos1 = digitPositions[digits[i]]!;
      final pos2 = digitPositions[digits[j]]!;
      if (pos1.length == 2 && pos2.length == 2 &&
          pos1.containsAll(pos2) && pos2.containsAll(pos1)) {
        final pairCells = pos1;
        final unitCells = <(int, int)>{
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final eliminators = <(int, int)>{};
        for (final (er, ec) in unitCells) {
          if (pairCells.contains((er, ec))) continue;
          if (pencilMarks[er][ec].contains(digits[i]) ||
              pencilMarks[er][ec].contains(digits[j])) {
            eliminators.add((er, ec));
          }
        }
        return HiddenPairResult(
          pairCells: pairCells,
          digits: {digits[i], digits[j]},
          unitCells: unitCells,
          eliminatorCells: eliminators,
          unitType: UnitType.box,
        );
      }
    }
  }
  return null;
}

/// Finds a naked triple: three cells in a unit where the union of their
/// candidates is exactly three digits.
NakedTripleResult? findNakedTriple(
    List<List<int>> board, List<List<Set<int>>> pencilMarks) {
  // Check rows
  for (int r = 0; r < 9; r++) {
    final result = _findNakedTripleInUnit(board, r, -1, pencilMarks, UnitType.row);
    if (result != null) return result;
  }
  // Check columns
  for (int c = 0; c < 9; c++) {
    final result = _findNakedTripleInUnit(board, -1, c, pencilMarks, UnitType.column);
    if (result != null) return result;
  }
  // Check boxes
  for (int br = 0; br < 3; br++) {
    for (int bc = 0; bc < 3; bc++) {
      final result = _findNakedTripleInBox(board, br, bc, pencilMarks);
      if (result != null) return result;
    }
  }
  return null;
}

NakedTripleResult? _findNakedTripleInUnit(
    List<List<int>> board, int row, int col,
    List<List<Set<int>>> pencilMarks, UnitType unitType) {
  // Get empty cells with 2-3 candidates
  final candidates = <(int, int), Set<int>>{};
  for (int i = 0; i < 9; i++) {
    final r = unitType == UnitType.row ? row : i;
    final c = unitType == UnitType.column ? col : i;
    if (board[r][c] == 0 && pencilMarks[r][c].length >= 2 && pencilMarks[r][c].length <= 3) {
      candidates[(r, c)] = pencilMarks[r][c];
    }
  }

  final entries = candidates.entries.toList();
  for (int i = 0; i < entries.length; i++) {
    for (int j = i + 1; j < entries.length; j++) {
      for (int k = j + 1; k < entries.length; k++) {
        final union = {...entries[i].value, ...entries[j].value, ...entries[k].value};
        if (union.length == 3) {
          final tripleCells = {entries[i].key, entries[j].key, entries[k].key};
          final digits = union;

          // Get all cells in unit
          final unitCells = <(int, int)>{};
          if (unitType == UnitType.row) {
            for (int c = 0; c < 9; c++) {
              unitCells.add((row, c));
            }
          } else {
            for (int r = 0; r < 9; r++) {
              unitCells.add((r, col));
            }
          }

          // Eliminators: other cells with these digits
          final eliminators = <(int, int)>{};
          for (final (er, ec) in unitCells) {
            if (tripleCells.contains((er, ec))) continue;
            for (final d in digits) {
              if (pencilMarks[er][ec].contains(d)) {
                eliminators.add((er, ec));
                break;
              }
            }
          }

          return NakedTripleResult(
            tripleCells: tripleCells,
            digits: digits,
            unitCells: unitCells,
            eliminatorCells: eliminators,
            unitType: unitType,
          );
        }
      }
    }
  }
  return null;
}

// Similar for boxes
NakedTripleResult? _findNakedTripleInBox(
    List<List<int>> board, int br, int bc,
    List<List<Set<int>>> pencilMarks) {
  final candidates = <(int, int), Set<int>>{};
  for (int r = br * 3; r < br * 3 + 3; r++) {
    for (int c = bc * 3; c < bc * 3 + 3; c++) {
      if (board[r][c] == 0 && pencilMarks[r][c].length >= 2 && pencilMarks[r][c].length <= 3) {
        candidates[(r, c)] = pencilMarks[r][c];
      }
    }
  }

  final entries = candidates.entries.toList();
  for (int i = 0; i < entries.length; i++) {
    for (int j = i + 1; j < entries.length; j++) {
      for (int k = j + 1; k < entries.length; k++) {
        final union = {...entries[i].value, ...entries[j].value, ...entries[k].value};
        if (union.length == 3) {
          final tripleCells = {entries[i].key, entries[j].key, entries[k].key};
          final digits = union;

          final unitCells = <(int, int)>{
            for (int r = br * 3; r < br * 3 + 3; r++)
              for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
          };

          final eliminators = <(int, int)>{};
          for (final (er, ec) in unitCells) {
            if (tripleCells.contains((er, ec))) continue;
            for (final d in digits) {
              if (pencilMarks[er][ec].contains(d)) {
                eliminators.add((er, ec));
                break;
              }
            }
          }

          return NakedTripleResult(
            tripleCells: tripleCells,
            digits: digits,
            unitCells: unitCells,
            eliminatorCells: eliminators,
            unitType: UnitType.box,
          );
        }
      }
    }
  }
  return null;
}

/// Finds a naked quad: four cells in a unit where the union of their
/// candidates is exactly four digits.
NakedQuadResult? findNakedQuad(
    List<List<int>> board, List<List<Set<int>>> pencilMarks) {
  // Check rows
  for (int r = 0; r < 9; r++) {
    final result = _findNakedQuadInUnit(board, r, -1, pencilMarks, UnitType.row);
    if (result != null) return result;
  }
  // Check columns
  for (int c = 0; c < 9; c++) {
    final result = _findNakedQuadInUnit(board, -1, c, pencilMarks, UnitType.column);
    if (result != null) return result;
  }
  // Check boxes
  for (int br = 0; br < 3; br++) {
    for (int bc = 0; bc < 3; bc++) {
      final result = _findNakedQuadInBox(board, br, bc, pencilMarks);
      if (result != null) return result;
    }
  }
  return null;
}

NakedQuadResult? _findNakedQuadInUnit(
    List<List<int>> board, int row, int col,
    List<List<Set<int>>> pencilMarks, UnitType unitType) {
  // Get empty cells with 2-4 candidates
  final candidates = <(int, int), Set<int>>{};
  for (int i = 0; i < 9; i++) {
    final r = unitType == UnitType.row ? row : i;
    final c = unitType == UnitType.column ? col : i;
    if (board[r][c] == 0 && pencilMarks[r][c].length >= 2 && pencilMarks[r][c].length <= 4) {
      candidates[(r, c)] = pencilMarks[r][c];
    }
  }

  final entries = candidates.entries.toList();
  // Check all combinations of 4 cells
  for (int i = 0; i < entries.length; i++) {
    for (int j = i + 1; j < entries.length; j++) {
      for (int k = j + 1; k < entries.length; k++) {
        for (int l = k + 1; l < entries.length; l++) {
          final union = {
            ...entries[i].value,
            ...entries[j].value,
            ...entries[k].value,
            ...entries[l].value,
          };
          if (union.length == 4) {
            final quadCells = {
              entries[i].key,
              entries[j].key,
              entries[k].key,
              entries[l].key,
            };
            final digits = union;

            // Get all cells in unit
            final unitCells = <(int, int)>{};
            if (unitType == UnitType.row) {
              for (int c = 0; c < 9; c++) {
                unitCells.add((row, c));
              }
            } else {
              for (int r = 0; r < 9; r++) {
                unitCells.add((r, col));
              }
            }

            // Eliminators: other cells with these digits
            final eliminators = <(int, int)>{};
            for (final (er, ec) in unitCells) {
              if (quadCells.contains((er, ec))) continue;
              for (final d in digits) {
                if (pencilMarks[er][ec].contains(d)) {
                  eliminators.add((er, ec));
                  break;
                }
              }
            }

            return NakedQuadResult(
              quadCells: quadCells,
              digits: digits,
              unitCells: unitCells,
              eliminatorCells: eliminators,
              unitType: unitType,
            );
          }
        }
      }
    }
  }
  return null;
}

// Similar for boxes
NakedQuadResult? _findNakedQuadInBox(
    List<List<int>> board, int br, int bc,
    List<List<Set<int>>> pencilMarks) {
  final candidates = <(int, int), Set<int>>{};
  for (int r = br * 3; r < br * 3 + 3; r++) {
    for (int c = bc * 3; c < bc * 3 + 3; c++) {
      if (board[r][c] == 0 && pencilMarks[r][c].length >= 2 && pencilMarks[r][c].length <= 4) {
        candidates[(r, c)] = pencilMarks[r][c];
      }
    }
  }

  final entries = candidates.entries.toList();
  for (int i = 0; i < entries.length; i++) {
    for (int j = i + 1; j < entries.length; j++) {
      for (int k = j + 1; k < entries.length; k++) {
        for (int l = k + 1; l < entries.length; l++) {
          final union = {
            ...entries[i].value,
            ...entries[j].value,
            ...entries[k].value,
            ...entries[l].value,
          };
          if (union.length == 4) {
            final quadCells = {
              entries[i].key,
              entries[j].key,
              entries[k].key,
              entries[l].key,
            };
            final digits = union;

            final unitCells = <(int, int)>{
              for (int r = br * 3; r < br * 3 + 3; r++)
                for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
            };

            final eliminators = <(int, int)>{};
            for (final (er, ec) in unitCells) {
              if (quadCells.contains((er, ec))) continue;
              for (final d in digits) {
                if (pencilMarks[er][ec].contains(d)) {
                  eliminators.add((er, ec));
                  break;
                }
              }
            }

            return NakedQuadResult(
              quadCells: quadCells,
              digits: digits,
              unitCells: unitCells,
              eliminatorCells: eliminators,
              unitType: UnitType.box,
            );
          }
        }
      }
    }
  }
  return null;
}
