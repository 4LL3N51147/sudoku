# User-Confirmed Hint Animation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Change the hint animation from timed delays to user-confirmed steps. Each phase waits for the user to tap "Next" before advancing.

**Architecture:** Add a `_hintPhase` field to track current phase (null/0/1/2). Add a Next button to the hint banner. Replace `Future.delayed` calls with a new `_advanceHintPhase()` method that advances through phases on button tap.

**Tech Stack:** Flutter 3.x / Dart 3.x. Use `flutter analyze` to verify correctness.

---

### Task 1: Add `_hintPhase` field and update state

**Files:**
- Modify: `lib/screens/game_screen.dart`

**Step 1: Add `_hintPhase` field**

After `String? _hintMessage;` (line ~35), add:

```dart
int? _hintPhase; // null = no hint, 0 = scan, 1 = elimination, 2 = target
```

**Step 2: Reset `_hintPhase` in `_newGame()`**

After `_hintMessage = null;` in `_newGame()`, add:

```dart
_hintPhase = null;
```

**Step 3: Analyze**

```bash
flutter analyze
```

Expected: no new errors.

**Step 4: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "refactor(hint): add _hintPhase field to track animation progress"
```

---

### Task 2: Add `_advanceHintPhase()` method

**Files:**
- Modify: `lib/screens/game_screen.dart`

**Step 1: Add the method after `_runHiddenSingleHint()`**

The method needs access to the `HiddenSingleResult` — we'll store it in a field temporarily. First add a field:

After `_hintPhase` field, add:

```dart
HiddenSingleResult? _currentHintResult;
```

**Step 2: Add `_advanceHintPhase()` method**

Add this method after `_runHiddenSingleHint()`:

```dart
void _advanceHintPhase() {
  if (_hintPhase == null) return; // no hint active
  if (_isPaused || _isCompleted) return;

  final result = _currentHintResult;
  if (result == null) return;

  if (_hintPhase! < 2) {
    // Advance to next phase
    setState(() {
      _hintPhase = _hintPhase! + 1;
      final unitLabel = switch (result.unitType) {
        UnitType.row => 'row',
        UnitType.column => 'column',
        UnitType.box => 'box',
      };

      if (_hintPhase == 1) {
        // Elimination phase
        _hintMessage =
            'These filled cells prevent ${result.digit} from going elsewhere in this $unitLabel';
        _strategyHighlight = StrategyHighlight(
          phase: StrategyPhase.elimination,
          unitCells: result.unitCells,
          eliminatorCells: result.eliminatorCells,
          unitType: result.unitType,
        );
      } else if (_hintPhase == 2) {
        // Target phase
        _hintMessage =
            '${result.digit} has only one valid cell left in this $unitLabel!';
        _strategyHighlight = StrategyHighlight(
          phase: StrategyPhase.target,
          unitCells: result.unitCells,
          eliminatorCells: result.eliminatorCells,
          targetCell: (result.row, result.col),
          unitType: result.unitType,
        );
      }
    });
  } else {
    // Phase 2 complete - fill the cell
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
      _strategyHighlight = null;
      _hintMessage = null;
      _hintPhase = null;
      _currentHintResult = null;
      _isAnimating = false;
      _selectedRow = result.row;
      _selectedCol = result.col;
      if (_checkWin()) {
        _isCompleted = true;
        _timer?.cancel();
      }
    });
    if (_isCompleted) _showWinDialog();
  }
}
```

**Step 3: Update `_runHiddenSingleHint()` to set up phase 0 and return early**

Replace the current `_runHiddenSingleHint()` body to just set up Phase 0 and store the result:

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

  _currentHintResult = result;
  final unitLabel = switch (result.unitType) {
    UnitType.row => 'row',
    UnitType.column => 'column',
    UnitType.box => 'box',
  };

  // Phase 0 — scan: highlight the unit
  setState(() {
    _isAnimating = true;
    _hintPhase = 0;
    _hintMessage =
        'Scanning this $unitLabel — looking for digit ${result.digit}';
    _strategyHighlight = StrategyHighlight(
      phase: StrategyPhase.scan,
      unitCells: result.unitCells,
      unitType: result.unitType,
    );
  });
}
```

**Step 4: Analyze**

```bash
flutter analyze
```

Expected: no new errors.

**Step 5: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "refactor(hint): add _advanceHintPhase and refactor to user-driven flow"
```

---

### Task 3: Add Next button to hint banner

**Files:**
- Modify: `lib/screens/game_screen.dart`

**Step 1: Update `_buildHintBanner` to include a Next button**

Replace the current `_buildHintBanner` method:

```dart
Widget _buildHintBanner(String message) {
  final bool hasNextButton = _hintPhase != null && _hintPhase! < 2;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1A237E), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: Color(0xFF1A237E), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A237E),
              ),
            ),
          ),
          if (hasNextButton) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: (_isPaused || _isAnimating || _isCompleted)
                  ? null
                  : _advanceHintPhase,
              child: const Text(
                'Next \u2192',
                style: TextStyle(
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
```

**Step 2: Analyze**

```bash
flutter analyze
```

Expected: no new errors.

**Step 3: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "refactor(hint): add Next button to hint banner"
```

---

### Task 4: Clean up — remove unused animation duration settings reference

**Files:**
- Modify: `lib/screens/game_screen.dart`

**Step 1: Check if `_settings` is still used**

The `_settings` is used for animation durations. Since we're removing the timed delays, we can check if it's still needed elsewhere. Currently it might only be used in `_runHiddenSingleHint` which we've refactored. If nothing else uses it, it can stay but won't affect hint behavior.

For now, just verify the build works:

```bash
flutter analyze
```

Expected: no errors.

**Step 2: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "refactor(hint): complete user-confirmed animation flow"
```
