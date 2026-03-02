# Strategy Solver Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Refactor strategy_solver.dart into a unified StrategySolver class supporting naked/hidden pairs, triples, and quads.

**Architecture:** Single StrategySolver class with findNextStrategy(board) method, pre-computed candidate map for efficiency.

**Tech Stack:** Dart 3.x, pure Dart (no Flutter imports).

---

### Task 1: Define StrategyType enum and refactor StrategyResult

**Files:**
- Modify: `lib/logic/strategy_solver.dart:1-40`

**Step 1: Add StrategyType enum and update StrategyResult**

Replace lines 1-37 with:

```dart
enum StrategyPhase { scan, elimination, target }

enum UnitType { row, column, box }

enum StrategyType {
  hiddenSingle,
  nakedPair,
  hiddenPair,
  nakedTriple,
  hiddenTriple,
  nakedQuad,
  hiddenQuad,
}

class StrategyResult {
  final StrategyType type;
  final StrategyPhase phase;
  final UnitType? unitType;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> patternCells;
  final Set<int> patternDigits;
  final Set<(int, int)> eliminationCells;
  final (int, int)? targetCell;

  const StrategyResult({
    required this.type,
    required this.phase,
    this.unitType,
    this.unitCells = const {},
    this.patternCells = const {},
    this.patternDigits = const {},
    this.eliminationCells = const {},
    this.targetCell,
  });
}
```

**Step 2: Commit**

```bash
git add lib/logic/strategy_solver.dart
git commit -m "refactor: add StrategyType enum and unified StrategyResult"
```

---

### Task 2: Add candidate computation helper

**Files:**
- Modify: `lib/logic/strategy_solver.dart:140-160`

**Step 1: Add computeCandidates function after line 140**

```dart
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
```

**Step 2: Commit**

```bash
git add lib/logic/strategy_solver.dart
git commit -m "feat: add computeCandidates helper function"
```

---

### Task 3: Create StrategySolver class with HiddenSingle

**Files:**
- Modify: `lib/logic/strategy_solver.dart`

**Step 1: Add StrategySolver class after computeCandidates**

```dart
class StrategySolver {
  final List<List<int>> board;
  final Map<(int, int), Set<int>> candidates;

  StrategySolver(this.board) : candidates = computeCandidates(board);

  StrategyResult? findNextStrategy() {
    // Try strategies in order: singles -> pairs -> triples -> quads
    final result = findHiddenSingle();
    if (result != null) return result;
    return null;
  }

  StrategyResult? findHiddenSingle() {
    // Rows
    for (int r = 0; r < 9; r++) {
      final cells = {for (int c = 0; c < 9; c++) (r, c)};
      final result = _checkUnitForHiddenSingle(cells, UnitType.row);
      if (result != null) return result;
    }
    // Columns
    for (int c = 0; c < 9; c++) {
      final cells = {for (int r = 0; r < 9; r++) (r, c)};
      final result = _checkUnitForHiddenSingle(cells, UnitType.column);
      if (result != null) return result;
    }
    // Boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final cells = {
          for (int r = br * 3; r < br * 3 + 3; r++)
            for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
        };
        final result = _checkUnitForHiddenSingle(cells, UnitType.box);
        if (result != null) return result;
      }
    }
    return null;
  }

  StrategyResult? _checkUnitForHiddenSingle(
      Set<(int, int)> unitCells, UnitType unitType) {
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
        for (final (r, c) in unitCells) {
          if ((r, c) == (tr, tc)) continue;
          if (board[r][c] != 0) continue;
          eliminators.addAll(_findBlockers(r, c, digit));
        }
        return StrategyResult(
          type: StrategyType.hiddenSingle,
          phase: StrategyPhase.target,
          unitType: unitType,
          unitCells: unitCells,
          patternCells: {(tr, tc)},
          patternDigits: {digit},
          eliminationCells: eliminators,
          targetCell: (tr, tc),
        );
      }
    }
    return null;
  }
}
```

**Step 2: Commit**

```bash
git add lib/logic/strategy_solver.dart
git commit -m "feat: add StrategySolver class with findNextStrategy"
```

---

### Task 4: Add backward-compatible findHiddenSingle function

**Files:**
- Modify: `lib/logic/strategy_solver.dart`

**Step 1: Add wrapper function**

After the StrategySolver class, add:

```dart
/// Returns the first hidden single found on the board, or null if none.
/// Maintains backward compatibility with existing tests.
HiddenSingleResult? findHiddenSingle(List<List<int>> board) {
  final solver = StrategySolver(board);
  final result = solver.findHiddenSingle();
  if (result == null) return null;

  return HiddenSingleResult(
    row: result.targetCell!.$1,
    col: result.targetCell!.$2,
    digit: result.patternDigits.first,
    unitCells: result.unitCells,
    eliminatorCells: result.eliminationCells,
    unitType: result.unitType!,
  );
}
```

**Step 2: Commit**

```bash
git add lib/logic/strategy_solver.dart
git commit -m "feat: add backward-compatible findHiddenSingle wrapper"
```

---

### Task 5: Add Naked Pair strategy

**Files:**
- Modify: `lib/logic/strategy_solver.dart`

**Step 1: Add findNakedPair method to StrategySolver class**

Add before `findHiddenSingle()` call in `findNextStrategy()`:

```dart
StrategyResult? findNakedPair() {
  // Check rows
  for (int r = 0; r < 9; r++) {
    final cells = {for (int c = 0; c < 9; c++) (r, c)};
    final result = _checkUnitForNakedPair(cells, UnitType.row);
    if (result != null) return result;
  }
  // Check columns
  for (int c = 0; c < 9; c++) {
    final cells = {for (int r = 0; r < 9; r++) (r, c)};
    final result = _checkUnitForNakedPair(cells, UnitType.column);
    if (result != null) return result;
  }
  // Check boxes
  for (int br = 0; br < 3; br++) {
    for (int bc = 0; bc < 3; bc++) {
      final cells = {
        for (int r = br * 3; r < br * 3 + 3; r++)
          for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
      };
      final result = _checkUnitForNakedPair(cells, UnitType.box);
      if (result != null) return result;
    }
  }
  return null;
}

StrategyResult? _checkUnitForNakedPair(
    Set<(int, int)> unitCells, UnitType unitType) {
  final emptyCells = unitCells
      .where((rc) => candidates[rc] != null && candidates[rc]!.length >= 2)
      .toList();

  // Find pairs: cells with exactly the same 2 candidates
  final seen = <Set<int>, List<(int, int)>>{};
  for (final cell in emptyCells) {
    final cellCandidates = candidates[cell]!;
    if (cellCandidates.length == 2) {
      seen.putIfAbsent(cellCandidates, () => []).add(cell);
    }
  }

  for (final entry in seen.entries) {
    if (entry.value.length >= 2) {
      final pairCells = entry.value.take(2).toSet();
      final pairDigits = entry.key;

      // Find elimination cells (other empty cells in unit that contain these digits)
      final eliminationCells = <(int, int)>{};
      for (final cell in emptyCells) {
        if (!pairCells.contains(cell)) {
          final cellCand = candidates[cell]!;
          for (final d in pairDigits) {
            if (cellCand.contains(d)) {
              eliminationCells.add(cell);
            }
          }
        }
      }

      if (eliminationCells.isNotEmpty) {
        return StrategyResult(
          type: StrategyType.nakedPair,
          phase: StrategyPhase.elimination,
          unitType: unitType,
          unitCells: unitCells,
          patternCells: pairCells,
          patternDigits: pairDigits,
          eliminationCells: eliminationCells,
        );
      }
    }
  }
  return null;
}
```

**Step 2: Update findNextStrategy to include nakedPair**

```dart
StrategyResult? findNextStrategy() {
  var result = findHiddenSingle();
  if (result != null) return result;
  result = findNakedPair();
  if (result != null) return result;
  return null;
}
```

**Step 3: Commit**

```bash
git add lib/logic/strategy_solver.dart
git commit -m "feat: add naked pair strategy"
```

---

### Task 6: Add Hidden Pair strategy

**Files:**
- Modify: `lib/logic/strategy_solver.dart`

**Step 1: Add findHiddenPair method to StrategySolver class**

After findNakedPair() in findNextStrategy(), add:

```dart
StrategyResult? findHiddenPair() {
  // Check rows
  for (int r = 0; r < 9; r++) {
    final cells = {for (int c = 0; c < 9; c++) (r, c)};
    final result = _checkUnitForHiddenPair(cells, UnitType.row);
    if (result != null) return result;
  }
  // Check columns
  for (int c = 0; c < 9; c++) {
    final cells = {for (int r = 0; r < 9; r++) (r, c)};
    final result = _checkUnitForHiddenPair(cells, UnitType.column);
    if (result != null) return result;
  }
  // Check boxes
  for (int br = 0; br < 3; br++) {
    for (int bc = 0; bc < 3; bc++) {
      final cells = {
        for (int r = br * 3; r < br * 3 + 3; r++)
          for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
      };
      final result = _checkUnitForHiddenPair(cells, UnitType.box);
      if (result != null) return result;
    }
  }
  return null;
}

StrategyResult? _checkUnitForHiddenPair(
    Set<(int, int)> unitCells, UnitType unitType) {
  final emptyCells = unitCells
      .where((rc) => candidates[rc] != null && candidates[rc]!.isNotEmpty)
      .toList();

  // Build digit -> cells mapping
  final digitToCells = <int, List<(int, int)>>{};
  for (final cell in emptyCells) {
    for (final d in candidates[cell]!) {
      digitToCells.putIfAbsent(d, () => []).add(cell);
    }
  }

  // Find digits that appear in exactly 2 cells
  final pairs = <(int, int), Set<(int, int)>>{};
  for (final entry in digitToCells.entries) {
    if (entry.value.length == 2) {
      final digitPair = (entry.key, entry.key); // placeholder
      pairs[entry.key] = entry.value.toSet();
    }
  }

  // Check all digit pairs
  final digits = digitToCells.keys.toList();
  for (int i = 0; i < digits.length; i++) {
    for (int j = i + 1; j < digits.length; j++) {
      final d1 = digits[i];
      final d2 = digits[j];
      final cells1 = digitToCells[d1]!;
      final cells2 = digitToCells[d2]!;

      // Both digits appear in exactly the same 2 cells
      if (cells1.length == 2 && cells2.length == 2) {
        final pairCells = cells1.toSet();
        if (pairCells.length == 2) {
          // Found hidden pair - eliminate other digits from these cells
          final eliminationCells = <(int, int)>{};
          for (final cell in emptyCells) {
            if (!pairCells.contains(cell)) {
              final cellCand = candidates[cell]!;
              if (cellCand.contains(d1) || cellCand.contains(d2)) {
                eliminationCells.add(cell);
              }
            }
          }

          if (eliminationCells.isNotEmpty) {
            return StrategyResult(
              type: StrategyType.hiddenPair,
              phase: StrategyPhase.elimination,
              unitType: unitType,
              unitCells: unitCells,
              patternCells: pairCells,
              patternDigits: {d1, d2},
              eliminationCells: eliminationCells,
            );
          }
        }
      }
    }
  }
  return null;
}
```

**Step 2: Update findNextStrategy**

```dart
StrategyResult? findNextStrategy() {
  var result = findHiddenSingle();
  if (result != null) return result;
  result = findNakedPair();
  if (result != null) return result;
  result = findHiddenPair();
  if (result != null) return result;
  return null;
}
```

**Step 3: Commit**

```bash
git add lib/logic/strategy_solver.dart
git commit -m "feat: add hidden pair strategy"
```

---

### Task 7: Add Naked Triple strategy

**Files:**
- Modify: `lib/logic/strategy_solver.dart`

**Step 1: Add findNakedTriple method**

Add to StrategySolver class before findNextStrategy return:

```dart
StrategyResult? findNakedTriple() {
  // Check rows
  for (int r = 0; r < 9; r++) {
    final cells = {for (int c = 0; c < 9; c++) (r, c)};
    final result = _checkUnitForNakedTriple(cells, UnitType.row);
    if (result != null) return result;
  }
  // Check columns
  for (int c = 0; c < 9; c++) {
    final cells = {for (int r = 0; r < 9; r++) (r, c)};
    final result = _checkUnitForNakedTriple(cells, UnitType.column);
    if (result != null) return result;
  }
  // Check boxes
  for (int br = 0; br < 3; br++) {
    for (int bc = 0; bc < 3; bc++) {
      final cells = {
        for (int r = br * 3; r < br * 3 + 3; r++)
          for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
      };
      final result = _checkUnitForNakedTriple(cells, UnitType.box);
      if (result != null) return result;
    }
  }
  return null;
}

StrategyResult? _checkUnitForNakedTriple(
    Set<(int, int)> unitCells, UnitType unitType) {
  final emptyCells = unitCells
      .where((rc) => candidates[rc] != null && candidates[rc]!.isNotEmpty)
      .toList();

  // Find all combinations of 3 cells
  for (int i = 0; i < emptyCells.length; i++) {
    for (int j = i + 1; j < emptyCells.length; j++) {
      for (int k = j + 1; k < emptyCells.length; k++) {
        final triple = [emptyCells[i], emptyCells[j], emptyCells[k]];
        final combinedCandidates = <int>{};
        for (final cell in triple) {
          combinedCandidates.addAll(candidates[cell]!);
        }

        // Naked triple: exactly 3 combined candidates
        if (combinedCandidates.length == 3) {
          // Find elimination cells
          final eliminationCells = <(int, int)>{};
          for (final cell in emptyCells) {
            if (!triple.contains(cell)) {
              final cellCand = candidates[cell]!;
              for (final d in combinedCandidates) {
                if (cellCand.contains(d)) {
                  eliminationCells.add(cell);
                }
              }
            }
          }

          if (eliminationCells.isNotEmpty) {
            return StrategyResult(
              type: StrategyType.nakedTriple,
              phase: StrategyPhase.elimination,
              unitType: unitType,
              unitCells: unitCells,
              patternCells: triple.toSet(),
              patternDigits: combinedDigits,
              eliminationCells: eliminationCells,
            );
          }
        }
      }
    }
  }
  return null;
}
```

Note: Fix typo - use `patternDigits: combinedCandidates,` instead of `patternDigits: combinedDigits,`

**Step 2: Update findNextStrategy**

**Step 3: Commit**

---

### Task 8: Add Hidden Triple strategy

**Files:**
- Modify: `lib/logic/strategy_solver.dart`

**Step 1: Add findHiddenTriple method**

Similar pattern to Hidden Pair but with 3 digits and 3 cells.

**Step 2: Update findNextStrategy**

**Step 3: Commit**

---

### Task 9: Add Naked Quad strategy

**Files:**
- Modify: `lib/logic/strategy_solver.dart`

**Step 1: Add findNakedQuad method**

Similar pattern to Naked Triple but with 4 cells and 4 combined candidates.

**Step 2: Update findNextStrategy**

**Step 3: Commit**

---

### Task 10: Add Hidden Quad strategy

**Files:**
- Modify: `lib/logic/strategy_solver.dart`

**Step 1: Add findHiddenQuad method**

Similar pattern to Hidden Triple but with 4 digits and 4 cells.

**Step 2: Update findNextStrategy**

**Step 3: Commit**

---

### Task 11: Run flutter analyze to verify

**Files:**
- Run: `flutter analyze`

**Step 1: Run analysis**

```bash
flutter analyze
```

Expected: No errors

**Step 2: Commit any fixes**

---

### Task 12: Final commit

**Step 1: Commit remaining changes**

```bash
git add .
git commit -m "feat: complete strategy solver with all naked/hidden strategies"
```
