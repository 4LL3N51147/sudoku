import 'package:flutter/material.dart';
import '../logic/strategy_solver.dart';

class SudokuBoard extends StatelessWidget {
  final List<List<int>> board;
  final List<List<bool>> isGiven;
  final List<List<bool>> isError;
  final int selectedRow;
  final int selectedCol;
  final bool isPaused;
  final void Function(int row, int col) onCellTap;
  final StrategyHighlight? strategyHighlight;
  final List<List<Set<int>>> pencilMarks;

  const SudokuBoard({
    super.key,
    required this.board,
    required this.isGiven,
    required this.isError,
    required this.selectedRow,
    required this.selectedCol,
    required this.isPaused,
    required this.onCellTap,
    this.strategyHighlight,
    this.pencilMarks = const [],
  });

  bool _isHighlighted(int row, int col) {
    if (selectedRow < 0) return false;
    return row == selectedRow ||
        col == selectedCol ||
        (row ~/ 3 == selectedRow ~/ 3 && col ~/ 3 == selectedCol ~/ 3);
  }

  bool _isSameNumber(int row, int col) {
    if (selectedRow < 0) return false;
    final num = board[selectedRow][selectedCol];
    return num != 0 &&
        board[row][col] == num &&
        !(row == selectedRow && col == selectedCol);
  }

  bool _isSelected(int row, int col) =>
      row == selectedRow && col == selectedCol;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF1A237E), width: 3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: isPaused
            ? const Center(
                child: Text(
                  'PAUSED',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                    letterSpacing: 6,
                  ),
                ),
              )
            : Column(
                children: List.generate(3, (blockRow) {
                  return Expanded(
                    child: Row(
                      children: List.generate(3, (blockCol) {
                        return Expanded(
                          child: _buildBlock(blockRow, blockCol),
                        );
                      }),
                    ),
                  );
                }),
              ),
      ),
    );
  }

  Widget _buildBlock(int blockRow, int blockCol) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: blockCol < 2
              ? const BorderSide(color: Color(0xFF1A237E), width: 2)
              : BorderSide.none,
          bottom: blockRow < 2
              ? const BorderSide(color: Color(0xFF1A237E), width: 2)
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: List.generate(3, (localRow) {
          return Expanded(
            child: Row(
              children: List.generate(3, (localCol) {
                final row = blockRow * 3 + localRow;
                final col = blockCol * 3 + localCol;
                return Expanded(
                  child: _buildCell(row, col, localRow, localCol),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCell(int row, int col, int localRow, int localCol) {
    final selected = _isSelected(row, col);
    final highlighted = _isHighlighted(row, col);
    final sameNum = _isSameNumber(row, col);
    final error = isError[row][col];
    final value = board[row][col];
    final given = isGiven[row][col];

    Color bgColor;
    final sh = strategyHighlight;
    if (sh != null) {
      final cell = (row, col);
      if (sh.phase == StrategyPhase.target && sh.targetCell == cell) {
        bgColor = const Color(0xFFC8E6C9); // green-100 — place digit here
      } else if (sh.phase == StrategyPhase.elimination &&
          sh.eliminatorCells.contains(cell)) {
        bgColor = const Color(0xFFFFE0B2); // amber-100 — blocks other cells
      } else if (sh.unitCells.contains(cell)) {
        bgColor = const Color(0xFFE3F2FD); // blue-50 — scanning this unit
      } else {
        bgColor = Colors.white;
      }
    } else if (selected) {
      bgColor = const Color(0xFF90CAF9); // blue-200
    } else if (sameNum) {
      bgColor = const Color(0xFFBBDEFB); // blue-100
    } else if (highlighted) {
      bgColor = const Color(0xFFE8EAF6); // indigo-50
    } else {
      bgColor = Colors.white;
    }

    Color textColor;
    if (error) {
      textColor = const Color(0xFFC62828);
    } else if (given) {
      textColor = const Color(0xFF1A237E);
    } else {
      textColor = const Color(0xFF1565C0);
    }

    return GestureDetector(
      onTap: () => onCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            right: localCol < 2
                ? const BorderSide(color: Color(0xFFBDBDBD), width: 0.5)
                : BorderSide.none,
            bottom: localRow < 2
                ? const BorderSide(color: Color(0xFFBDBDBD), width: 0.5)
                : BorderSide.none,
          ),
        ),
        child: Stack(
          children: [
            // Main number or empty
            Center(
              child: value == 0
                  ? null
                  : Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            given ? FontWeight.bold : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
            ),
            // Pencil marks (show in top-left corner when cell is empty)
            if (value == 0 && pencilMarks.isNotEmpty && pencilMarks[row][col].isNotEmpty)
              Positioned(
                top: 1,
                left: 2,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Wrap(
                    spacing: 0,
                    runSpacing: 0,
                    children: [
                      for (int i = 1; i <= 9; i++)
                        SizedBox(
                          width: 6,
                          height: 6,
                          child: Text(
                            '$i',
                            style: TextStyle(
                              fontSize: 6,
                              color: pencilMarks[row][col].contains(i)
                                  ? Colors.grey[600]
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
