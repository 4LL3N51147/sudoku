import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/logic/strategy_solver.dart';

void main() {
  group('StrategyHighlight.fromHintStep', () {
    test('creates StrategyHighlight from HintStep with all fields', () {
      const hintStep = HintStep(
        phase: StrategyPhase.elimination,
        message: 'Test message',
        unitCells: {(0, 0), (0, 1)},
        patternCells: {(0, 0)},
        eliminatorCells: {(1, 1)},
        targetCell: (0, 0),
        unitType: UnitType.row,
        patternDigits: {1, 2},
        eliminationCandidates: {(2, 2): {3}},
        eliminationRows: {1},
        eliminationCols: {2},
        eliminationBoxes: {3},
        resultCells: {(4, 4)},
      );

      final highlight = StrategyHighlight.fromHintStep(hintStep);

      expect(highlight.phase, StrategyPhase.elimination);
      expect(highlight.unitCells, hintStep.unitCells);
      expect(highlight.patternCells, hintStep.patternCells);
      expect(highlight.eliminatorCells, hintStep.eliminatorCells);
      expect(highlight.targetCell, hintStep.targetCell);
      expect(highlight.unitType, hintStep.unitType);
      expect(highlight.patternDigits, hintStep.patternDigits);
      expect(highlight.eliminationCandidates, hintStep.eliminationCandidates);
      expect(highlight.eliminationRows, hintStep.eliminationRows);
      expect(highlight.eliminationCols, hintStep.eliminationCols);
      expect(highlight.eliminationBoxes, hintStep.eliminationBoxes);
      expect(highlight.resultCells, hintStep.resultCells);
    });

    test('creates StrategyHighlight from HintStep with minimal fields', () {
      const hintStep = HintStep(
        phase: StrategyPhase.scan,
        unitCells: {(0, 0)},
      );

      final highlight = StrategyHighlight.fromHintStep(hintStep);

      expect(highlight.phase, StrategyPhase.scan);
      expect(highlight.unitCells, {(0, 0)});
      expect(highlight.patternCells, isEmpty);
      expect(highlight.eliminatorCells, isEmpty);
    });
  });
}
