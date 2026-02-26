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

    test('returns null when no hidden singles exist', () {
      // Board with empty cells but no hidden singles (every empty cell has
      // multiple candidates in every unit it belongs to).
      final board = List.generate(9, (_) => List.filled(9, 0));
      // Fill a nearly-empty board: only two givens so every digit has many
      // candidate cells in every unit — no hidden single is forced.
      board[0][0] = 1;
      board[4][4] = 5;
      expect(findHiddenSingle(board), isNull);
    });

    test('finds a hidden single in a row', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      // Row 0: missing only digit 2 at col 1; col 1 and box 0 are saturated
      // for digit 2 everywhere else in row 0 by the digits in row 1.
      board[0] = [0, 0, 3, 4, 5, 6, 7, 8, 9];
      board[1] = [2, 1, 4, 3, 6, 5, 8, 7, 0];

      final result = findHiddenSingle(board);
      expect(result, isNotNull);
      expect(result!.digit, 2);
      expect(result.row, 0);
      expect(result.col, 1);
      expect(result.unitCells.length, 9);
    });

    test('eliminatorCells are non-empty when other candidates are blocked', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0] = [0, 0, 3, 4, 5, 6, 7, 8, 9];
      board[1] = [2, 1, 4, 3, 6, 5, 8, 7, 0];
      final result = findHiddenSingle(board);
      expect(result?.eliminatorCells, isNotEmpty);
    });

    test('finds a hidden single in a column', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      // Column 0 contains 1-8 in rows 1-8; only row 0 is empty.
      // Digit 9 appears nowhere in column 0, and is blocked everywhere else
      // in column 0 except row 0 by box/row constraints seeded below.
      // Simpler: col 0 has digits 1..8 placed, so the missing digit 9 must
      // go in row 0 — a naked single in the column, which also qualifies as
      // a hidden single (only one candidate position in the column).
      for (int r = 1; r <= 8; r++) {
        board[r][0] = r; // col 0: rows 1-8 have digits 1-8
      }
      // row 0, col 0 is the only empty cell in col 0; digit 9 is the only
      // missing digit in col 0 and is legal there.
      final result = findHiddenSingle(board);
      expect(result, isNotNull);
      expect(result!.digit, 9);
      expect(result.row, 0);
      expect(result.col, 0);
    });

    test('finds a hidden single in a box', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      // Top-left box (rows 0-2, cols 0-2): fill 8 of the 9 cells, leaving
      // only (0,0) empty. The missing digit in the box can only go there.
      board[0] = [0, 2, 3, 0, 0, 0, 0, 0, 0];
      board[1] = [4, 5, 6, 0, 0, 0, 0, 0, 0];
      board[2] = [7, 8, 9, 0, 0, 0, 0, 0, 0];
      // Digit 1 is missing from the box; no other row/col/box constraints
      // block (0,0) for digit 1.
      final result = findHiddenSingle(board);
      // The scanner finds row hidden singles first; if none, then column,
      // then box. In this board the box single at (0,0)=1 is also a row
      // single (row 0 only has one empty cell for digit 1), so the result
      // is found as a row single — still valid.
      expect(result, isNotNull);
      expect(result!.digit, 1);
      expect(result.row, 0);
      expect(result.col, 0);
    });

    test('eliminatorCells is empty when target is the only empty cell in unit', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      // Row 0 has exactly one empty cell at col 0; all other cols filled.
      board[0] = [0, 2, 3, 4, 5, 6, 7, 8, 9];
      final result = findHiddenSingle(board);
      expect(result, isNotNull);
      expect(result!.digit, 1);
      expect(result.row, 0);
      expect(result.col, 0);
      // No other empty cells in the unit means no eliminators.
      expect(result.eliminatorCells, isEmpty);
    });
  });
}
