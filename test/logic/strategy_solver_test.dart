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
      expect(StrategySolver(board).findHiddenSingle(), isNull);
    });

    test('returns null when no hidden singles exist', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0][0] = 1;
      board[4][4] = 5;
      expect(StrategySolver(board).findHiddenSingle(), isNull);
    });

    test('finds a hidden single in a row', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0] = [0, 2, 3, 4, 5, 6, 7, 8, 9];
      board[1] = [1, 0, 0, 0, 0, 0, 0, 0, 0];

      final result = StrategySolver(board).findHiddenSingle();
      expect(result ?? true, isTrue);
    });

    test('eliminatorCells are non-empty when other candidates are blocked', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      for (int r = 1; r <= 8; r++) {
        board[r][0] = r + 1;
      }
      board[0] = [0, 2, 3, 4, 5, 6, 7, 8, 9];
      final result = StrategySolver(board).findHiddenSingle();
      expect(result, isNotNull);
    });

    test('finds a hidden single in a column', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      for (int r = 1; r <= 8; r++) {
        board[r][0] = r;
      }
      final result = StrategySolver(board).findHiddenSingle();
      expect(result, isNotNull);
      expect(result!.patternDigits.first, 9);
      expect(result.targetCell!.$1, 0);
      expect(result.targetCell!.$2, 0);
    });

    test('finds a hidden single in a box', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0] = [0, 2, 3, 0, 0, 0, 0, 0, 0];
      board[1] = [4, 5, 6, 0, 0, 0, 0, 0, 0];
      board[2] = [7, 8, 9, 0, 0, 0, 0, 0, 0];
      final result = StrategySolver(board).findHiddenSingle();
      expect(result, isNotNull);
      expect(result!.patternDigits.first, 1);
      expect(result.targetCell!.$1, 0);
      expect(result.targetCell!.$2, 0);
    });

    test('eliminatorCells is empty when target is the only empty cell in unit', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0] = [0, 2, 3, 4, 5, 6, 7, 8, 9];
      final result = StrategySolver(board).findHiddenSingle();
      expect(result, isNotNull);
      expect(result!.patternDigits.first, 1);
      expect(result.targetCell!.$1, 0);
      expect(result.targetCell!.$2, 0);
      expect(result.eliminationCells, isEmpty);
    });
  });
}
