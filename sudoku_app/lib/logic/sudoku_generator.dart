import 'dart:math';

enum Difficulty { easy, medium, hard }

class GeneratorResult {
  final List<List<int>> puzzle;
  final List<List<int>> solution;

  GeneratorResult(this.puzzle, this.solution);
}

class SudokuGenerator {
  static final Random _random = Random();

  static GeneratorResult generate(Difficulty difficulty) {
    final solution = _generateSolvedBoard();
    final puzzle = _createPuzzle(solution, _cellsToRemove(difficulty));
    return GeneratorResult(puzzle, solution);
  }

  static int _cellsToRemove(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 35; // 46 given
      case Difficulty.medium:
        return 46; // 35 given
      case Difficulty.hard:
        return 52; // 29 given
    }
  }

  static List<List<int>> _generateSolvedBoard() {
    final board = List.generate(9, (_) => List.filled(9, 0));
    _fillBoard(board);
    return board;
  }

  static bool _fillBoard(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          final nums = List.generate(9, (i) => i + 1)..shuffle(_random);
          for (final num in nums) {
            if (_isValid(board, row, col, num)) {
              board[row][col] = num;
              if (_fillBoard(board)) return true;
              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  static bool _isValid(List<List<int>> board, int row, int col, int num) {
    for (int c = 0; c < 9; c++) {
      if (board[row][c] == num) return false;
    }
    for (int r = 0; r < 9; r++) {
      if (board[r][col] == num) return false;
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if (board[r][c] == num) return false;
      }
    }
    return true;
  }

  static List<List<int>> _createPuzzle(
      List<List<int>> solution, int toRemove) {
    final puzzle = solution.map((row) => List<int>.from(row)).toList();
    final cells = List.generate(81, (i) => [i ~/ 9, i % 9])..shuffle(_random);
    int removed = 0;
    for (final cell in cells) {
      if (removed >= toRemove) break;
      puzzle[cell[0]][cell[1]] = 0;
      removed++;
    }
    return puzzle;
  }
}
