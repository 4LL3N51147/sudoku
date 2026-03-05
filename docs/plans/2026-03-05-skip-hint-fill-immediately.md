# Skip Hint Animation — Fill Immediately Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** When the "Skip Animation" toggle is ON, hints immediately apply their result (fill the cell or update candidates) with no animation phases, no hint banner, and no required clicks.

**Architecture:** Two code paths in `game_screen.dart` handle hints: the legacy `_runHiddenSingleHint()` and the newer `_runStrategyHint()`. Both currently skip to phase 2 but still show a banner. We replace both skip-animation blocks with immediate application logic. For Hidden Single: fill immediately. For elimination strategies: update `_candidates` and show a snackbar.

**Tech Stack:** Flutter/Dart, Playwright (for integration tests)

---

### Task 1: Fix `_runHiddenSingleHint()` — immediate fill on skip

**Files:**
- Modify: `lib/screens/game_screen.dart:331-349`

**Step 1: Locate the skip-animation block in `_runHiddenSingleHint()`**

Lines 331–349 in `game_screen.dart`:
```dart
// If skip animation is enabled, go directly to target phase
if (_settings.skipHintAnimation) {
  setState(() {
    _isAnimating = true;
    _hintPhase = 2; // Target phase
    _hintMessage = '${result.digit} has only one valid cell left in this $unitLabel!';
    _strategyHighlight = StrategyHighlight(
      phase: StrategyPhase.target,
      ...
    );
  });
  return;
}
```

**Step 2: Replace with immediate fill logic**

Replace the entire `if (_settings.skipHintAnimation)` block (lines 331–349) with:

```dart
// If skip animation is enabled, fill immediately with no UI
if (_settings.skipHintAnimation) {
  setState(() {
    final oldValue = _board[result.row][result.col];
    _undoStack.add((
      row: result.row,
      col: result.col,
      oldValue: oldValue,
      newValue: result.digit,
    ));
    _board[result.row][result.col] = result.digit;
    _updateErrors();
    _selectedRow = result.row;
    _selectedCol = result.col;
    if (_checkWin()) {
      _isCompleted = true;
      _timer?.cancel();
    }
  });
  if (_isCompleted) _showWinDialog();
  return;
}
```

**Step 3: Run flutter analyze**

```bash
flutter analyze
```
Expected: No new errors (7 existing info-level warnings are OK).

**Step 4: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "feat: skip animation fills Hidden Single immediately (legacy path)"
```

---

### Task 2: Fix `_runStrategyHint()` — immediate fill/apply on skip

**Files:**
- Modify: `lib/screens/game_screen.dart:697-724`

**Step 1: Locate the skip-animation block in `_runStrategyHint()`**

Lines 697–724 in `game_screen.dart`:
```dart
// If skip animation is enabled, go directly to elimination phase
if (_settings.skipHintAnimation) {
  ...
  setState(() {
    _isAnimating = true;
    _hintPhase = 2;
    ...
  });
  return;
}
```

**Step 2: Replace with immediate apply logic**

Replace the entire `if (_settings.skipHintAnimation)` block with:

```dart
// If skip animation is enabled, apply immediately with no UI
if (_settings.skipHintAnimation) {
  if (type == StrategyType.hiddenSingle && result.targetCell != null) {
    // Hidden Single: fill the cell immediately
    final (row, col) = result.targetCell!;
    setState(() {
      final oldValue = _board[row][col];
      _undoStack.add((
        row: row,
        col: col,
        oldValue: oldValue,
        newValue: result.patternDigits.first,
      ));
      _board[row][col] = result.patternDigits.first;
      _updateErrors();
      _selectedRow = row;
      _selectedCol = col;
      if (_checkWin()) {
        _isCompleted = true;
        _timer?.cancel();
      }
    });
    if (_isCompleted) _showWinDialog();
  } else {
    // Elimination strategy: apply eliminations to candidates
    setState(() {
      final updated = Map<(int, int), Set<int>>.from(_candidates);
      for (final entry in result.eliminationCandidates.entries) {
        final cell = entry.key;
        final digits = entry.value;
        if (updated.containsKey(cell)) {
          updated[cell] = updated[cell]!.difference(digits);
        }
      }
      _candidates = updated;
    });
    final strategyName = type.name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => ' ${m.group(1)}',
    ).trim();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$strategyName applied — candidates updated')),
      );
    }
  }
  return;
}
```

**Step 3: Run flutter analyze**

```bash
flutter analyze
```
Expected: No new errors.

**Step 4: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "feat: skip animation applies strategy hints immediately"
```

---

### Task 3: Build and Playwright integration test

**Files:**
- No new files (use existing Playwright MCP tools)

**Step 1: Build the web app**

```bash
flutter build web
```

**Step 2: Serve locally**

```bash
python3 -m http.server 8080 --directory build/web &
```

**Step 3: Run Playwright tests**

Use the Playwright MCP tools to verify:
1. Navigate to `http://localhost:8080`
2. Select a difficulty and start a game
3. Open Settings, enable "Skip Animation"
4. Click the hint (lightbulb) button and pick "Hidden Single"
5. Verify: the cell fills immediately — **no banner appears**, no "Next →" button
6. Verify: the cell that was filled is now selected and correct

**Step 4: Test elimination strategy skip**

1. With Skip Animation still ON, click hint → pick "Naked Pair" (or any elimination strategy)
2. Verify: no banner appears, a snackbar shows "Naked Pair applied — candidates updated"
3. Verify: candidate numbers on the board reflect the elimination

**Step 5: Test skip OFF (regression)**

1. Disable "Skip Animation" in settings
2. Run a Hidden Single hint
3. Verify: multi-phase animation still works (scan → elimination → target → fill)

**Step 6: Kill the server and commit**

```bash
kill %1
git add .
git commit -m "test: verify skip animation fills immediately via Playwright"
```
