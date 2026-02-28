# Pencil Mode and Hint UI Design

**Date:** 2026-02-28
**Features:** Pencil Mode Toggle, Hint UI Spacing

## Overview

Add pencil mode for marking candidate numbers, and reserve space for hint banner to prevent UI jumping.

## Pencil Mode

### Behavior
- Toggle button in game header (pencil icon)
- Off by default (current behavior)
- When enabled, tap a number to add as pencil mark instead of filling cell
- Pencil marks displayed differently from filled numbers (smaller, lighter, or corner notation)

### UI
- Icon button with pencil/pencil_outlined icon
- Visual indicator when pencil mode is active (filled vs outline, or color change)
- Position: In header near settings or lightbulb

### Data Model
- Add `pencilMarks` field: `List<List<Set<int>>>` - 9x9 grid of sets of integers
- Modify GameState to include pencil marks in export/import

## Hint UI Spacing

### Problem
Currently: `if (_hintMessage != null) _buildHintBanner()` causes layout shift when hint appears.

### Solution
- Always render hint banner container with fixed height
- Background color matches page background (Color(0xFFF5F5F5))
- When no hint: shows empty space with consistent spacing
- When hint active: shows message with Next button

### Layout
```
[Header]
[SizedBox(height: 12)]         // Existing spacing
[SudokuBoard]                  // Board
[SizedBox(height: 8)]           // Existing spacing
[HintBanner (fixed height)]    // Always visible, 60px height
[SizedBox(height: 8)]           // Existing spacing
[NumberPad]
[SizedBox(height: 12)]
```

## Files to Modify

1. `lib/screens/game_screen.dart`
   - Add `_isPencilMode` state
   - Add pencil marks tracking (`List<List<Set<int>>>`)
   - Add pencil toggle button in header
   - Modify `_onNumberInput` to handle pencil mode
   - Always render hint banner placeholder

2. `lib/widgets/sudoku_board.dart`
   - Display pencil marks in cells (smaller, corner position)

3. `lib/logic/game_state.dart`
   - Add pencilMarks field to serialization

4. `lib/screens/difficulty_screen.dart` (if needed for export/import)
