import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/logic/strategy_solver.dart';

void main() {
  group('findHiddenSingle', () {
    test('returns null for a fully solved board', () {
      final board = [
        [5,3,4,6,7,8,9,1,2],
        [6,7,2,1,9,5,3,4,8],
        [1,9,8,3,4,2,5,6,7],
        [8,5,9,7,6,1,4,2,3],
        [4,2,6,8,5,3,7,9,1],
        [7,1,3,9,2,4,8,5,6],
        [9,6,1,5,3,7,2,8,4],
        [2,8,7,4,1,9,6,3,5],
        [3,4,5,2,8,6,1,7,9],
      ];
      expect(findHiddenSingle(board), isNull);
    });

    test('finds a hidden single in a row', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0] = [0, 0, 3, 4, 5, 6, 7, 8, 9];
      board[1][0] = 2;
      board[1] = [2, 1, 4, 3, 6, 5, 8, 7, 0];

      final result = findHiddenSingle(board);
      expect(result, isNotNull);
      expect(result!.digit, 2);
      expect(result.row, 0);
      expect(result.col, 1);
      expect(result.unitCells.length, 9);
    });

    test('result unitCells always contains exactly 9 cells', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0] = [0, 0, 3, 4, 5, 6, 7, 8, 9];
      board[1][0] = 2;
      board[1] = [2, 1, 4, 3, 6, 5, 8, 7, 0];
      final result = findHiddenSingle(board);
      expect(result?.unitCells.length, 9);
    });

    test('eliminatorCells are non-empty when other candidates are blocked', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0] = [0, 0, 3, 4, 5, 6, 7, 8, 9];
      board[1][0] = 2;
      board[1] = [2, 1, 4, 3, 6, 5, 8, 7, 0];
      final result = findHiddenSingle(board);
      expect(result?.eliminatorCells, isNotEmpty);
    });
  });
}
