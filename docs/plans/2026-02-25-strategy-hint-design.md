# Strategy Hint Feature — Design Doc

Date: 2026-02-25

## Overview

Add a strategy hint system to the Sudoku game. The user opens a bottom sheet to select a solving strategy. The app checks the current board, and if the strategy applies, runs a multi-phase animated demonstration that highlights the relevant cells and then auto-fills the answer. Only Hidden Single is implemented in this iteration.

---

## Data Model

### `lib/logic/strategy_solver.dart` (new file)

```dart
enum StrategyPhase { none, scan, elimination, target }

class HiddenSingleResult {
  final int row, col, digit;
  final Set<(int, int)> unitCells;       // all 9 cells in the unit
  final Set<(int, int)> eliminatorCells; // existing filled cells that block other positions
}

class StrategyHighlight {
  final StrategyPhase phase;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final (int, int)? targetCell;
}
```

### Detection: `findHiddenSingle(List<List<int>> board) → HiddenSingleResult?`

Scan order: rows → columns → boxes.

For each unit, for each digit 1–9 not already placed in the unit:
- Collect all empty cells in the unit where the digit is still legal (not blocked by its row, column, or box).
- If exactly one cell is legal → return a `HiddenSingleResult` with:
  - `row`, `col`, `digit`: the target cell and value
  - `unitCells`: all 9 cells of the unit
  - `eliminatorCells`: for every other cell in the unit where the digit is blocked, the existing cell(s) in the same row/col/box that cause the block

Return `null` if no hidden single exists anywhere on the board.

---

## Animation Sequence

Orchestrated in `GameScreen._runHiddenSingleHint()` (async):

| Phase | Duration | Board state | Purpose |
|-------|----------|-------------|---------|
| Pre-check | — | unchanged | Call `findHiddenSingle`; show snackbar and return if `null` |
| 1 — Scan | 800ms | `unitCells` highlighted light blue | "We're examining this unit" |
| 2 — Elimination | 1200ms | `eliminatorCells` highlighted amber | "These numbers block other positions" |
| 3 — Target | 800ms | target cell highlighted green | "Only this cell can hold the digit" |
| Fill | — | number placed, highlights cleared | Auto-fill via existing `_onNumberInput` |

The game timer is paused for the duration of the animation and resumed after fill.

---

## Cell Color Priority (during animation)

```
target green > eliminator amber > unit scan blue > normal selection > white
```

Strategy highlight overrides the normal row/col/box selection highlight so the board is visually unambiguous during the demo.

### Colors

| Role | Color | Hex |
|------|-------|-----|
| Unit scan | Light blue | `0xFFE3F2FD` |
| Eliminator | Amber | `0xFFFFE0B2` |
| Target | Light green | `0xFFC8E6C9` |

---

## UI Changes

### Game Screen Header

Add a `lightbulb_outline` icon button to the right of the pause button. Tapping it opens the strategy picker bottom sheet.

### Strategy Picker Bottom Sheet

`showModalBottomSheet` with:
- Title: *"Choose a Strategy"*
- `ListTile` for **Hidden Single**: subtitle *"Find a digit that can only go in one cell within a row, column, or box"*
- Tapping closes the sheet and triggers the animation

### `SudokuBoard` Widget

Add one new optional parameter:
```dart
StrategyHighlight? strategyHighlight
```

In `_buildCell`, check the strategy highlight after the existing color logic and override where applicable.

---

## Files Changed

| File | Change |
|------|--------|
| `lib/logic/strategy_solver.dart` | New — detection logic + data classes |
| `lib/screens/game_screen.dart` | Add button, bottom sheet, animation orchestration |
| `lib/widgets/sudoku_board.dart` | Add `strategyHighlight` param + color priority logic |
