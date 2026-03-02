# Sudoku Strategy Solver - Unified Design

**Date:** 2026-03-02

## Overview

Refactor the existing `strategy_solver.dart` from standalone functions into a unified `StrategySolver` class that supports multiple solving strategies: hidden singles, naked/hidden pairs, triples, and quads.

## Data Structures

### StrategyType Enum
```dart
enum StrategyType {
  hiddenSingle,
  nakedPair, hiddenPair,
  nakedTriple, hiddenTriple,
  nakedQuad, hiddenQuad,
}
```

### StrategyResult Class
```dart
class StrategyResult {
  final StrategyType type;
  final StrategyPhase phase;
  final UnitType? unitType;
  final Set<(int, int)> unitCells;        // The row/col/box being analyzed
  final Set<(int, int)> patternCells;     // Cells forming the pattern (pair/triple/quad)
  final Set<int> patternDigits;          // Digits involved in the pattern
  final Set<(int, int)> eliminationCells; // Cells where candidates are removed
  final (int, int)? targetCell;           // The cell to fill in (for hidden singles)
}
```

## Architecture

### StrategySolver Class
- Single `findNextStrategy(board)` method returns first applicable strategy
- Scans in order: hidden singles → pairs → triples → quads
- Each strategy scans: rows → columns → boxes
- Uses pre-computed candidate map for efficiency

### Candidate Computation
- `Map<(int,int), Set<int>> computeCandidates(board)` - compute all candidates once
- Reused across all strategies to avoid redundant legal placement checks

## Strategy Definitions

### Hidden Single
- A digit that can only go in one cell within a row/column/box
- Already implemented, refactor to new structure

### Naked Pair
- Two cells in same unit containing exactly the same 2 candidates
- Those two candidates can be eliminated from all other cells in that unit

### Hidden Pair
- Two digits that appear as candidates in exactly two cells within a unit
- Those two digits can be eliminated from all other cells in that unit

### Naked Triple
- Three cells in same unit containing exactly 3 combined candidates (each cell has subset)
- All candidates from the triple can be eliminated from other cells in unit

### Hidden Triple
- Three digits that appear as candidates in exactly three cells within a unit
- Those three digits can be eliminated from all other cells in that unit

### Naked Quad
- Four cells in same unit containing exactly 4 combined candidates
- All four candidates eliminated from other cells in unit

### Hidden Quad
- Four digits that appear as candidates in exactly four cells within a unit
- Those four digits eliminated from other cells in unit

## Implementation Order

1. Refactor Hidden Single to new structure
2. Add candidate computation helper
3. Implement Naked Pair
4. Implement Hidden Pair
5. Implement Naked Triple
6. Implement Hidden Triple
7. Implement Naked Quad
8. Implement Hidden Quad
