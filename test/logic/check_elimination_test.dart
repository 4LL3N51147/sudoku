import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/logic/strategy_solver.dart';

void main() {
  test('check elimination zones for original board', () {
    final board = [
      [0, 0, 0, 6, 2, 0, 1, 0, 8],
      [0, 0, 6, 0, 0, 0, 0, 0, 0],
      [2, 9, 0, 7, 0, 0, 0, 0, 0],
      [0, 0, 0, 3, 0, 0, 0, 1, 0],
      [0, 0, 5, 8, 4, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 6, 0, 8, 4],
      [0, 3, 2, 4, 0, 7, 9, 0, 0],
      [0, 7, 0, 2, 0, 5, 0, 4, 3],
      [0, 5, 0, 9, 0, 0, 6, 7, 2],
    ];

    final solver = StrategySolver(board);
    final result = solver.findHiddenSingle();

    print('=== Strategy Result ===');
    print('targetCell: ${result!.targetCell}');
    print('unitType: ${result.unitType}');
    print('patternDigits: ${result.patternDigits}');
    print('eliminationRows: ${result.eliminationRows}');
    print('eliminationCols: ${result.eliminationCols}');
    print('eliminationBoxes: ${result.eliminationBoxes}');

    // Check hintSteps
    print('=== Hint Steps ===');
    for (int i = 0; i < result.hintSteps.length; i++) {
      final step = result.hintSteps[i];
      print('Step $i: phase=${step.phase}, message=${step.message}');
      print('  eliminatorCells: ${step.eliminatorCells}');
      print('  eliminationRows: ${step.eliminationRows}');
      print('  eliminationCols: ${step.eliminationCols}');
      print('  eliminationBoxes: ${step.eliminationBoxes}');
    }
  });
}
