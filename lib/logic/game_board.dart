typedef _Move = ({int row, int col, int oldValue, int newValue});

/// Manages the Sudoku board state, validation, and operations.
class GameBoard {
  final List<List<int>> solution;
  final List<List<bool>> _isGiven;
  final List<List<int>> _board;
  final List<List<bool>> _isError;
  final List<_Move> _undoStack = [];

  GameBoard({
    required List<List<int>> puzzle,
    required this.solution,
  })  : _isGiven = List.generate(
            9, (r) => List.generate(9, (c) => puzzle[r][c] != 0)),
        _board = puzzle.map((row) => List<int>.from(row)).toList(),
        _isError = List.generate(9, (_) => List.filled(9, false));

  List<List<int>> get board => _board;
  List<List<bool>> get isGivenBoard => _isGiven;
  List<List<bool>> get isErrorBoard => _isError;
  List<_Move> get undoStack => List.unmodifiable(_undoStack);

  int getCell(int row, int col) => _board[row][col];
  bool isGivenCell(int row, int col) => _isGiven[row][col];
  bool isErrorCell(int row, int col) => _isError[row][col];

  void setCell(int row, int col, int digit, {bool markAsGiven = true}) {
    // Add to undo stack
    _undoStack.add((
      row: row,
      col: col,
      oldValue: _board[row][col],
      newValue: digit,
    ));

    _board[row][col] = digit;
    if (markAsGiven) {
      _isGiven[row][col] = true; // Mark cell as given after user input
    }
    updateErrors();
  }

  void eraseCell(int row, int col) {
    setCell(row, col, 0, markAsGiven: false);
  }

  bool isValidMove(int row, int col, int digit) {
    // Check row
    for (var c = 0; c < 9; c++) {
      if (c != col && _board[row][c] == digit) return false;
    }

    // Check column
    for (var r = 0; r < 9; r++) {
      if (r != row && _board[r][col] == digit) return false;
    }

    // Check 3x3 box
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        if (r != row && c != col && _board[r][c] == digit) return false;
      }
    }

    return true;
  }

  void updateErrors() {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (_board[r][c] != 0 && _board[r][c] != solution[r][c]) {
          _isError[r][c] = true;
        } else {
          _isError[r][c] = false;
        }
      }
    }
  }

  bool checkWin() {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (_board[r][c] != solution[r][c]) return false;
      }
    }
    return true;
  }

  void undo() {
    if (_undoStack.isEmpty) return;

    final move = _undoStack.removeLast();
    _board[move.row][move.col] = move.oldValue;
    _isGiven[move.row][move.col] = move.oldValue != 0;
    updateErrors();
  }

  bool get canUndo => _undoStack.isNotEmpty;
}
