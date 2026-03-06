/// Manages the currently selected cell in the Sudoku board.
class SelectionModel {
  int _row = -1;
  int _col = -1;

  int get row => _row;
  int get col => _col;
  bool get hasSelection => _row >= 0 && _col >= 0;

  void select(int row, int col) {
    _row = row;
    _col = col;
  }

  void clear() {
    _row = -1;
    _col = -1;
  }
}
