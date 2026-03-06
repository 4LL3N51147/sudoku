import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/logic/game_board.dart';
import 'package:sudoku/logic/sudoku_generator.dart';

void main() {
  group('GameBoard', () {
    late GameBoard board;

    setUp(() {
      final result = SudokuGenerator.generate(Difficulty.easy);
      board = GameBoard(
        puzzle: result.puzzle,
        solution: result.solution,
      );
    });

    test('initializes with puzzle values', () {
      // Some cells should have values (given cells)
      int givenCount = 0;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board.getCell(r, c) != 0) givenCount++;
        }
      }
      expect(givenCount, greaterThan(0));
    });

    test('gets cell value', () {
      expect(board.getCell(0, 0), isNotNull);
      expect(board.getCell(0, 0), inInclusiveRange(0, 9));
    });

    test('sets cell value', () {
      // Find an empty cell
      int emptyRow = -1, emptyCol = -1;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board.getCell(r, c) == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
        if (emptyRow >= 0) break;
      }

      if (emptyRow >= 0) {
        board.setCell(emptyRow, emptyCol, 5);
        expect(board.getCell(emptyRow, emptyCol), 5);
      }
    });

    test('tracks given cells', () {
      // Find a given cell
      int givenRow = -1, givenCol = -1;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board.isGivenCell(r, c)) {
            givenRow = r;
            givenCol = c;
            break;
          }
        }
        if (givenRow >= 0) break;
      }

      if (givenRow >= 0) {
        expect(board.isGivenCell(givenRow, givenCol), true);
      }
    });

    test('can check if move is valid', () {
      // The solution should be valid
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          final solutionValue = board.solution[r][c];
          expect(board.isValidMove(r, c, solutionValue), true);
        }
      }
    });

    test('detects errors after invalid move', () {
      // Set a cell to an incorrect value
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isGivenCell(r, c)) {
            // Find a value that's NOT the solution
            final wrongValue = board.solution[r][c] == 1 ? 2 : 1;
            board.setCell(r, c, wrongValue);
            board.updateErrors();

            expect(board.isErrorCell(r, c), true);
            return;
          }
        }
      }
    });

    test('detects win condition', () {
      // Fill board with solution
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          board.setCell(r, c, board.solution[r][c]);
        }
      }

      expect(board.checkWin(), true);
    });

    test('undo stack works', () {
      // Find empty cell and set value
      int emptyRow = -1, emptyCol = -1, emptyValue = 0;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board.getCell(r, c) == 0) {
            emptyRow = r;
            emptyCol = c;
            emptyValue = board.solution[r][c];
            break;
          }
        }
        if (emptyRow >= 0) break;
      }

      if (emptyRow >= 0) {
        board.setCell(emptyRow, emptyCol, emptyValue);
        expect(board.undoStack.length, 1);

        board.undo();
        expect(board.getCell(emptyRow, emptyCol), 0);
        expect(board.undoStack.length, 0);
      }
    });

    test('undo stack getter returns unmodifiable list', () {
      // Find empty cell and set value
      int emptyRow = -1, emptyCol = -1;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board.getCell(r, c) == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
        if (emptyRow >= 0) break;
      }

      if (emptyRow >= 0) {
        board.setCell(emptyRow, emptyCol, 5);
        // The getter should return an unmodifiable view
        expect(() => board.undoStack.add((row: 0, col: 0, oldValue: 0, newValue: 1)),
            throwsA(isA<UnsupportedError>()));
      }
    });
  });
}
