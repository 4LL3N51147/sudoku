import 'package:sudoku/logic/strategy_solver.dart' hide StrategyResult, StrategyType;
import 'package:sudoku/logic/strategy/strategy.dart';

class NakedQuadStrategy extends Strategy {
  @override
  StrategyType get type => StrategyType.nakedQuad;

  @override
  StrategyResult? find(List<List<int>> board, Map<(int, int), Set<int>> candidates) {
    // Check rows
    for (int r = 0; r < 9; r++) {
      final cells = {for (int c = 0; c < 9; c++) (r, c)};
      final result = _checkUnitForNakedQuad(cells, UnitType.row, board, candidates);
      if (result != null) return result;
    }
    // Check columns
    for (int c = 0; c < 9; c++) {
      final cells = {for (int r = 0; r < 9; r++) (r, c)};
      final result = _checkUnitForNakedQuad(cells, UnitType.column, board, candidates);
      if (result != null) return result;
    }
    // Check boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final cells = {
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final result = _checkUnitForNakedQuad(cells, UnitType.box, board, candidates);
        if (result != null) return result;
      }
    }
    return null;
  }

  StrategyResult? _checkUnitForNakedQuad(
      Set<(int, int)> unitCells, UnitType unitType,
      List<List<int>> board, Map<(int, int), Set<int>> candidates) {
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
}
