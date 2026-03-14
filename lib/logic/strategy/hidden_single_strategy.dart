import 'package:sudoku/logic/strategy_solver.dart' hide StrategyResult, StrategyType;
import 'package:sudoku/logic/strategy/strategy.dart';

class HiddenSingleStrategy extends Strategy {
  @override
  StrategyType get type => StrategyType.hiddenSingle;

  @override
  StrategyResult? find(List<List<int>> board, Map<(int, int), Set<int>> candidates) {
    // Check rows
    for (int r = 0; r < 9; r++) {
      final cells = {for (int c = 0; c < 9; c++) (r, c)};
      final result = _checkUnitForHiddenSingle(cells, UnitType.row, board, candidates);
      if (result != null) return result;
    }
    // Check columns
    for (int c = 0; c < 9; c++) {
      final cells = {for (int r = 0; r < 9; r++) (r, c)};
      final result = _checkUnitForHiddenSingle(cells, UnitType.column, board, candidates);
      if (result != null) return result;
    }
    // Check boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final cells = {
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final result = _checkUnitForHiddenSingle(cells, UnitType.box, board, candidates);
        if (result != null) return result;
      }
    }
    return null;
  }

  StrategyResult? _checkUnitForHiddenSingle(
      Set<(int, int)> unitCells, UnitType unitType,
      List<List<int>> board, Map<(int, int), Set<int>> candidates) {
    final presentDigits = {
      for (final (r, c) in unitCells)
        if (board[r][c] != 0) board[r][c],
    };

    for (int digit = 1; digit <= 9; digit++) {
      if (presentDigits.contains(digit)) continue;

      final cellsWithDigit = unitCells
          .where((rc) => candidates[rc]?.contains(digit) ?? false)
          .toList();

      if (cellsWithDigit.length == 1) {
        final (tr, tc) = cellsWithDigit.first;
        final eliminators = <(int, int)>{};
        final eliminationRows = <int>{};
        final eliminationCols = <int>{};
        final eliminationBoxes = <int>{};

        // For each empty cell in the unit (not the target), find which specific constraint eliminates it
        // The elimination zone is the specific column, row, or box that contains the digit and blocks this cell
        for (final (r, c) in unitCells) {
          if ((r, c) == (tr, tc)) continue;
          if (board[r][c] != 0) continue;

          // Add blockers (cells with the digit that block this cell)
          eliminators.addAll(_findBlockers(r, c, digit, board));

          // Compute elimination zones per empty cell - which specific constraint eliminates this cell
          // Priority: box > row > column (boxes take priority when there's intersection)
          if (unitType == UnitType.row) {
            // For row hidden single: boxes take priority over columns
            // First check if the box containing this cell (r, c) has the digit elsewhere
            final cellBox = (r ~/ 3) * 3 + (c ~/ 3);
            bool boxHasDigit = false;
            for (int rr = (cellBox ~/ 3) * 3; rr < (cellBox ~/ 3) * 3 + 3; rr++) {
              for (int cc = (cellBox % 3) * 3; cc < (cellBox % 3) * 3 + 3; cc++) {
                if ((rr, cc) != (r, c) && board[rr][cc] == digit) {
                  eliminationBoxes.add(cellBox);
                  boxHasDigit = true;
                  break;
                }
              }
              if (boxHasDigit) break;
            }
            // Only check column if box doesn't have the digit (boxes take priority)
            if (!boxHasDigit) {
              for (int rr = 0; rr < 9; rr++) {
                if (rr != tr && board[rr][c] == digit) {
                  eliminationCols.add(c);
                  break;
                }
              }
            }
          } else if (unitType == UnitType.column) {
            // For column hidden single: boxes take priority over rows
            // First check if the box containing this cell (r, c) has the digit elsewhere
            final cellBox = (r ~/ 3) * 3 + (c ~/ 3);
            bool boxHasDigit = false;
            for (int rr = (cellBox ~/ 3) * 3; rr < (cellBox ~/ 3) * 3 + 3; rr++) {
              for (int cc = (cellBox % 3) * 3; cc < (cellBox % 3) * 3 + 3; cc++) {
                if ((rr, cc) != (r, c) && board[rr][cc] == digit) {
                  eliminationBoxes.add(cellBox);
                  boxHasDigit = true;
                  break;
                }
              }
              if (boxHasDigit) break;
            }
            // Only check row if box doesn't have the digit (boxes take priority)
            if (!boxHasDigit) {
              for (int cc = 0; cc < 9; cc++) {
                if (cc != tc && board[r][cc] == digit) {
                  eliminationRows.add(r);
                  break;
                }
              }
            }
          } else if (unitType == UnitType.box) {
            // For box hidden single: rows take priority over columns
            // First check if row r has the digit elsewhere
            bool rowHasDigit = false;
            for (int cc = 0; cc < 9; cc++) {
              if (board[r][cc] == digit && cc != c) {
                eliminationRows.add(r);
                rowHasDigit = true;
                break;
              }
            }
            // Only check column if row doesn't have the digit (rows take priority)
            if (!rowHasDigit) {
              for (int rr = 0; rr < 9; rr++) {
                if (board[rr][c] == digit && rr != r) {
                  eliminationCols.add(c);
                  break;
                }
              }
            }
          }
        }

        final unitLabel = switch (unitType) {
          UnitType.row => 'row',
          UnitType.column => 'column',
          UnitType.box => 'box',
        };

        // Compute eliminator cells - cells that contain the digit and block positions
        // For row hidden single: cells in THIS ROW with the digit
        // For column hidden single: cells in THIS COLUMN with the digit
        // For box hidden single: cells in THIS BOX with the digit
        final eliminatorCells = <(int, int)>{};

        if (unitType == UnitType.row) {
          for (int cc = 0; cc < 9; cc++) {
            if (cc != tc && board[tr][cc] == digit) {
              eliminatorCells.add((tr, cc));
            }
          }
        } else if (unitType == UnitType.column) {
          for (int rr = 0; rr < 9; rr++) {
            if (rr != tr && board[rr][tc] == digit) {
              eliminatorCells.add((rr, tc));
            }
          }
        } else if (unitType == UnitType.box) {
          final targetBox = (tr ~/ 3) * 3 + (tc ~/ 3);
          for (int rr = (targetBox ~/ 3) * 3; rr < (targetBox ~/ 3) * 3 + 3; rr++) {
            for (int cc = (targetBox % 3) * 3; cc < (targetBox % 3) * 3 + 3; cc++) {
              if ((rr, cc) != (tr, tc) && board[rr][cc] == digit) {
                eliminatorCells.add((rr, cc));
              }
            }
          }
        }

        // Hidden single: Scan -> Elimination -> Target
        final steps = [
          HintStep(
            phase: StrategyPhase.scan,
            message: 'Scanning this $unitLabel — looking for $digit',
            unitCells: unitCells,
            patternDigits: {digit},
            unitType: unitType,
          ),
          HintStep(
            phase: StrategyPhase.elimination,
            message: '$digit can only go in 1 cell in this $unitLabel!',
            unitCells: unitCells,
            patternCells: {(tr, tc)},
            patternDigits: {digit},
            targetCell: (tr, tc),
            unitType: unitType,
            eliminatorCells: eliminators,
            eliminationRows: eliminationRows,
            eliminationCols: eliminationCols,
            eliminationBoxes: eliminationBoxes,
          ),
          HintStep(
            phase: StrategyPhase.target,
            message: 'Now you can place $digit in this cell!',
            unitCells: unitCells,
            patternCells: {(tr, tc)},
            patternDigits: {digit},
            targetCell: (tr, tc),
            unitType: unitType,
          ),
        ];

        return StrategyResult(
          type: StrategyType.hiddenSingle,
          phase: StrategyPhase.target,
          unitType: unitType,
          unitCells: unitCells,
          patternCells: {(tr, tc)},
          patternDigits: {digit},
          eliminationCells: eliminators,
          targetCell: (tr, tc),
          eliminationRows: eliminationRows,
          eliminationCols: eliminationCols,
          eliminationBoxes: eliminationBoxes,
          hintSteps: steps,
        );
      }
    }
    return null;
  }

  Set<(int, int)> _findBlockers(int row, int col, int digit, List<List<int>> board) {
    // Priority: box > row > column - each cell should have only one blocker
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        if (board[r][c] == digit) return {(r, c)};
      }
    }
    for (int c = 0; c < 9; c++) {
      if (c != col && board[row][c] == digit) return {(row, c)};
    }
    for (int r = 0; r < 9; r++) {
      if (r != row && board[r][col] == digit) return {(r, col)};
    }
    return {};
  }
}
