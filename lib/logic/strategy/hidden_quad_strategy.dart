import 'package:sudoku/logic/strategy_solver.dart' hide StrategyResult, StrategyType;
import 'package:sudoku/logic/strategy/strategy.dart';

class HiddenQuadStrategy extends Strategy {
  @override
  StrategyType get type => StrategyType.hiddenQuad;

  @override
  StrategyResult? find(List<List<int>> board, Map<(int, int), Set<int>> candidates) {
    // Check rows
    for (int r = 0; r < 9; r++) {
      final cells = {for (int c = 0; c < 9; c++) (r, c)};
      final result = _checkUnitForHiddenQuad(cells, UnitType.row, board, candidates);
      if (result != null) return result;
    }
    // Check columns
    for (int c = 0; c < 9; c++) {
      final cells = {for (int r = 0; r < 9; r++) (r, c)};
      final result = _checkUnitForHiddenQuad(cells, UnitType.column, board, candidates);
      if (result != null) return result;
    }
    // Check boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final cells = {
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final result = _checkUnitForHiddenQuad(cells, UnitType.box, board, candidates);
        if (result != null) return result;
      }
    }
    return null;
  }

  StrategyResult? _checkUnitForHiddenQuad(
      Set<(int, int)> unitCells, UnitType unitType,
      List<List<int>> board, Map<(int, int), Set<int>> candidates) {
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
