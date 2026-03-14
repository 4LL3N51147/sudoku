import 'package:sudoku/logic/strategy_solver.dart' hide StrategyResult, StrategyType;
import 'package:sudoku/logic/strategy/strategy.dart';

class HiddenPairStrategy extends Strategy {
  @override
  StrategyType get type => StrategyType.hiddenPair;

  @override
  StrategyResult? find(List<List<int>> board, Map<(int, int), Set<int>> candidates) {
    // Check rows
    for (int r = 0; r < 9; r++) {
      final cells = {for (int c = 0; c < 9; c++) (r, c)};
      final result = _checkUnitForHiddenPair(cells, UnitType.row, board, candidates);
      if (result != null) return result;
    }
    // Check columns
    for (int c = 0; c < 9; c++) {
      final cells = {for (int r = 0; r < 9; r++) (r, c)};
      final result = _checkUnitForHiddenPair(cells, UnitType.column, board, candidates);
      if (result != null) return result;
    }
    // Check boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final cells = {
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final result = _checkUnitForHiddenPair(cells, UnitType.box, board, candidates);
        if (result != null) return result;
      }
    }
    return null;
  }

  StrategyResult? _checkUnitForHiddenPair(
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
}
