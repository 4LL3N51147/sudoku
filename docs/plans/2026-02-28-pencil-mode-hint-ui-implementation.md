# Pencil Mode and Hint UI Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add pencil mode toggle for marking candidate numbers, and reserve space for hint banner to prevent UI jumping.

**Architecture:** Add pencil mode state and toggle button in game screen. Pencil marks stored as `List<List<Set<int>>>` in game state. Hint banner always rendered with fixed height to prevent layout shift.

**Tech Stack:** Flutter/Dart, StatefulWidget state management

---

### Task 1: Add pencil mode state and toggle button to GameScreen

**Files:**
- Modify: `lib/screens/game_screen.dart`

**Step 1: Add pencil mode state**

Find the state fields (around line 29-39) and add:
```dart
bool _isPencilMode = false;
late List<List<Set<int>>> _pencilMarks;
```

**Step 2: Initialize pencil marks in _newGame**

In `_newGame()` method, after `_isError` initialization, add:
```dart
_pencilMarks = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
```

Also handle in the initialState case:
```dart
_pencilMarks = state.pencilMarks.map((row) =>
  row.map((cell) => Set<int>.from(cell)).toList()
).toList();
```

**Step 3: Add toggle method**

Add after `_exportGame()`:
```dart
void _togglePencilMode() {
  setState(() => _isPencilMode = !_isPencilMode);
}
```

**Step 4: Add pencil toggle button in header**

In `_buildHeader()`, add after settings button (around line 530-535):
```dart
IconButton(
  icon: Icon(_isPencilMode ? Icons.edit : Icons.edit_outlined),
  onPressed: (_isPaused || _isAnimating || _isCompleted)
      ? null
      : _togglePencilMode,
  color: _isPencilMode ? const Color(0xFFFF9800) : const Color(0xFF1A237E),
  iconSize: 26,
),
```

**Step 5: Modify _onNumberInput to handle pencil mode**

Replace current `_onNumberInput` logic:
```dart
void _onNumberInput(int num) {
  if (_isPaused || _isAnimating || _isCompleted) return;
  if (_selectedRow < 0 || _selectedCol < 0) return;
  if (_isGiven[_selectedRow][_selectedCol]) return;

  if (_isPencilMode) {
    // Toggle pencil mark
    setState(() {
      final marks = _pencilMarks[_selectedRow][_selectedCol];
      if (marks.contains(num)) {
        marks.remove(num);
      } else {
        marks.add(num);
      }
    });
  } else {
    // Existing fill logic
    if (_board[_selectedRow][_selectedCol] == num) return;
    // ... rest of existing code
  }
}
```

**Step 6: Modify _onErase to also clear pencil marks**

In `_onErase()`, add after clearing board value:
```dart
_pencilMarks[_selectedRow][_selectedCol].clear();
```

**Step 7: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors (may have info-level hints)

**Step 8: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "feat(pencil): add pencil mode toggle

- Add _isPencilMode state and _pencilMarks tracking
- Add toggle button in header with edit icon
- Modify input to toggle pencil marks when enabled
- Pencil marks stored as Set<int> per cell

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 2: Display pencil marks in SudokuBoard

**Files:**
- Modify: `lib/widgets/sudoku_board.dart`

**Step 1: Add pencilMarks parameter**

Add to SudokuBoard constructor (around line 4-24):
```dart
final List<List<Set<int>>> pencilMarks;
```

Add to const constructor:
```dart
const SudokuBoard({
  // ... existing fields ...
  this.pencilMarks = const [],
});
```

**Step 2: Modify cell rendering to show pencil marks**

In `_buildCell()`, find where the value is rendered (around line 167-178). Replace the `child: Center(...)` section to show both value and pencil marks:

```dart
child: Stack(
  children: [
    // Main number or empty
    Center(
      child: value == 0
          ? null
          : Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: given ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
    ),
    // Pencil marks (top-left corner, smaller)
    if (pencilMarks.isNotEmpty && pencilMarks[row][col].isNotEmpty)
      Positioned(
        top: 2,
        left: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int r = 0; r < 3; r++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int c = 0; c < 3; c++)
                    SizedBox(
                      width: 8,
                      height: 10,
                      child: Text(
                        '${r * 3 + c + 1}',
                        style: TextStyle(
                          fontSize: 7,
                          color: pencilMarks[row][col].contains(r * 3 + c + 1)
                              ? Colors.grey[600]
                              : Colors.transparent,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
  ],
),
```

**Step 3: Update GameScreen to pass pencilMarks**

In `game_screen.dart` build method, update SudokuBoard:
```dart
SudokuBoard(
  // ... existing props ...
  pencilMarks: _pencilMarks,
),
```

**Step 4: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors

**Step 5: Commit**

```bash
git add lib/widgets/sudoku_board.dart lib/screens/game_screen.dart
git commit -m "feat(pencil): display pencil marks in cells

- Add pencilMarks parameter to SudokuBoard
- Show pencil marks as small numbers in top-left corner
- Pass pencilMarks from GameScreen to SudokuBoard

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 3: Add hint banner placeholder to prevent UI jumping

**Files:**
- Modify: `lib/screens/gameStep 1: Replace conditional_screen.dart`

** hint banner with placeholder**

Find the build method (around line 471-472):
```dart
if (_hintMessage != null) _buildHintBanner(_hintMessage!),
const SizedBox(height: 8),
```

Replace with:
```dart
// Hint banner placeholder - always rendered to prevent layout shift
_buildHintBannerPlaceholder(),
const SizedBox(height: 8),
```

**Step 2: Create placeholder method**

Add new method after `_buildHintBanner`:
```dart
Widget _buildHintBannerPlaceholder() {
  // Always reserve space with page background color
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Container(
      height: 60, // Fixed height matching hint banner
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Same as page background
        borderRadius: BorderRadius.circular(10),
      ),
      child: _hintMessage != null
          ? _buildHintBanner(_hintMessage!)
          : const SizedBox(), // Empty space when no hint
    ),
  );
}
```

**Step 3: Remove the SizedBox(height: 8) after conditional**

The placeholder now has fixed height, so we may need to adjust spacing.

**Step 4: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors

**Step 5: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "fix(ui): reserve space for hint banner

- Always render hint banner container with fixed height
- Background matches page color to prevent visual jump
- Empty when no hint, shows message when active

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 4: Add pencil marks to GameState serialization

**Files:**
- Modify: `lib/logic/game_state.dart`

**Step 1: Add pencilMarks field**

Add field after `isError`:
```dart
final List<List<Set<int>>> pencilMarks;
```

Update constructor:
```dart
GameState({
  // ... existing fields ...
  this.pencilMarks = const [],
});
```

**Step 2: Update toJson**

Add to toJson():
```dart
'pencilMarks': pencilMarks.map((row) =>
  row.map((cell) => cell.toList()).toList()
).toList(),
```

**Step 3: Update fromJson**

Add to fromJson():
```dart
pencilMarks: _parsePencilMarksFromJson(json['pencilMarks'] as List?),
```

Add helper method:
```dart
static List<List<Set<int>>> _parsePencilMarksFromJson(List<dynamic>? json) {
  if (json == null) {
    return List.generate(9, (_) => List.generate(9, (_) => <int>{}));
  }
  return json.map((row) =>
    (row as List<dynamic>).map((cell) =>
      (cell as List<dynamic>).map((e) => e as int).toSet()
    ).toList()
  ).toList();
}
```

**Step 4: Update GameScreen to handle pencil marks in import**

In `_newGame()`, update initialState handling:
```dart
if (widget.initialState != null) {
  // ... existing code ...
  _pencilMarks = widget.initialState!.pencilMarks.map((row) =>
    row.map((cell) => Set<int>.from(cell)).toList()
  ).toList();
}
```

**Step 5: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors

**Step 6: Commit**

```bash
git add lib/logic/game_state.dart lib/screens/game_screen.dart
git commit -m "feat(export): include pencil marks in game state

- Add pencilMarks field to GameState serialization
- Handle pencil marks in import flow

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 5: Test the features

**Step 1: Build and test**

```bash
flutter build web
python3 -m http.server 8080 --directory build/web
```

**Step 2: Manual testing**
- Pencil mode: Toggle pencil mode, add marks to cells, verify display
- Erase pencil: Select cell with pencil marks, tap erase, verify cleared
- Hint UI: Trigger hint, verify no layout jump
- Export/Import: Export game with pencil marks, import, verify restored

**Step 3: Run tests**

```bash
flutter test
```

Expected: All tests pass

**Step 4: Commit**

```bash
git commit -m "test: verify pencil mode and hint UI features

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Pencil mode state & toggle | game_screen.dart |
| 2 | Display pencil marks | sudoku_board.dart, game_screen.dart |
| 3 | Hint UI placeholder | game_screen.dart |
| 4 | GameState serialization | game_state.dart, game_screen.dart |
| 5 | Testing | - |

**Estimated time:** 30-45 minutes
