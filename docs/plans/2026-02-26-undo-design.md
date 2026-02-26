# Undo Feature Design

**Date:** 2026-02-26

## Overview

Add an undo button to the game header that lets players step back through their moves one at a time. Both manual entries and hint-filled cells are undoable.

## Approach: Delta/Move Record

Each write to the board pushes a `_Move` record onto a stack. Undo pops the top record and writes the old value back.

### Data Model

```dart
typedef _Move = ({int row, int col, int oldValue, int newValue});
List<_Move> _undoStack = [];
```

### Write Sites

Three places push to the stack:

1. `_onNumberInput` — captures `_board[row][col]` as `oldValue` before writing the new digit
2. `_onErase` — same; `newValue` is always 0
3. `_runHiddenSingleHint` — pushes after the animation fills the target cell (oldValue: 0, newValue: digit)

### `_undo()` Method

- If stack is empty, return (button is disabled anyway)
- Pop the top `_Move`
- Write `move.oldValue` back to `_board[move.row][move.col]`
- Call `_updateErrors()` to revalidate
- Set `_selectedRow` / `_selectedCol` to the undone cell

### UI

`IconButton(Icons.undo)` added to `_buildHeader()`, positioned between the back arrow and the title.

Disabled when: `_undoStack.isEmpty || _isPaused || _isAnimating || _isCompleted`

### Edge Cases

- Stack cleared in `_newGame()`
- Undo blocked during hint animation via existing `_isAnimating` guard
- No redo (out of scope)
