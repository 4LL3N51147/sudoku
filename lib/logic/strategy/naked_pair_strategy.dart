import 'package:sudoku/logic/strategy_solver.dart' hide StrategyResult, StrategyType;
import 'package:sudoku/logic/strategy/strategy.dart';

class NakedPairStrategy extends Strategy {
  @override
  StrategyType get type => StrategyType.nakedPair;

  @override
  StrategyResult? find(List<List<int>> board, Map<(int, int), Set<int>> candidates) {
    // Check rows
    for (int r = 0; r < 9; r++) {
      final cells = {for (int c = 0; c < 9; c++) (r, c)};
      final result = _checkUnitForNakedPair(cells, UnitType.row, board, candidates);
      if (result != null) return result;
    }
    // Check columns
    for (int c = 0; c < 9; c++) {
      final cells = {for (int r = 0; r < 9; r++) (r, c)};
      final result = _checkUnitForNakedPair(cells, UnitType.column, board, candidates);
      if (result != null) return result;
    }
    // Check boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final cells = {
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final result = _checkUnitForNakedPair(cells, UnitType.box, board, candidates);
        if (result != null) return result;
      }
    }
    return null;
  }

  StrategyResult? _checkUnitForNakedPair(
      Set<(int, int)> unitCells, UnitType unitType,
      List<List<int>> board, Map<(int, int), Set<int>> candidates) {
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
}
