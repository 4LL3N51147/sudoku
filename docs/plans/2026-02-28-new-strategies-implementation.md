# New Sudoku Strategies Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add three new Sudoku solving strategies (Naked Single, Naked/Hidden Pair, Naked Triple/Quad) to the hint system with animated steps.

**Architecture:** Add new strategy solver functions in `lib/logic/strategy_solver.dart` (pure Dart, no Flutter imports). Each returns result objects with cells and candidates. Add runner methods in `game_screen.dart` to animate and apply the strategies.

**Tech Stack:** Dart, Flutter, Pure Dart logic in `lib/logic/`

---

## Task 1: Add Naked Single Strategy

**Files:**
- Modify: `lib/logic/strategy_solver.dart:1-22` (add NakedSingleResult class)
- Modify: `lib/logic/strategy_solver.dart` (add findNakedSingle function)
- Modify: `lib/screens/game_screen.dart` (add _runNakedSingleHint method and UI entry)

**Step 1: Add NakedSingleResult class to strategy_solver.dart**

Add after line 21 (after HiddenSingleResult class closing brace):

```dart
class NakedSingleResult {
  final int row;
  final int col;
  final int digit;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final UnitType unitType;

  const NakedSingleResult({
    required this.row,
    required this.col,
    required this.digit,
    required this.unitCells,
    required this.eliminatorCells,
    required this.unitType,
  });
}
```

**Step 2: Add findNakedSingle function to strategy_solver.dart**

Add at end of file (after line 140):

```dart
/// Finds a naked single: a cell with only one possible candidate.
/// Returns the cell position and digit, or null if none found.
/// Requires pencilMarks to determine candidates.
NakedSingleResult? findNakedSingle(
    List<List<int>> board, List<List<Set<int>>> pencilMarks) {
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      if (board[r][c] != 0) continue;
      final candidates = pencilMarks[r][c];
      if (candidates.length == 1) {
        final digit = candidates.first;
        // Find the unit for highlighting
        final unitCells = <(int, int)>{};
        // Row
        for (int i = 0; i < 9; i++) unitCells.add((r, i));
        // Find blockers for elimination animation
        final eliminators = _findBlockers(board, r, c, digit);
        return NakedSingleResult(
          row: r,
          col: c,
          digit: digit,
          unitCells: unitCells,
          eliminatorCells: eliminators,
          unitType: UnitType.row,
        );
      }
    }
  }
  return null;
}
```

**Step 3: Add _runNakedSingleHint method to game_screen.dart**

Find the _runHiddenSingleHint method (around line 276) and add _runNakedSingleHint after it:

```dart
Future<void> _runNakedSingleHint() async {
  final result = findNakedSingle(_board, _pencilMarks);
  if (result == null) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No naked singles on this board.')),
    );
    return;
  }

  setState(() {
    _hintPhase = 0;
    _hintMessage = 'Looking for cells with only one possible number...';
    _highlightedCells = result.unitCells;
    _targetCell = null;
    _selectedNumber = null;
  });

  await Future.delayed(const Duration(milliseconds: 800));
  if (!mounted || _hintPhase == null) return;

  setState(() {
    _hintPhase = 1;
    _highlightedCells = result.eliminatorCells;
    _hintMessage = 'This cell can only contain ${result.digit}';
  });

  await Future.delayed(const Duration(milliseconds: 1200));
  if (!mounted || _hintPhase == null) return;

  setState(() {
    _hintPhase = 2;
    _targetCell = (result.row, result.col);
    _selectedNumber = result.digit;
    _hintMessage = 'Found it!';
  });

  await Future.delayed(const Duration(milliseconds: 1000));
  if (!mounted || _hintPhase == null) return;

  _placeNumber(result.row, result.col, result.digit);
  _clearHintState();
}
```

**Step 4: Add Naked Single to strategy picker in game_screen.dart**

Find _showStrategyPicker (line 375) and add ListTile for Naked Single BEFORE Hidden Single (line 394):

```dart
ListTile(
  leading: const Icon(Icons.looks_one, color: Color(0xFF1A237E)),
  title: const Text('Naked Single'),
  subtitle: const Text(
    'Find a cell with only one possible number',
  ),
  onTap: () {
    Navigator.pop(context);
    unawaited(_runNakedSingleHint());
  },
),
```

**Step 5: Verify with analyze**

Run: `flutter analyze`
Expected: No new issues

---

## Task 2: Add Naked Pair Strategy

**Files:**
- Modify: `lib/logic/strategy_solver.dart` (add NakedPairResult class and findNakedPair function)
- Modify: `lib/screens/game_screen.dart` (add _runNakedPairHint method and UI entry)

**Step 1: Add NakedPairResult class to strategy_solver.dart**

Add after NakedSingleResult class:

```dart
class NakedPairResult {
  final Set<(int, int)> pairCells;  // The two cells with the pair
  final Set<int> digits;  // The two digits
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final UnitType unitType;

  const NakedPairResult({
    required this.pairCells,
    required this.digits,
    required this.unitCells,
    required this.eliminatorCells,
    required this.unitType,
  });
}
```

**Step 2: Add findNakedPair function to strategy_solver.dart**

Add at end of file:

```dart
/// Finds a naked pair: two cells in same unit with exactly the same two candidates.
/// Returns the cells and digits, or null if none found.
NakedPairResult? findNakedPair(
    List<List<int>> board, List<List<Set<int>>> pencilMarks) {
  // Check rows
  for (int r = 0; r < 9; r++) {
    final cells = <(int, int), Set<int>>{};
    for (int c = 0; c < 9; c++) {
      if (board[r][c] == 0 && pencilMarks[r][c].length == 2) {
        cells[(r, c)] = pencilMarks[r][c];
      }
    }
    final result = _findMatchingCandidates(cells, UnitType.row);
    if (result != null) return result;
  }

  // Check columns
  for (int c = 0; c < 9; c++) {
    final cells = <(int, int), Set<int>>{};
    for (int r = 0; r < 9; r++) {
      if (board[r][c] == 0 && pencilMarks[r][c].length == 2) {
        cells[(r, c)] = pencilMarks[r][c];
      }
    }
    final result = _findMatchingCandidates(cells, UnitType.column);
    if (result != null) return result;
  }

  // Check boxes
  for int br = 0; br < 3; br++) {
    for (int bc = 0; bc < 3; bc++) {
      final cells = <(int, int), Set<int>>{};
      for (int r = br * 3; r < br * 3 + 3; r++) {
        for (int c = bc * 3; c < bc * 3 + 3; c++) {
          if (board[r][c] == 0 && pencilMarks[r][c].length == 2) {
            cells[(r, c)] = pencilMarks[r][c];
          }
        }
      }
      final result = _findMatchingCandidates(cells, UnitType.box);
      if (result != null) return result;
    }
  }

  return null;
}

NakedPairResult? _findMatchingCandidates(
    Map<(int, int), Set<int>> cells, UnitType unitType) {
  // Find two cells with exactly the same candidates
  final entries = cells.entries.toList();
  for (int i = 0; i < entries.length; i++) {
    for (int j = i + 1; j < entries.length; j++) {
      if (entries[i].value.containsAll(entries[j].value) &&
          entries[j].value.containsAll(entries[i].value)) {
        final pairCells = {entries[i].key, entries[j].key};
        final digits = entries[i].value;
        // Get all cells in unit for highlighting
        final unitCells = <(int, int)>{};
        final (r, c) = entries[i].key;
        if (unitType == UnitType.row) {
          for (int i = 0; i < 9; i++) unitCells.add((r, i));
        } else if (unitType == UnitType.column) {
          for (int i = 0; i < 9; i++) unitCells.add((i, c));
        } else {
          final br = r ~/ 3;
          final bc = c ~/ 3;
          for (int rr = br * 3; rr < br * 3 + 3; rr++) {
            for (int cc = bc * 3; cc < bc * 3 + 3; cc++) {
              unitCells.add((rr, cc));
            }
          }
        }
        // Eliminators are other cells in unit that have these digits
        final eliminators = <(int, int)>{};
        for (final (er, ec) in unitCells) {
          if (pairCells.contains((er, ec))) continue;
          for (final d in digits) {
            if (_isLegal(board, er, ec, d)) {
              eliminators.add((er, ec));
              break;
            }
          }
        }
        return NakedPairResult(
          pairCells: pairCells,
          digits: digits,
          unitCells: unitCells,
          eliminatorCells: eliminators,
          unitType: unitType,
        );
      }
    }
  }
  return null;
}
```

Note: Add `List<List<int>> board` as a static variable or pass it to helper functions.

**Step 3: Add _runNakedPairHint method to game_screen.dart**

```dart
Future<void> _runNakedPairHint() async {
  final result = findNakedPair(_board, _pencilMarks);
  if (result == null) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No naked pairs found.')),
    );
    return;
  }

  setState(() {
    _hintPhase = 0;
    _hintMessage = 'Looking for two cells with the same two candidates...';
    _highlightedCells = result.unitCells;
    _targetCell = null;
    _selectedNumber = null;
  });

  await Future.delayed(const Duration(milliseconds: 800));
  if (!mounted || _hintPhase == null) return;

  setState(() {
    _hintPhase = 1;
    _highlightedCells = result.pairCells;
    _hintMessage = 'Found a naked pair: ${result.digits.join(", ")}';
  });

  await Future.delayed(const Duration(milliseconds: 1200));
  if (!mounted || _hintPhase == null) return;

  setState(() {
    _hintPhase = 2;
    _hintMessage = 'Remove ${result.digits.join(", ")} from highlighted cells';
    _highlightedCells = result.eliminatorCells;
  });

  await Future.delayed(const Duration(milliseconds: 1500));
  if (!mounted || _hintPhase == null) return;

  // Remove the pair digits from other cells in the unit
  for (final (r, c) in result.eliminatorCells) {
    final newCandidates = Set<int>.from(_pencilMarks[r][c]);
    for (final d in result.digits) {
      newCandidates.remove(d);
    }
    setState(() {
      _pencilMarks[r][c] = newCandidates;
    });
  }

  _clearHintState();
}
```

**Step 4: Add Naked Pair to strategy picker**

Add after Naked Single ListTile:

```dart
ListTile(
  leading: const Icon(Icons.looks_two, color: Color(0xFF1A237E)),
  title: const Text('Naked Pair'),
  subtitle: const Text(
    'Two cells with the same two candidates',
  ),
  onTap: () {
    Navigator.pop(context);
    unawaited(_runNakedPairHint());
  },
),
```

**Step 5: Verify with analyze**

Run: `flutter analyze`
Expected: No new issues

---

## Task 3: Add Hidden Pair Strategy

**Files:**
- Modify: `lib/logic/strategy_solver.dart` (add HiddenPairResult class and findHiddenPair function)
- Modify: `lib/screens/game_screen.dart` (add _runHiddenPairHint method and UI entry)

**Step 1: Add HiddenPairResult class**

```dart
class HiddenPairResult {
  final Set<(int, int)> pairCells;
  final Set<int> digits;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final UnitType unitType;

  const HiddenPairResult({
    required this.pairCells,
    required this.digits,
    required this.unitCells,
    required this.eliminatorCells,
    required this.unitType,
  });
}
```

**Step 2: Add findHiddenPair function**

```dart
/// Finds a hidden pair: two digits that only appear in exactly two cells in a unit.
HiddenPairResult? findHiddenPair(
    List<List<int>> board, List<List<Set<int>>> pencilMarks) {
  // Check rows
  for (int r = 0; r < 9; r++) {
    final result = _findHiddenPairInUnit(board, r, -1, pencilMarks, UnitType.row);
    if (result != null) return result;
  }
  // Check columns
  for (int c = 0; c < 9; c++) {
    final result = _findHiddenPairInUnit(board, -1, c, pencilMarks, UnitType.column);
    if (result != null) return result;
  }
  // Check boxes
  for (int br = 0; br < 3; br++) {
    for (int bc = 0; bc < 3; bc++) {
      final result = _findHiddenPairInBox(board, br, bc, pencilMarks);
      if (result != null) return result;
    }
  }
  return null;
}

HiddenPairResult? _findHiddenPairInUnit(
    List<List<int>> board, int row, int col,
    List<List<Set<int>>> pencilMarks, UnitType unitType) {
  // Count occurrences of each digit across cells in unit
  final digitPositions = <int, Set<(int, int)>>{};
  for (int i = 0; i < 9; i++) {
    final r = unitType == UnitType.row ? row : i;
    final c = unitType == UnitType.column ? col : i;
    if (board[r][c] != 0) continue;
    for (final d in pencilMarks[r][c]) {
      digitPositions.putIfAbsent(d, () => {}).add((r, c));
    }
  }

  // Find two digits that appear in exactly the same two cells
  final digits = digitPositions.keys.toList();
  for (int i = 0; i < digits.length; i++) {
    for (int j = i + 1; j < digits.length; j++) {
      final pos1 = digitPositions[digits[i]]!;
      final pos2 = digitPositions[digits[j]]!;
      if (pos1.length == 2 && pos2.length == 2 &&
          pos1.containsAll(pos2) && pos2.containsAll(pos1)) {
        final pairCells = pos1;
        final unitCells = <(int, int)>{};
        for (int k = 0; k < 9; k++) {
          if (unitType == UnitType.row) {
            unitCells.add((row, k));
          } else {
            unitCells.add((k, col));
          }
        }
        // Eliminators are other cells in unit with these digits
        final eliminators = <(int, int)>{};
        for (final (er, ec) in unitCells) {
          if (pairCells.contains((er, ec))) continue;
          if (pencilMarks[er][ec].contains(digits[i]) ||
              pencilMarks[er][ec].contains(digits[j])) {
            eliminators.add((er, ec));
          }
        }
        return HiddenPairResult(
          pairCells: pairCells,
          digits: {digits[i], digits[j]},
          unitCells: unitCells,
          eliminatorCells: eliminators,
          unitType: unitType,
        );
      }
    }
  }
  return null;
}
```

Similar for boxes. Add _findHiddenPairInBox function.

**Step 3: Add _runHiddenPairHint to game_screen.dart**

Similar to Naked Pair but highlights the hidden pair discovery.

**Step 4: Add Hidden Pair to strategy picker**

---

## Task 4: Add Naked Triple Strategy

**Files:**
- Modify: `lib/logic/strategy_solver.dart` (add NakedTripleResult and findNakedTriple)
- Modify: `lib/screens/game_screen.dart` (add runner and UI entry)

**Step 1: Add NakedTripleResult class**

```dart
class NakedTripleResult {
  final Set<(int, int)> tripleCells;
  final Set<int> digits;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final UnitType unitType;

  const NakedTripleResult({
    required this.tripleCells,
    required this.digits,
    required this.unitCells,
    required this.eliminatorCells,
    required this.unitType,
  });
}
```

**Step 2: Add findNakedTriple function**

Logic: Find 3 cells in a unit where the union of their candidates is exactly 3 digits.

```dart
/// Finds a naked triple: three cells in a unit where the union of their
/// candidates is exactly three digits.
NakedTripleResult? findNakedTriple(
    List<List<int>> board, List<List<Set<int>>> pencilMarks) {
  // Check each unit type (rows, columns, boxes)
  // For each unit, find 3 cells whose combined candidates = exactly 3 digits
  // ... implementation
}
```

**Step 3: Add _runNakedTripleHint to game_screen.dart**

Similar pattern - animate scan → elimination → target, then remove candidates.

**Step 4: Add Naked Triple to strategy picker**

---

## Task 5: Add Naked Quad Strategy

**Files:**
- Modify: `lib/logic/strategy_solver.dart` (add NakedQuadResult and findNakedQuad)
- Modify: `lib/screens/game_screen.dart` (add runner and UI entry)

Similar to Naked Triple but for 4 cells with 4 shared candidates.

---

## Task 6: Update Strategy Picker Order

Ensure all strategies appear in correct difficulty order in _showStrategyPicker:

1. Naked Single (easiest)
2. Hidden Single
3. Naked Pair
4. Hidden Pair
5. Naked Triple
6. Naked Quad (hardest)

---

## Task 7: Final Testing

**Step 1: Run analyze**

Run: `flutter analyze`
Expected: No issues

**Step 2: Build web**

Run: `flutter build web`
Expected: Success

---

## Plan Complete

The plan is saved to `docs/plans/2026-02-28-new-strategies-design.md`.

**Two execution options:**

1. **Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

2. **Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

Which approach?
