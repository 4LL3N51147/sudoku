# NumberPad Disable and Pencil Mark Highlight Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Disable number buttons when digit exists in all 9 blocks, and highlight matching pencil marks when a cell is selected.

**Architecture:** Create a unified `_fillCell()` method that handles all cell filling (user input + hints) and tracks completed digits. Add props to NumberPad and SudokuBoard for the new UI features.

**Tech Stack:** Flutter/Dart

---

### Task 1: Update NumberPad to support disabled digits

**Files:**
- Modify: `lib/widgets/number_pad.dart:1-80`

**Step 1: Add disabledDigits prop**

Edit the `NumberPad` class to add a new optional prop:

```dart
class NumberPad extends StatelessWidget {
  final void Function(int) onNumber;
  final void Function() onErase;
  final Set<int>? disabledDigits;  // NEW PROP

  const NumberPad({
    super.key,
    required this.onNumber,
    required this.onErase,
    this.disabledDigits,  // ADD THIS
  });
```

**Step 2: Update _PadButton to accept disabled state**

Modify the `_PadButton` class:

```dart
class _PadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDisabled;  // NEW FIELD

  const _PadButton({
    this.label,
    this.icon,
    required this.onTap,
    this.isDisabled = false,  // ADD DEFAULT
  });
```

**Step 3: Update _PadButton.build to handle disabled state**

```dart
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,  // CHANGED
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAF6),
            borderRadius: BorderRadius.circular(10),
            // ADD opacity for disabled state
            opacity: isDisabled ? 0.4 : 1.0,
          ),
          // ... rest of the widget
        ),
      ),
    );
  }
}
```

**Step 4: Pass disabled state from NumberPad.build**

In the `NumberPad.build` method, update the button creation:

```dart
        ...List.generate(
          9,
          (i) {
            final digit = i + 1;
            final isDisabled = disabledDigits?.contains(digit) ?? false;
            return _PadButton(
              label: '$digit',
              onTap: isDisabled ? () {} : () => onNumber(digit),
              isDisabled: isDisabled,
            );
          },
        ),
```

**Step 5: Run analyze**

Run: `flutter analyze`
Expected: No errors

**Step 6: Commit**

Run: `git add lib/widgets/number_pad.dart && git commit -m "feat: add disabledDigits prop to NumberPad"`

---

### Task 2: Add _completedDigits state and _fillCell method to GameScreen

**Files:**
- Modify: `lib/screens/game_screen.dart:29-50` (add state)
- Modify: `lib/screens/game_screen.dart:184-220` (add method, update _onNumberInput)

**Step 1: Add _completedDigits state**

After line 48 (after `final List<_Move> _undoStack = [];`), add:

```dart
  Set<int> _completedDigits = {};  // Track digits placed in all 9 blocks
```

**Step 2: Add _fillCell helper method**

After the `_onErase` method (around line 230), add:

```dart
  void _fillCell(int row, int col, int digit) {
    // Add to undo stack
    _undoStack.add((
      row: row,
      col: col,
      oldValue: _board[row][col],
      newValue: digit,
    ));

    // Fill the cell
    _board[row][col] = digit;
    _updateErrors();
    _candidates = computeCandidates(_board);

    // Track completed digits
    _updateCompletedDigits(digit);

    // Check win
    if (_checkWin()) {
      _isCompleted = true;
      _timer?.cancel();
      _showWinDialog();
    }
  }

  void _updateCompletedDigits(int digit) {
    // Count occurrences of this digit on the board
    int count = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_board[r][c] == digit) count++;
      }
    }
    if (count >= 9) {
      _completedDigits = {..._completedDigits, digit};
    }
  }
```

**Step 3: Update _onNumberInput to use _fillCell**

Replace the body of `_onNumberInput` (lines 184-205) with:

```dart
  void _onNumberInput(int num) {
    if (_isPaused || _isAnimating || _isCompleted) return;
    if (_selectedRow < 0 || _selectedCol < 0) return;
    if (_isGiven[_selectedRow][_selectedCol]) return;
    if (_board[_selectedRow][_selectedCol] == num) return;
    setState(() {
      _fillCell(_selectedRow, _selectedCol, num);
    });
  }
```

**Step 4: Run analyze**

Run: `flutter analyze`
Expected: No errors

**Step 5: Commit**

Run: `git add lib/screens/game_screen.dart && git commit -m "feat: add _fillCell method and _completedDigits tracking"`

---

### Task 3: Update hint logic to use _fillCell

**Files:**
- Modify: `lib/screens/game_screen.dart:437-453` (legacy HiddenSingle)
- Modify: `lib/screens/game_screen.dart:545-575` (strategy hints)

**Step 1: Update _advanceHintPhaseLegacy**

In the "Phase 2 complete" block (around line 437), replace the setState body with:

```dart
      setState(() {
        _fillCell(result.row, result.col, result.digit);
        _strategyHighlight = null;
        _hintMessage = null;
        _hintPhase = null;
        _currentHintResult = null;
        _isAnimating = false;
        _selectedRow = result.row;
        _selectedCol = result.col;
      });
```

**Step 2: Update _advanceHintPhaseStrategy**

In the "Phase 2 complete" block (around line 545), find the auto-fill section and replace with:

```dart
        setState(() {
          if (shouldAutoFill) {
            _fillCell(row, col, result.patternDigits.first);
          }
          // ... rest of elimination candidates code stays the same
          _strategyHighlight = null;
          _hintMessage = null;
          _hintPhase = null;
          _currentStrategyResult = null;
          _isAnimating = false;
          _selectedRow = row;
```

Note: The elimination candidates logic should remain as-is (that updates `_candidates` separately).

**Step 3: Run analyze**

Run: `flutter analyze`
Expected: No errors

**Step 4: Commit**

Run: `git add lib/screens/game_screen.dart && git commit -m "feat: update hint logic to use _fillCell"`

---

### Task 4: Pass _completedDigits to NumberPad in GameScreen

**Files:**
- Modify: `lib/screens/game_screen.dart` (find NumberPad usages, pass disabledDigits)

**Step 1: Find all NumberPad instantiations**

Run: `grep -n "NumberPad(" lib/screens/game_screen.dart`
Expected: Two locations around lines 926 and 969

**Step 2: Update NumberPad calls to pass disabledDigits**

For both NumberPad instances, add the prop:

```dart
          child: NumberPad(
            onNumber: _onNumberInput,
            onErase: _onErase,
            disabledDigits: _completedDigits,  // ADD THIS
          ),
```

**Step 3: Run analyze**

Run: `flutter analyze`
Expected: No errors

**Step 4: Commit**

Run: `git add lib/screens/game_screen.dart && git commit -m "feat: pass completed digits to NumberPad"`

---

### Task 5: Add matchingCandidates prop to SudokuBoard

**Files:**
- Modify: `lib/widgets/sudoku_board.dart:1-45` (add prop)
- Modify: `lib/widgets/sudoku_board.dart:220-264` (update _buildCandidates)

**Step 1: Add matchingCandidates prop**

In the `SudokuBoard` class (around line 13), add:

```dart
  final Map<(int, int), Set<int>>? candidates;
  final Set<int>? matchingCandidates;  // NEW PROP
```

Add to constructor:

```dart
  const SudokuBoard({
    // ... existing props
    this.candidates,
    this.matchingCandidates,  // ADD THIS
  });
```

**Step 2: Update _buildCandidates to highlight matching candidates**

In `_buildCandidates` method, update the candidate rendering:

```dart
        final digit = index + 1;
        final hasCandidate = cellCandidates.contains(digit);
        final isEliminated = _isEliminated(row, col, digit);
        final isMatching = matchingCandidates?.contains(digit) ?? false;  // NEW

        return Center(
          child: isEliminated
              ? Stack(...)
              : Text(
                  '$digit',
                  style: TextStyle(
                    fontSize: 9,
                    // CHANGED: highlight matching candidates
                    color: hasCandidate
                        ? (isMatching ? Colors.blue.shade700 : Colors.blue.shade700)
                        : Colors.transparent,
                    fontWeight: isMatching ? FontWeight.bold : FontWeight.normal,  // NEW
                  ),
                ),
        );
```

Wait - the color is the same. We need to highlight the BACKGROUND, not just the text. Let me fix that:

```dart
        return Center(
          child: isEliminated
              ? Stack(...)
              : Container(  // Wrap in Container for background
                  decoration: BoxDecoration(
                    color: isMatching ? const Color(0xFFBBDEFB) : null,  // blue-100
                    borderRadius: BorderRadius.circular(2),
                  ),
                  padding: const EdgeInsets.all(1),
                  child: Text(
                    '$digit',
                    style: TextStyle(
                      fontSize: 9,
                      color: hasCandidate ? Colors.blue.shade700 : Colors.transparent,
                      fontWeight: isMatching ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
        );
```

**Step 3: Run analyze**

Run: `flutter analyze`
Expected: No errors

**Step 4: Commit**

Run: `git add lib/widgets/sudoku_board.dart && git commit -m "feat: add matchingCandidates prop to SudokuBoard"`

---

### Task 6: Pass matchingCandidates from GameScreen to SudokuBoard

**Files:**
- Modify: `lib/screens/game_screen.dart` (update SudokuBoard props)

**Step 1: Find SudokuBoard instantiations**

Run: `grep -n "SudokuBoard(" lib/screens/game_screen.dart`
Expected: Two locations (wide and narrow layouts)

**Step 2: Update both SudokuBoard calls**

For both instances, add:

```dart
                SudokuBoard(
                  board: _board,
                  isGiven: _isGiven,
                  isError: _isError,
                  selectedRow: _selectedRow,
                  selectedCol: _selectedCol,
                  isPaused: _isPaused,
                  onCellTap: _onCellTap,
                  strategyHighlight: _strategyHighlight,
                  candidates: _candidates,
                  matchingCandidates: _getSelectedCellCandidates(),  // ADD THIS
                ),
```

**Step 3: Add _getSelectedCellCandidates helper method**

Add to `_GameScreenState`:

```dart
  Set<int>? _getSelectedCellCandidates() {
    if (_selectedRow < 0 || _selectedCol < 0) return null;
    return _candidates[(_selectedRow, _selectedCol)];
  }
```

**Step 4: Run analyze**

Run: `flutter analyze`
Expected: No errors

**Step 5: Commit**

Run: `git add lib/screens/game_screen.dart && git commit -m "feat: pass matching candidates to SudokuBoard"`

---

### Task 7: Add Playwright test and verify

**Files:**
- Create: `test/feature_test.dart` (or add to existing)

**Step 1: Build the app**

Run: `flutter build web`

**Step 2: Serve and test with Playwright**

Use the Playwright MCP tools to verify:
1. Number pad buttons are enabled by default
2. When all 9 of a digit are placed, the button becomes disabled
3. When selecting an empty cell with pencil marks, matching pencil marks are highlighted

---

### Summary

| Task | Description |
|------|-------------|
| 1 | Update NumberPad with disabledDigits prop |
| 2 | Add _fillCell method and _completedDigits state |
| 3 | Update hint logic to use _fillCell |
| 4 | Pass _completedDigits to NumberPad |
| 5 | Add matchingCandidates to SudokuBoard |
| 6 | Pass matchingCandidates from GameScreen |
| 7 | Test with Playwright |
