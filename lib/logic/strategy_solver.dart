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

  /// Create a solver. If candidates are provided, use them instead of computing fresh.
  /// This preserves manual eliminations from hints.
  StrategySolver(this.board, [Map<(int, int), Set<int>>? existingCandidates])
      : candidates = existingCandidates ?? computeCandidates(board);


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
        final eliminationRows = <int>{};
        final eliminationCols = <int>{};
        final eliminationBoxes = <int>{};

        // For each empty cell in the unit (not the target), find which specific constraint eliminates it
        // The elimination zone is the specific column, row, or box that contains the digit and blocks this cell
        for (final (r, c) in unitCells) {
          if ((r, c) == (tr, tc)) continue;
          if (board[r][c] != 0) continue;

          // Add blockers (cells with the digit that block this cell)
          eliminators.addAll(_findBlockers(r, c, digit));

          // Compute elimination zones per empty cell - which specific constraint eliminates this cell
          // Priority: box > row > column (boxes take priority when there's intersection)
          if (unitType == UnitType.row) {
            // For row hidden single: boxes take priority over columns
            // First check if the box containing this cell (r, c) has the digit elsewhere
            final cellBox = (r ~/ 3) * 3 + (c ~/ 3);
            bool boxHasDigit = false;
            for (int rr = (cellBox ~/ 3) * 3; rr < (cellBox ~/ 3) * 3 + 3; rr++) {
              for (int cc = (cellBox % 3) * 3; cc < (cellBox % 3) * 3 + 3; cc++) {
                if ((rr, cc) != (r, c) && board[rr][cc] == digit) {
                  eliminationBoxes.add(cellBox);
                  boxHasDigit = true;
                  break;
                }
              }
              if (boxHasDigit) break;
            }
            // Only check column if box doesn't have the digit (boxes take priority)
            if (!boxHasDigit) {
              for (int rr = 0; rr < 9; rr++) {
                if (rr != tr && board[rr][c] == digit) {
                  eliminationCols.add(c);
                  break;
                }
              }
            }
          } else if (unitType == UnitType.column) {
            // For column hidden single: boxes take priority over rows
            // First check if the box containing this cell (r, c) has the digit elsewhere
            final cellBox = (r ~/ 3) * 3 + (c ~/ 3);
            bool boxHasDigit = false;
            for (int rr = (cellBox ~/ 3) * 3; rr < (cellBox ~/ 3) * 3 + 3; rr++) {
              for (int cc = (cellBox % 3) * 3; cc < (cellBox % 3) * 3 + 3; cc++) {
                if ((rr, cc) != (r, c) && board[rr][cc] == digit) {
                  eliminationBoxes.add(cellBox);
                  boxHasDigit = true;
                  break;
                }
              }
              if (boxHasDigit) break;
            }
            // Only check row if box doesn't have the digit (boxes take priority)
            if (!boxHasDigit) {
              for (int cc = 0; cc < 9; cc++) {
                if (cc != tc && board[r][cc] == digit) {
                  eliminationRows.add(r);
                  break;
                }
              }
            }
          } else if (unitType == UnitType.box) {
            // For box hidden single: rows take priority over columns
            // First check if row r has the digit elsewhere
            bool rowHasDigit = false;
            for (int cc = 0; cc < 9; cc++) {
              if (board[r][cc] == digit && cc != c) {
                eliminationRows.add(r);
                rowHasDigit = true;
                break;
              }
            }
            // Only check column if row doesn't have the digit (rows take priority)
            if (!rowHasDigit) {
              for (int rr = 0; rr < 9; rr++) {
                if (board[rr][c] == digit && rr != r) {
                  eliminationCols.add(c);
                  break;
                }
              }
            }
          }
        }

        final unitLabel = switch (unitType) {
          UnitType.row => 'row',
          UnitType.column => 'column',
          UnitType.box => 'box',
        };
        
        // Compute eliminator cells - cells that contain the digit and block positions
        // For row hidden single: cells in THIS ROW with the digit
        // For column hidden single: cells in THIS COLUMN with the digit  
        // For box hidden single: cells in THIS BOX with the digit
        final eliminatorCells = <(int, int)>{};
        
        if (unitType == UnitType.row) {
          for (int cc = 0; cc < 9; cc++) {
            if (cc != tc && board[tr][cc] == digit) {
              eliminatorCells.add((tr, cc));
            }
          }
        } else if (unitType == UnitType.column) {
          for (int rr = 0; rr < 9; rr++) {
            if (rr != tr && board[rr][tc] == digit) {
              eliminatorCells.add((rr, tc));
            }
          }
        } else if (unitType == UnitType.box) {
          final targetBox = (tr ~/ 3) * 3 + (tc ~/ 3);
          for (int rr = (targetBox ~/ 3) * 3; rr < (targetBox ~/ 3) * 3 + 3; rr++) {
            for (int cc = (targetBox % 3) * 3; cc < (targetBox % 3) * 3 + 3; cc++) {
              if ((rr, cc) != (tr, tc) && board[rr][cc] == digit) {
                eliminatorCells.add((rr, cc));
              }
            }
          }
        }
        
        // Hidden single: Scan -> Elimination -> Target
        final steps = [
          HintStep(
            phase: StrategyPhase.scan,
            message: 'Scanning this $unitLabel — looking for $digit',
            unitCells: unitCells,
            patternDigits: {digit},
            unitType: unitType,
          ),
          HintStep(
            phase: StrategyPhase.elimination,
            message: '$digit can only go in 1 cell in this $unitLabel!',
            unitCells: unitCells,
            patternCells: {(tr, tc)},
            patternDigits: {digit},
            targetCell: (tr, tc),
            unitType: unitType,
            eliminatorCells: eliminators,
            eliminationRows: eliminationRows,
            eliminationCols: eliminationCols,
            eliminationBoxes: eliminationBoxes,
          ),
          HintStep(
            phase: StrategyPhase.target,
            message: 'Now you can place $digit in this cell!',
            unitCells: unitCells,
            patternCells: {(tr, tc)},
            patternDigits: {digit},
            targetCell: (tr, tc),
            unitType: unitType,
          ),
        ];
        
        return StrategyResult(
          type: StrategyType.hiddenSingle,
          phase: StrategyPhase.target,
          unitType: unitType,
          unitCells: unitCells,
          patternCells: {(tr, tc)},
          patternDigits: {digit},
          eliminationCells: eliminators,
          targetCell: (tr, tc),
          eliminationRows: eliminationRows,
          eliminationCols: eliminationCols,
          eliminationBoxes: eliminationBoxes,
          hintSteps: steps,
        );
      }
    }
    return null;
  }

  Set<(int, int)> _findBlockers(int row, int col, int digit) {
    // Priority: box > row > column - each cell should have only one blocker
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        if (board[r][c] == digit) return {(r, c)};
      }
    }
    for (int c = 0; c < 9; c++) {
      if (c != col && board[row][c] == digit) return {(row, c)};
    }
    for (int r = 0; r < 9; r++) {
      if (r != row && board[r][col] == digit) return {(r, col)};
    }
    return {};
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

    // Find pairs: cells with exactly the same 2 candidates.
    // Use a sorted string key because Dart's Set doesn't override == for content equality.
    final seen = <String, List<(int, int)>>{};
    for (final cell in emptyCells) {
      final cellCandidates = candidates[cell]!;
      if (cellCandidates.length == 2) {
        final key = (cellCandidates.toList()..sort()).join(',');
        seen.putIfAbsent(key, () => []).add(cell);
      }
    }

    for (final entry in seen.entries) {
      if (entry.value.length >= 2) {
        final pairCells = entry.value.take(2).toSet();
        final pairDigits = candidates[entry.value.first]!;

        // Find elimination cells (other empty cells in unit that contain these digits)
        // Also track which specific digits to eliminate from each cell
        final eliminationCells = <(int, int)>{};
        final eliminationCandidates = <(int, int), Set<int>>{};
        for (final cell in emptyCells) {
          if (!pairCells.contains(cell)) {
            final cellCand = candidates[cell]!;
            final digitsToRemove = <int>{};
            for (final d in pairDigits) {
              if (cellCand.contains(d)) {
                eliminationCells.add(cell);
                digitsToRemove.add(d);
              }
            }
            if (digitsToRemove.isNotEmpty) {
              eliminationCandidates[cell] = digitsToRemove;
            }
          }
        }

        if (eliminationCells.isNotEmpty) {
          // Compute result cells: cells that now have only 1 candidate after elimination
          final resultCells = <(int, int)>{};
          for (final cell in emptyCells) {
            if (!pairCells.contains(cell)) {
              final cellCand = candidates[cell]!;
              final remainingAfterElimination = cellCand.difference(pairDigits);
              if (remainingAfterElimination.length == 1) {
                resultCells.add(cell);
              }
            }
          }

          // Naked pair: Scan -> Pattern -> Elimination -> Target
          final unitLabel = switch (unitType) {
            UnitType.row => 'row',
            UnitType.column => 'column',
            UnitType.box => 'box',
          };
          final pairSteps = [
            HintStep(
              phase: StrategyPhase.scan,
              message: 'Scanning this $unitLabel — looking for $pairDigits',
              unitCells: unitCells,
              patternDigits: pairDigits,
              unitType: unitType,
            ),
            HintStep(
              phase: StrategyPhase.elimination,
              message: 'Naked Pair: $pairDigits are locked in these 2 cells',
              unitCells: unitCells,
              patternCells: pairCells,
              patternDigits: pairDigits,
              unitType: unitType,
            ),
            HintStep(
              phase: StrategyPhase.elimination,
              message: 'Remove $pairDigits from ${eliminationCells.length} other cell${eliminationCells.length > 1 ? 's' : ''} in this $unitLabel',
              unitCells: unitCells,
              patternCells: pairCells,
              eliminatorCells: eliminationCells,
              patternDigits: pairDigits,
              eliminationCandidates: eliminationCandidates,
              unitType: unitType,
            ),
          ];

          return StrategyResult(
            type: StrategyType.nakedPair,
            phase: StrategyPhase.elimination,
            unitType: unitType,
            unitCells: unitCells,
            patternCells: pairCells,
            patternDigits: pairDigits,
            eliminationCells: eliminationCells,
            eliminationCandidates: eliminationCandidates,
            resultCells: resultCells,
            hintSteps: pairSteps,
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
          final cells1Set = cells1.toSet();
          final cells2Set = cells2.toSet();
          // Check that both digits are in the SAME 2 cells
          if (cells1Set.length == 2 && cells2Set.length == 2 && 
              cells1Set.containsAll(cells2Set)) {
            final pairCells = cells1Set;
            // Found hidden pair - eliminate OTHER digits from these cells (not the pair digits)
            // eliminationCells = the pair cells themselves
            // eliminationCandidates = other candidates to remove from those cells
            final eliminationCells = pairCells;
            final eliminationCandidates = <(int, int), Set<int>>{};
            for (final cell in pairCells) {
              final cellCand = candidates[cell]!;
              final otherDigits = cellCand.difference({d1, d2});
              if (otherDigits.isNotEmpty) {
                eliminationCandidates[cell] = otherDigits;
              }
            }

            if (eliminationCandidates.isNotEmpty) {
              // Compute elimination zones for the pattern digits
              final elimRows = <int>{};
              final elimCols = <int>{};
              final elimBoxes = <int>{};
              for (final cell in pairCells) {
                final (r, c) = cell;
                for (final d in {d1, d2}) {
                  // Check row
                  for (int cc = 0; cc < 9; cc++) {
                    if (board[r][cc] == d) elimRows.add(r);
                  }
                  // Check column
                  for (int rr = 0; rr < 9; rr++) {
                    if (board[rr][c] == d) elimCols.add(c);
                  }
                  // Check box
                  final br = (r ~/ 3) * 3;
                  final bc = (c ~/ 3) * 3;
                  for (int rr = br; rr < br + 3; rr++) {
                    for (int cc = bc; cc < bc + 3; cc++) {
                      if (board[rr][cc] == d) {
                        elimBoxes.add((r ~/ 3) * 3 + (c ~/ 3));
                      }
                    }
                  }
                }
              }

              // Hidden pair: Scan -> Pattern -> Elimination
              final unitLabel = switch (unitType) {
                UnitType.row => 'row',
                UnitType.column => 'column',
                UnitType.box => 'box',
              };
              final pairDigits = {d1, d2};
              final hiddenPairSteps = [
                HintStep(
                  phase: StrategyPhase.scan,
                  message: 'Scanning this $unitLabel — looking for hidden pair',
                  unitCells: unitCells,
                  patternDigits: pairDigits,
                  unitType: unitType,
                ),
                HintStep(
                  phase: StrategyPhase.elimination,
                  message: 'Hidden Pair: $pairDigits are locked in these 2 cells',
                  unitCells: unitCells,
                  patternCells: pairCells,
                  patternDigits: pairDigits,
                  unitType: unitType,
                ),
                HintStep(
                  phase: StrategyPhase.elimination,
                  message: 'Remove other candidates from these ${pairCells.length} cells',
                  unitCells: unitCells,
                  patternCells: pairCells,
                  eliminatorCells: eliminationCells,
                  patternDigits: pairDigits,
                  eliminationCandidates: eliminationCandidates,
                  eliminationRows: elimRows,
                  eliminationCols: elimCols,
                  eliminationBoxes: elimBoxes,
                  unitType: unitType,
                ),
              ];

              return StrategyResult(
                type: StrategyType.hiddenPair,
                phase: StrategyPhase.elimination,
                unitType: unitType,
                unitCells: unitCells,
                patternCells: pairCells,
                patternDigits: pairDigits,
                eliminationCells: eliminationCells,
                eliminationCandidates: eliminationCandidates,
                eliminationRows: elimRows,
                eliminationCols: elimCols,
                eliminationBoxes: elimBoxes,
                hintSteps: hiddenPairSteps,
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
              // Build elimination candidates map: which digits to remove from which cells
              final eliminationCandidates = <(int, int), Set<int>>{};
              for (final cell in eliminationCells) {
                final cellCand = candidates[cell]!;
                final digitsToRemove = cellCand.intersection(combinedCandidates);
                if (digitsToRemove.isNotEmpty) {
                  eliminationCandidates[cell] = digitsToRemove;
                }
              }

              // Compute result cells: cells that now have only 1 candidate after elimination
              final resultCells = <(int, int)>{};
              for (final cell in emptyCells) {
                if (!triple.contains(cell)) {
                  final cellCand = candidates[cell]!;
                  final remainingAfterElimination = cellCand.difference(combinedCandidates);
                  if (remainingAfterElimination.length == 1) {
                    resultCells.add(cell);
                  }
                }
              }

              // Naked triple: Scan -> Pattern -> Elimination
              final unitLabel = switch (unitType) {
                UnitType.row => 'row',
                UnitType.column => 'column',
                UnitType.box => 'box',
              };
              final tripleSteps = [
                HintStep(
                  phase: StrategyPhase.scan,
                  message: 'Scanning this $unitLabel — looking for naked triple',
                  unitCells: unitCells,
                  patternDigits: combinedCandidates,
                  unitType: unitType,
                ),
                HintStep(
                  phase: StrategyPhase.elimination,
                  message: 'Naked Triple: $combinedCandidates are locked in these 3 cells',
                  unitCells: unitCells,
                  patternCells: triple.toSet(),
                  patternDigits: combinedCandidates,
                  unitType: unitType,
                ),
                HintStep(
                  phase: StrategyPhase.elimination,
                  message: 'Remove $combinedCandidates from ${eliminationCells.length} other cell${eliminationCells.length > 1 ? 's' : ''} in this $unitLabel',
                  unitCells: unitCells,
                  patternCells: triple.toSet(),
                  eliminatorCells: eliminationCells,
                  patternDigits: combinedCandidates,
                  eliminationCandidates: eliminationCandidates,
                  unitType: unitType,
                ),
              ];

              return StrategyResult(
                type: StrategyType.nakedTriple,
                phase: StrategyPhase.elimination,
                unitType: unitType,
                unitCells: unitCells,
                patternCells: triple.toSet(),
                patternDigits: combinedCandidates,
                eliminationCells: eliminationCells,
                eliminationCandidates: eliminationCandidates,
                resultCells: resultCells,
                hintSteps: tripleSteps,
              );
            }
          }
        }
      }
    }
    return null;
  }

  /// Find hidden triples in the board
  StrategyResult? findHiddenTriple() {
    // Check rows
    for (int r = 0; r < 9; r++) {
      final cells = {for (int c = 0; c < 9; c++) (r, c)};
      final result = _checkUnitForHiddenTriple(cells, UnitType.row);
      if (result != null) return result;
    }
    // Check columns
    for (int c = 0; c < 9; c++) {
      final cells = {for (int r = 0; r < 9; r++) (r, c)};
      final result = _checkUnitForHiddenTriple(cells, UnitType.column);
      if (result != null) return result;
    }
    // Check boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final cells = {
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final result = _checkUnitForHiddenTriple(cells, UnitType.box);
        if (result != null) return result;
      }
    }
    return null;
  }

  /// Check a unit for hidden triples
  StrategyResult? _checkUnitForHiddenTriple(
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

    // Find all digit triples
    final digits = digitToCells.keys.toList();
    for (int i = 0; i < digits.length; i++) {
      for (int j = i + 1; j < digits.length; j++) {
        for (int k = j + 1; k < digits.length; k++) {
          final d1 = digits[i];
          final d2 = digits[j];
          final d3 = digits[k];
          final cells1 = digitToCells[d1]!;
          final cells2 = digitToCells[d2]!;
          final cells3 = digitToCells[d3]!;

          // All three digits appear in exactly the same 3 cells
          final tripleCells = cells1.toSet();
          if (tripleCells.length == 3 &&
              cells2.toSet().length == 3 &&
              cells3.toSet().length == 3 &&
              cells2.toSet().containsAll(tripleCells) &&
              cells3.toSet().containsAll(tripleCells)) {
            // Found hidden triple - eliminate OTHER digits from these triple cells
            // These 3 cells MUST contain {d1, d2, d3}, so remove other candidates
            final eliminationCells = tripleCells;
            final eliminationCandidates = <(int, int), Set<int>>{};
            for (final cell in tripleCells) {
              final cellCand = candidates[cell]!;
              final otherDigits = cellCand.difference({d1, d2, d3});
              if (otherDigits.isNotEmpty) {
                eliminationCandidates[cell] = otherDigits;
              }
            }

            if (eliminationCandidates.isNotEmpty) {
              // Compute elimination zones for the pattern digits
              final elimRows = <int>{};
              final elimCols = <int>{};
              final elimBoxes = <int>{};
              for (final cell in tripleCells) {
                final (r, c) = cell;
                for (final d in {d1, d2, d3}) {
                  // Check row
                  for (int cc = 0; cc < 9; cc++) {
                    if (board[r][cc] == d) elimRows.add(r);
                  }
                  // Check column
                  for (int rr = 0; rr < 9; rr++) {
                    if (board[rr][c] == d) elimCols.add(c);
                  }
                  // Check box
                  for (int rr = (r ~/ 3) * 3; rr < (r ~/ 3) * 3 + 3; rr++) {
                    for (int cc = (c ~/ 3) * 3; cc < (c ~/ 3) * 3 + 3; cc++) {
                      if (board[rr][cc] == d) {
                        elimBoxes.add((r ~/ 3) * 3 + (c ~/ 3));
                      }
                    }
                  }
                }
              }
              // Hidden triple: Scan -> Pattern -> Elimination
              final unitLabel = switch (unitType) {
                UnitType.row => 'row',
                UnitType.column => 'column',
                UnitType.box => 'box',
              };
              final tripleDigits = {d1, d2, d3};
              final hiddenTripleSteps = [
                HintStep(
                  phase: StrategyPhase.scan,
                  message: 'Scanning this $unitLabel — looking for hidden triple',
                  unitCells: unitCells,
                  patternDigits: tripleDigits,
                  unitType: unitType,
                ),
                HintStep(
                  phase: StrategyPhase.elimination,
                  message: 'Hidden Triple: $tripleDigits are locked in these 3 cells',
                  unitCells: unitCells,
                  patternCells: tripleCells,
                  patternDigits: tripleDigits,
                  unitType: unitType,
                ),
                HintStep(
                  phase: StrategyPhase.elimination,
                  message: 'Remove other candidates from these ${tripleCells.length} cells',
                  unitCells: unitCells,
                  patternCells: tripleCells,
                  eliminatorCells: eliminationCells,
                  patternDigits: tripleDigits,
                  eliminationCandidates: eliminationCandidates,
                  eliminationRows: elimRows,
                  eliminationCols: elimCols,
                  eliminationBoxes: elimBoxes,
                  unitType: unitType,
                ),
              ];

              return StrategyResult(
                type: StrategyType.hiddenTriple,
                phase: StrategyPhase.elimination,
                unitType: unitType,
                unitCells: unitCells,
                patternCells: tripleCells,
                patternDigits: tripleDigits,
                eliminationCells: eliminationCells,
                eliminationCandidates: eliminationCandidates,
                eliminationRows: elimRows,
                eliminationCols: elimCols,
                eliminationBoxes: elimBoxes,
                hintSteps: hiddenTripleSteps,
              );
            }
          }
        }
      }
    }
    return null;
  }

  /// Find naked quads in the board
  StrategyResult? findNakedQuad() {
    // Check rows
    for (int r = 0; r < 9; r++) {
      final cells = {for (int c = 0; c < 9; c++) (r, c)};
      final result = _checkUnitForNakedQuad(cells, UnitType.row);
      if (result != null) return result;
    }
    // Check columns
    for (int c = 0; c < 9; c++) {
      final cells = {for (int r = 0; r < 9; r++) (r, c)};
      final result = _checkUnitForNakedQuad(cells, UnitType.column);
      if (result != null) return result;
    }
    // Check boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final cells = {
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final result = _checkUnitForNakedQuad(cells, UnitType.box);
        if (result != null) return result;
      }
    }
    return null;
  }

  /// Check a unit for naked quads
  StrategyResult? _checkUnitForNakedQuad(
      Set<(int, int)> unitCells, UnitType unitType) {
    final emptyCells = unitCells
        .where((rc) => candidates[rc] != null && candidates[rc]!.isNotEmpty)
        .toList();

    // Find all combinations of 4 cells
    for (int i = 0; i < emptyCells.length; i++) {
      for (int j = i + 1; j < emptyCells.length; j++) {
        for (int k = j + 1; k < emptyCells.length; k++) {
          for (int l = k + 1; l < emptyCells.length; l++) {
            final quad = [
              emptyCells[i],
              emptyCells[j],
              emptyCells[k],
              emptyCells[l]
            ];
            final combinedCandidates = <int>{};
            for (final cell in quad) {
              combinedCandidates.addAll(candidates[cell]!);
            }

            // Naked quad: exactly 4 combined candidates
            if (combinedCandidates.length == 4) {
              // Find elimination cells
              final eliminationCells = <(int, int)>{};
              for (final cell in emptyCells) {
                if (!quad.contains(cell)) {
                  final cellCand = candidates[cell]!;
                  for (final d in combinedCandidates) {
                    if (cellCand.contains(d)) {
                      eliminationCells.add(cell);
                    }
                  }
                }
              }

              if (eliminationCells.isNotEmpty) {
                // Build elimination candidates map: which digits to remove from which cells
                final eliminationCandidates = <(int, int), Set<int>>{};
                for (final cell in eliminationCells) {
                  final cellCand = candidates[cell]!;
                  final digitsToRemove = cellCand.intersection(combinedCandidates);
                  if (digitsToRemove.isNotEmpty) {
                    eliminationCandidates[cell] = digitsToRemove;
                  }
                }

                // Compute result cells: cells that now have only 1 candidate after elimination
                final resultCells = <(int, int)>{};
                for (final cell in emptyCells) {
                  if (!quad.contains(cell)) {
                    final cellCand = candidates[cell]!;
                    final remainingAfterElimination = cellCand.difference(combinedCandidates);
                    if (remainingAfterElimination.length == 1) {
                      resultCells.add(cell);
                    }
                  }
                }

                // Naked quad: Scan -> Pattern -> Elimination
                final unitLabel = switch (unitType) {
                  UnitType.row => 'row',
                  UnitType.column => 'column',
                  UnitType.box => 'box',
                };
                final quadSteps = [
                  HintStep(
                    phase: StrategyPhase.scan,
                    message: 'Scanning this $unitLabel — looking for naked quad',
                    unitCells: unitCells,
                    patternDigits: combinedCandidates,
                    unitType: unitType,
                  ),
                  HintStep(
                    phase: StrategyPhase.elimination,
                    message: 'Naked Quad: $combinedCandidates are locked in these 4 cells',
                    unitCells: unitCells,
                    patternCells: quad.toSet(),
                    patternDigits: combinedCandidates,
                    unitType: unitType,
                  ),
                  HintStep(
                    phase: StrategyPhase.elimination,
                    message: 'Remove $combinedCandidates from ${eliminationCells.length} other cell${eliminationCells.length > 1 ? 's' : ''} in this $unitLabel',
                    unitCells: unitCells,
                    patternCells: quad.toSet(),
                    eliminatorCells: eliminationCells,
                    patternDigits: combinedCandidates,
                    eliminationCandidates: eliminationCandidates,
                    unitType: unitType,
                  ),
                ];

                return StrategyResult(
                  type: StrategyType.nakedQuad,
                  phase: StrategyPhase.elimination,
                  unitType: unitType,
                  unitCells: unitCells,
                  patternCells: quad.toSet(),
                  patternDigits: combinedCandidates,
                  eliminationCells: eliminationCells,
                  eliminationCandidates: eliminationCandidates,
                  resultCells: resultCells,
                  hintSteps: quadSteps,
                );
              }
            }
          }
        }
      }
    }
    return null;
  }

  /// Find hidden quads in the board
  StrategyResult? findHiddenQuad() {
    // Check rows
    for (int r = 0; r < 9; r++) {
      final cells = {for (int c = 0; c < 9; c++) (r, c)};
      final result = _checkUnitForHiddenQuad(cells, UnitType.row);
      if (result != null) return result;
    }
    // Check columns
    for (int c = 0; c < 9; c++) {
      final cells = {for (int r = 0; r < 9; r++) (r, c)};
      final result = _checkUnitForHiddenQuad(cells, UnitType.column);
      if (result != null) return result;
    }
    // Check boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final cells = {
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final result = _checkUnitForHiddenQuad(cells, UnitType.box);
        if (result != null) return result;
      }
    }
    return null;
  }

  /// Check a unit for hidden quads
  StrategyResult? _checkUnitForHiddenQuad(
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

    // Find all digit quadruples
    final digits = digitToCells.keys.toList();
    for (int i = 0; i < digits.length; i++) {
      for (int j = i + 1; j < digits.length; j++) {
        for (int k = j + 1; k < digits.length; k++) {
          for (int l = k + 1; l < digits.length; l++) {
            final d1 = digits[i];
            final d2 = digits[j];
            final d3 = digits[k];
            final d4 = digits[l];
            final cells1 = digitToCells[d1]!;
            final cells2 = digitToCells[d2]!;
            final cells3 = digitToCells[d3]!;
            final cells4 = digitToCells[d4]!;

            // All four digits appear in exactly the same 4 cells
            final quadCells = cells1.toSet();
            if (quadCells.length == 4 &&
                cells2.toSet().length == 4 &&
                cells3.toSet().length == 4 &&
                cells4.toSet().length == 4 &&
                cells2.toSet().containsAll(quadCells) &&
                cells3.toSet().containsAll(quadCells) &&
                cells4.toSet().containsAll(quadCells)) {
              // Found hidden quad - eliminate OTHER digits from these quad cells
              // These 4 cells MUST contain {d1, d2, d3, d4}, so remove other candidates
              final eliminationCells = quadCells;
              final eliminationCandidates = <(int, int), Set<int>>{};
              for (final cell in quadCells) {
                final cellCand = candidates[cell]!;
                final otherDigits = cellCand.difference({d1, d2, d3, d4});
                if (otherDigits.isNotEmpty) {
                  eliminationCandidates[cell] = otherDigits;
                }
              }

              if (eliminationCandidates.isNotEmpty) {
                // Compute elimination zones for the pattern digits
                final elimRows = <int>{};
                final elimCols = <int>{};
                final elimBoxes = <int>{};
                for (final cell in quadCells) {
                  final (r, c) = cell;
                  for (final d in {d1, d2, d3, d4}) {
                    // Check row
                    for (int cc = 0; cc < 9; cc++) {
                      if (board[r][cc] == d) elimRows.add(r);
                    }
                    // Check column
                    for (int rr = 0; rr < 9; rr++) {
                      if (board[rr][c] == d) elimCols.add(c);
                    }
                    // Check box
                    for (int rr = (r ~/ 3) * 3; rr < (r ~/ 3) * 3 + 3; rr++) {
                      for (int cc = (c ~/ 3) * 3; cc < (c ~/ 3) * 3 + 3; cc++) {
                        if (board[rr][cc] == d) {
                          elimBoxes.add((r ~/ 3) * 3 + (c ~/ 3));
                        }
                      }
                    }
                  }
                }
                // Hidden quad: Scan -> Pattern -> Elimination
                final unitLabel = switch (unitType) {
                  UnitType.row => 'row',
                  UnitType.column => 'column',
                  UnitType.box => 'box',
                };
                final quadDigits = {d1, d2, d3, d4};
                final hiddenQuadSteps = [
                  HintStep(
                    phase: StrategyPhase.scan,
                    message: 'Scanning this $unitLabel — looking for hidden quad',
                    unitCells: unitCells,
                    patternDigits: quadDigits,
                    unitType: unitType,
                  ),
                  HintStep(
                    phase: StrategyPhase.elimination,
                    message: 'Hidden Quad: $quadDigits are locked in these 4 cells',
                    unitCells: unitCells,
                    patternCells: quadCells,
                    patternDigits: quadDigits,
                    unitType: unitType,
                  ),
                  HintStep(
                    phase: StrategyPhase.elimination,
                    message: 'Remove other candidates from these ${quadCells.length} cells',
                    unitCells: unitCells,
                    patternCells: quadCells,
                    eliminatorCells: eliminationCells,
                    patternDigits: quadDigits,
                    eliminationCandidates: eliminationCandidates,
                    eliminationRows: elimRows,
                    eliminationCols: elimCols,
                    eliminationBoxes: elimBoxes,
                    unitType: unitType,
                  ),
                ];

                return StrategyResult(
                  type: StrategyType.hiddenQuad,
                  phase: StrategyPhase.elimination,
                  unitType: unitType,
                  unitCells: unitCells,
                  patternCells: quadCells,
                  patternDigits: quadDigits,
                  eliminationCells: eliminationCells,
                  eliminationCandidates: eliminationCandidates,
                  eliminationRows: elimRows,
                  eliminationCols: elimCols,
                  eliminationBoxes: elimBoxes,
                  hintSteps: hiddenQuadSteps,
                );
              }
            }
          }
        }
      }
    }
    return null;
  }
}
