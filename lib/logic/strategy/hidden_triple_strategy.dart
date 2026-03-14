import 'package:sudoku/logic/strategy_solver.dart' hide StrategyResult, StrategyType;
import 'package:sudoku/logic/strategy/strategy.dart';

class HiddenTripleStrategy extends Strategy {
  @override
  StrategyType get type => StrategyType.hiddenTriple;

  @override
  StrategyResult? find(List<List<int>> board, Map<(int, int), Set<int>> candidates) {
    // Check rows
    for (int r = 0; r < 9; r++) {
      final cells = {for (int c = 0; c < 9; c++) (r, c)};
      final result = _checkUnitForHiddenTriple(cells, UnitType.row, board, candidates);
      if (result != null) return result;
    }
    // Check columns
    for (int c = 0; c < 9; c++) {
      final cells = {for (int r = 0; r < 9; r++) (r, c)};
      final result = _checkUnitForHiddenTriple(cells, UnitType.column, board, candidates);
      if (result != null) return result;
    }
    // Check boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final cells = {
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final result = _checkUnitForHiddenTriple(cells, UnitType.box, board, candidates);
        if (result != null) return result;
      }
    }
    return null;
  }

  StrategyResult? _checkUnitForHiddenTriple(
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
}
