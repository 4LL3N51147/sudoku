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
  final Map<(int, int), Set<int>>? candidates;

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
    this.candidates,
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
        child: Center(
          child: value == 0
              ? _buildCandidates(row, col)
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
      ),
    );
  }

  Widget? _buildCandidates(int row, int col) {
    final cellCandidates = candidates?[(row, col)];
    if (cellCandidates == null || cellCandidates.isEmpty) {
      return null;
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(9, (index) {
        final digit = index + 1;
        final hasCandidate = cellCandidates.contains(digit);
        final isEliminated = _isEliminated(row, col, digit);

        return Center(
          child: isEliminated
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$digit',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 1,
                      color: Colors.red.shade400,
                    ),
                  ],
                )
              : Text(
                  '$digit',
                  style: TextStyle(
                    fontSize: 9,
                    color: hasCandidate ? Colors.blue.shade700 : Colors.transparent,
                  ),
                ),
        );
      }),
    );
  }

  bool _isEliminated(int row, int col, int digit) {
    final sh = strategyHighlight;
    if (sh == null) return false;

    // Use eliminationCandidates if available (new approach with specific digit info)
    if (sh.eliminationCandidates.isNotEmpty) {
      return sh.eliminationCandidates[(row, col)]?.contains(digit) ?? false;
    }

    // Fallback: check if this cell is in elimination phase and should have strikethrough
    if (sh.phase != StrategyPhase.elimination) {
      return false;
    }

    // Check if this digit is eliminated in this cell based on patternDigits
    final unitCells = sh.unitCells;
    final eliminatorCells = sh.eliminatorCells;
    final patternDigits = sh.patternDigits;

    // If this cell is in the elimination unit and is not itself an eliminator
    // and not the pattern cells
    if (!unitCells.contains((row, col)) ||
        eliminatorCells.contains((row, col)) ||
        sh.patternCells.contains((row, col))) {
      return false;
    }

    // Check if any eliminator cell has this digit as a candidate
    final cellCandidates = candidates?[(row, col)];
    if (cellCandidates == null) return false;

    // If this digit is in patternDigits and exists in eliminator cells, it's eliminated
    if (patternDigits.contains(digit)) {
      for (final ec in eliminatorCells) {
        final ecCandidates = candidates?[ec];
        if (ecCandidates?.contains(digit) ?? false) {
          return true;
        }
      }
    }

    return false;
  }
}
