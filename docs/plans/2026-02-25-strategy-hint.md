# Strategy Hint (Hidden Single) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a strategy hint system where the user picks "Hidden Single" from a bottom sheet, the app animates through the reasoning on the board, then auto-fills the answer.

**Architecture:** Three-layer change — pure logic in `strategy_solver.dart`, board rendering extended with a `StrategyHighlight` prop in `sudoku_board.dart`, and animation orchestration + UI in `game_screen.dart`. Animation is driven by `Future.delayed` phases; state lives in `GameScreen`.

**Tech Stack:** Flutter 3.35, Dart 3.9, `flutter test` for unit + widget tests.

---

### Task 1: Strategy solver logic

**Files:**
- Create: `lib/logic/strategy_solver.dart`
- Create: `test/logic/strategy_solver_test.dart`

---

**Step 1: Create the test file with a failing test for the null case**

```dart
// test/logic/strategy_solver_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/logic/strategy_solver.dart';

void main() {
  group('findHiddenSingle', () {
    test('returns null for a fully solved board', () {
      final board = [
        [5,3,4,6,7,8,9,1,2],
        [6,7,2,1,9,5,3,4,8],
        [1,9,8,3,4,2,5,6,7],
        [8,5,9,7,6,1,4,2,3],
        [4,2,6,8,5,3,7,9,1],
        [7,1,3,9,2,4,8,5,6],
        [9,6,1,5,3,7,2,8,4],
        [2,8,7,4,1,9,6,3,5],
        [3,4,5,2,8,6,1,7,9],
      ];
      expect(findHiddenSingle(board), isNull);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/logic/strategy_solver_test.dart
```
Expected: compilation error — `strategy_solver.dart` does not exist yet.

---

**Step 3: Create `lib/logic/strategy_solver.dart` with data classes and skeleton**

```dart
// lib/logic/strategy_solver.dart

enum StrategyPhase { none, scan, elimination, target }

class HiddenSingleResult {
  final int row;
  final int col;
  final int digit;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;

  const HiddenSingleResult({
    required this.row,
    required this.col,
    required this.digit,
    required this.unitCells,
    required this.eliminatorCells,
  });
}

class StrategyHighlight {
  final StrategyPhase phase;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final (int, int)? targetCell;

  const StrategyHighlight({
    required this.phase,
    this.unitCells = const {},
    this.eliminatorCells = const {},
    this.targetCell,
  });
}

/// Returns the first hidden single found on the board, or null if none.
/// Scans rows → columns → boxes in order.
HiddenSingleResult? findHiddenSingle(List<List<int>> board) {
  // rows
  for (int r = 0; r < 9; r++) {
    final cells = {for (int c = 0; c < 9; c++) (r, c)};
    final result = _checkUnit(board, cells);
    if (result != null) return result;
  }
  // columns
  for (int c = 0; c < 9; c++) {
    final cells = {for (int r = 0; r < 9; r++) (r, c)};
    final result = _checkUnit(board, cells);
    if (result != null) return result;
  }
  // boxes
  for (int br = 0; br < 3; br++) {
    for (int bc = 0; bc < 3; bc++) {
      final cells = {
        for (int r = br * 3; r < br * 3 + 3; r++)
          for (int c = bc * 3; c < bc * 3 + 3; c++) (r, c),
      };
      final result = _checkUnit(board, cells);
      if (result != null) return result;
    }
  }
  return null;
}

HiddenSingleResult? _checkUnit(
    List<List<int>> board, Set<(int, int)> unitCells) {
  final presentDigits = {
    for (final (r, c) in unitCells)
      if (board[r][c] != 0) board[r][c],
  };

  for (int digit = 1; digit <= 9; digit++) {
    if (presentDigits.contains(digit)) continue;

    // Find empty cells in the unit where digit is still legal
    final candidates = <(int, int)>[];
    for (final (r, c) in unitCells) {
      if (board[r][c] == 0 && _isLegal(board, r, c, digit)) {
        candidates.add((r, c));
      }
    }

    if (candidates.length == 1) {
      final (tr, tc) = candidates.first;
      // Collect eliminator cells: for each other empty unit cell where digit
      // is blocked, find the cell in the board that blocks it.
      final eliminators = <(int, int)>{};
      for (final (r, c) in unitCells) {
        if ((r, c) == (tr, tc)) continue;
        if (board[r][c] != 0) continue; // already filled — not a blocked candidate
        // Find which existing cell blocks digit at (r, c)
        eliminators.addAll(_findBlockers(board, r, c, digit));
      }
      return HiddenSingleResult(
        row: tr,
        col: tc,
        digit: digit,
        unitCells: unitCells,
        eliminatorCells: eliminators,
      );
    }
  }
  return null;
}

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

/// Returns the board cells that prevent [digit] from going at ([row],[col]).
Set<(int, int)> _findBlockers(
    List<List<int>> board, int row, int col, int digit) {
  final blockers = <(int, int)>{};
  for (int c = 0; c < 9; c++) {
    if (board[row][c] == digit) blockers.add((row, c));
  }
  for (int r = 0; r < 9; r++) {
    if (board[r][col] == digit) blockers.add((r, col));
  }
  final br = (row ~/ 3) * 3;
  final bc = (col ~/ 3) * 3;
  for (int r = br; r < br + 3; r++) {
    for (int c = bc; c < bc + 3; c++) {
      if (board[r][c] == digit) blockers.add((r, c));
    }
  }
  return blockers;
}
```

**Step 4: Run test — expect it to pass**

```bash
flutter test test/logic/strategy_solver_test.dart
```
Expected: PASS (1 test).

---

**Step 5: Add tests for hidden single detection in a row, column, and box**

Add to the `group` block in `test/logic/strategy_solver_test.dart`:

```dart
    test('finds a hidden single in a row', () {
      // Row 0: only cell (0,1) can hold digit 2
      // All other empty cells in row 0 are blocked by a 2 in their column/box
      final board = List.generate(9, (_) => List.filled(9, 0));
      // Fill a near-complete board leaving one hidden single
      // Row 0: [0, 0, 3, 4, 5, 6, 7, 8, 9] — digit 2 can only go at (0,1)
      board[0] = [0, 0, 3, 4, 5, 6, 7, 8, 9];
      // Block (0,0) for digit 2 via column 0
      board[1][0] = 2;
      // Give rows 1-8 enough data to keep the board legal
      board[1] = [2, 1, 4, 3, 6, 5, 8, 7, 0];
      // Remaining rows left as zeros — solver finds row 0 first

      final result = findHiddenSingle(board);
      expect(result, isNotNull);
      expect(result!.digit, 2);
      expect(result.row, 0);
      expect(result.col, 1);
      expect(result.unitCells.length, 9);
    });

    test('result unitCells always contains exactly 9 cells', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0] = [0, 0, 3, 4, 5, 6, 7, 8, 9];
      board[1][0] = 2;
      board[1] = [2, 1, 4, 3, 6, 5, 8, 7, 0];
      final result = findHiddenSingle(board);
      expect(result?.unitCells.length, 9);
    });

    test('eliminatorCells are non-empty when other candidates are blocked', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0] = [0, 0, 3, 4, 5, 6, 7, 8, 9];
      board[1][0] = 2;
      board[1] = [2, 1, 4, 3, 6, 5, 8, 7, 0];
      final result = findHiddenSingle(board);
      expect(result?.eliminatorCells, isNotEmpty);
    });
```

**Step 6: Run all solver tests**

```bash
flutter test test/logic/strategy_solver_test.dart
```
Expected: PASS (4 tests).

---

**Step 7: Commit**

```bash
git add lib/logic/strategy_solver.dart test/logic/strategy_solver_test.dart
git commit -m "feat: add hidden single detection logic with tests"
```

---

### Task 2: Extend SudokuBoard with strategy highlight rendering

**Files:**
- Modify: `lib/widgets/sudoku_board.dart`

---

**Step 1: Add `strategyHighlight` parameter to `SudokuBoard`**

In `lib/widgets/sudoku_board.dart`, add the import and parameter:

```dart
import '../logic/strategy_solver.dart'; // add at top

// Add to SudokuBoard fields:
final StrategyHighlight? strategyHighlight;

// Add to constructor:
this.strategyHighlight,
```

**Step 2: Update `_buildCell` to apply strategy colors**

Replace the `Color bgColor` block in `_buildCell` with this extended version:

```dart
Color bgColor;
final sh = strategyHighlight;
if (sh != null && sh.phase != StrategyPhase.none) {
  final cell = (row, col);
  if (sh.phase == StrategyPhase.target && sh.targetCell == cell) {
    bgColor = const Color(0xFFC8E6C9); // green-100 — "place digit here"
  } else if (sh.phase == StrategyPhase.elimination &&
      sh.eliminatorCells.contains(cell)) {
    bgColor = const Color(0xFFFFE0B2); // amber-100 — "this blocks other cells"
  } else if (sh.unitCells.contains(cell)) {
    bgColor = const Color(0xFFE3F2FD); // blue-50 — "scanning this unit"
  } else {
    bgColor = Colors.white;
  }
} else if (selected) {
  bgColor = const Color(0xFF90CAF9);
} else if (sameNum) {
  bgColor = const Color(0xFFBBDEFB);
} else if (highlighted) {
  bgColor = const Color(0xFFE8EAF6);
} else {
  bgColor = Colors.white;
}
```

Note: During strategy animation, normal selection highlights are suppressed — the strategy context takes full priority.

**Step 3: Pass `strategyHighlight` through `_buildBlock` → `_buildCell`**

`_buildBlock` calls `_buildCell`; `_buildCell` needs access to `strategyHighlight`. Since both are methods on `SudokuBoard` (a stateless widget), `strategyHighlight` is already accessible as `this.strategyHighlight` — no extra passing needed.

**Step 4: Verify the app still compiles with no regressions**

```bash
flutter build web 2>&1 | tail -5
```
Expected: `✓ Built build/web`

**Step 5: Commit**

```bash
git add lib/widgets/sudoku_board.dart
git commit -m "feat: extend SudokuBoard with strategy highlight rendering"
```

---

### Task 3: Strategy picker bottom sheet + animation in GameScreen

**Files:**
- Modify: `lib/screens/game_screen.dart`

---

**Step 1: Add imports and state**

At the top of `game_screen.dart`, add:
```dart
import '../logic/strategy_solver.dart';
```

Add to `_GameScreenState` fields:
```dart
StrategyHighlight? _strategyHighlight;
```

**Step 2: Add the `_runHiddenSingleHint()` method**

Add this async method to `_GameScreenState`:

```dart
Future<void> _runHiddenSingleHint() async {
  final result = findHiddenSingle(_board);
  if (result == null) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No hidden singles on this board.')),
    );
    return;
  }

  final wasRunning = !_isPaused && !_isCompleted;
  if (wasRunning) setState(() => _isPaused = true);

  // Phase 1 — scan: highlight the unit
  setState(() {
    _strategyHighlight = StrategyHighlight(
      phase: StrategyPhase.scan,
      unitCells: result.unitCells,
    );
  });
  await Future.delayed(const Duration(milliseconds: 800));
  if (!mounted) return;

  // Phase 2 — elimination: show what blocks other cells
  setState(() {
    _strategyHighlight = StrategyHighlight(
      phase: StrategyPhase.elimination,
      unitCells: result.unitCells,
      eliminatorCells: result.eliminatorCells,
    );
  });
  await Future.delayed(const Duration(milliseconds: 1200));
  if (!mounted) return;

  // Phase 3 — target: highlight the answer cell
  setState(() {
    _strategyHighlight = StrategyHighlight(
      phase: StrategyPhase.target,
      unitCells: result.unitCells,
      eliminatorCells: result.eliminatorCells,
      targetCell: (result.row, result.col),
    );
  });
  await Future.delayed(const Duration(milliseconds: 800));
  if (!mounted) return;

  // Fill the number
  setState(() {
    _board[result.row][result.col] = result.digit;
    _updateErrors();
    _strategyHighlight = null;
    _selectedRow = result.row;
    _selectedCol = result.col;
    if (wasRunning) _isPaused = false;
    if (_checkWin()) {
      _isCompleted = true;
      _timer?.cancel();
    }
  });

  if (_isCompleted) _showWinDialog();
}
```

**Step 3: Add the `_showStrategyPicker()` bottom sheet method**

```dart
void _showStrategyPicker() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Choose a Strategy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline,
                color: Color(0xFF1A237E)),
            title: const Text('Hidden Single'),
            subtitle: const Text(
              'Find a digit that can only go in one cell within a row, column, or box',
            ),
            onTap: () {
              Navigator.pop(context);
              _runHiddenSingleHint();
            },
          ),
        ],
      ),
    ),
  );
}
```

**Step 4: Add the strategy button to the header**

In `_buildHeader()`, find the `IconButton` for pause and add a strategy button before it:

```dart
IconButton(
  icon: const Icon(Icons.lightbulb_outline),
  onPressed: (_isPaused || _isCompleted) ? null : _showStrategyPicker,
  color: const Color(0xFF1A237E),
  iconSize: 26,
),
```

**Step 5: Pass `_strategyHighlight` to `SudokuBoard`**

In the `build` method, update the `SudokuBoard(...)` call to include:
```dart
strategyHighlight: _strategyHighlight,
```

**Step 6: Build and verify**

```bash
flutter build web 2>&1 | tail -5
```
Expected: `✓ Built build/web`

**Step 7: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "feat: add strategy picker bottom sheet and hidden single animation"
```

---

### Task 4: Manual smoke test in browser

**Step 1: Rebuild and reload**

```bash
flutter build web 2>&1 | tail -3
# Then hard-reload http://localhost:8080 in the browser
```

**Step 2: Verify the flow**

1. Open app → tap EASY → confirm lightbulb icon appears in header
2. Tap lightbulb → bottom sheet opens with "Hidden Single" tile
3. Tap "Hidden Single" → board animates:
   - Phase 1: 9 cells of a row/col/box flash light blue
   - Phase 2: blocking cells turn amber
   - Phase 3: target cell turns green
   - Number fills automatically
4. Tap lightbulb again → repeat until snackbar "No hidden singles" appears (or puzzle completes)
5. Confirm timer was paused during animation and resumes after fill
