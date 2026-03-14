import 'package:sudoku/logic/strategy_solver.dart' hide StrategyResult, StrategyType, Strategy, StrategyHighlight;
import 'package:sudoku/logic/strategy/strategy.dart';

class NakedTripleStrategy extends Strategy {
  @override
  StrategyType get type => StrategyType.nakedTriple;

  @override
  StrategyResult? find(List<List<int>> board, Map<(int, int), Set<int>> candidates) {
    // Check rows
    for (int r = 0; r < 9; r++) {
      final cells = {for (int c = 0; c < 9; c++) (r, c)};
      final result = _checkUnitForNakedTriple(cells, UnitType.row, board, candidates);
      if (result != null) return result;
    }
    // Check columns
    for (int c = 0; c < 9; c++) {
      final cells = {for (int r = 0; r < 9; r++) (r, c)};
      final result = _checkUnitForNakedTriple(cells, UnitType.column, board, candidates);
      if (result != null) return result;
    }
    // Check boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final cells = {
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final result = _checkUnitForNakedTriple(cells, UnitType.box, board, candidates);
        if (result != null) return result;
      }
    }
    return null;
  }

  StrategyResult? _checkUnitForNakedTriple(
      Set<(int, int)> unitCells, UnitType unitType,
      List<List<int>> board, Map<(int, int), Set<int>> candidates) {
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
}
