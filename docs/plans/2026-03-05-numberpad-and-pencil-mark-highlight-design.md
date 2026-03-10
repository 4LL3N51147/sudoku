# NumberPad and Pencil Mark Highlight Design

## Date: 2026-03-05

## Feature 1: Disable Number Button When Digit Complete

### Problem
Players can tap a number button even when that digit already exists in all 9 blocks, which is useless since there's nowhere valid to place it.

### Solution
Disable number buttons when the digit has already been placed in all 9 blocks.

### Implementation

**State:**
- Add `Set<int> _completedDigits = {}` to `_GameScreenState`

**Unified Fill Interface:**
- Create `_fillCell(int row, int col, int digit)` method that:
  1. Updates `_board[row][col] = digit`
  2. Adds digit to `_completedDigits` if this is the 9th occurrence across all blocks
  3. Adds move to undo stack
  4. Checks for completion
- Both `_onNumberInput()` and hint logic call `_fillCell()` instead of directly setting the board

**NumberPad Changes:**
- Add `Set<int>? disabledDigits` prop
- When provided, render buttons with reduced opacity and ignore taps

## Feature 2: Highlight Matching Pencil Marks

### Problem
When a cell is selected with pencil marks (candidates), it's hard to see which other cells share the same candidate digits.

### Solution
Highlight pencil marks in other cells that match the selected cell's candidates using the same blue color as same-number highlighting.

### Implementation

**SudokuBoard Changes:**
- Add `Set<int>? matchingCandidates` prop
- In `_buildCandidates()`, check if each candidate digit is in `matchingCandidates`
- Apply blue-100 background color to matching candidates

**GameScreen Changes:**
- When a cell is selected, get its candidates from `_candidates`
- Pass those digits as `matchingCandidates` to `SudokuBoard`

## Visual Design

- **Disabled number button:** opacity 0.4, non-interactive
- **Matching candidate highlight:** blue-100 (#BBDEFB) - same as same-number cell highlight
