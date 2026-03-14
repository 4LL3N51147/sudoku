import 'strategy/strategy.dart';
import 'strategy/strategy_types.dart';

// Re-export for backwards compatibility
export 'strategy/strategy.dart' show StrategyType, StrategyResult, Strategy, StrategyHighlight;
export 'strategy/strategy_types.dart' show StrategyPhase, UnitType, HintStep;

bool _isLegal(List<List<int>> board, int row, int col, int digit) {
  for (int c = 0; c < 9; c++) {
    if (board[row][c] == digit) return false;
  }
  for (int r = 0; r < 9; r++) {
    if (board[r][col] == digit) return false;
  }
  final br = (row ~/ 3) * 3;
  final bc = (col ~/ 3) * 3;
  for (int r = br; r < br + 3; r++) {
    for (int c = bc; c < bc + 3; c++) {
      if (board[r][c] == digit) return false;
    }
  }
  return true;
}

/// Computes all candidates for each empty cell on the board.
Map<(int, int), Set<int>> computeCandidates(List<List<int>> board) {
  final candidates = <(int, int), Set<int>>{};
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      if (board[r][c] == 0) {
        final cellCandidates = <int>{};
        for (int d = 1; d <= 9; d++) {
          if (_isLegal(board, r, c, d)) {
            cellCandidates.add(d);
          }
        }
        candidates[(r, c)] = cellCandidates;
      }
    }
  }
  return candidates;
}

class StrategySolver {
  final List<List<int>> board;
  final Map<(int, int), Set<int>> candidates;

  /// Create a solver. If candidates are provided, use them instead of computing fresh.
  /// This preserves manual eliminations from hints.
  StrategySolver(this.board, [Map<(int, int), Set<int>>? existingCandidates])
      : candidates = existingCandidates ?? computeCandidates(board);


  StrategyResult? findHiddenSingle() {
    return StrategyRegistry.getStrategy(StrategyType.hiddenSingle)
        ?.find(board, candidates);
  }

  /// Find naked pairs in the board
  StrategyResult? findNakedPair() {
    return StrategyRegistry.getStrategy(StrategyType.nakedPair)
        ?.find(board, candidates);
  }

  /// Find naked triples in the board
  StrategyResult? findNakedTriple() {
    return StrategyRegistry.getStrategy(StrategyType.nakedTriple)
        ?.find(board, candidates);
  }

  /// Find hidden pairs in the board
  StrategyResult? findHiddenPair() {
    return StrategyRegistry.getStrategy(StrategyType.hiddenPair)
        ?.find(board, candidates);
  }

  /// Find hidden triples in the board
  StrategyResult? findHiddenTriple() {
    return StrategyRegistry.getStrategy(StrategyType.hiddenTriple)
        ?.find(board, candidates);
  }

  /// Find naked quads in the board
  StrategyResult? findNakedQuad() {
    return StrategyRegistry.getStrategy(StrategyType.nakedQuad)
        ?.find(board, candidates);
  }

  /// Find hidden quads in the board
  StrategyResult? findHiddenQuad() {
    return StrategyRegistry.getStrategy(StrategyType.hiddenQuad)
        ?.find(board, candidates);
  }
}
