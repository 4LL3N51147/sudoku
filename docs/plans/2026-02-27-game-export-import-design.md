# Sudoku Game State Export/Import Design

**Date:** 2026-02-27
**Feature:** Game State Export/Import

## Overview

Add the ability to export the current game state to a JSON file and import it later to continue playing. This enables sharing puzzles, saving progress, and cloud sync capabilities.

## Data Model

### Exported JSON Structure

```json
{
  "version": 1,
  "difficulty": "easy",
  "elapsedSeconds": 123,
  "board": [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    ...
  ],
  "solution": [
    [5, 3, 4, 6, 7, 8, 9, 1, 2],
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    ...
  ],
  "isGiven": [
    [true, true, false, false, true, false, false, false, false],
    [true, false, false, true, true, true, false, false, false],
    ...
  ],
  "isError": [
    [false, false, false, false, false, false, false, false, false],
    ...
  ],
  "undoStack": [
    {"row": 0, "col": 2, "oldValue": 0, "newValue": 1},
    {"row": 1, "col": 4, "oldValue": 0, "newValue": 9},
    ...
  ],
  "savedAt": "2026-02-27T10:30:00.000Z"
}
```

### Version Field

- `version`: Integer starting at 1
- Allows future format changes without breaking backward compatibility

### Fields

| Field | Type | Description |
|-------|------|-------------|
| version | int | Format version for compatibility |
| difficulty | string | "easy", "medium", or "hard" |
| elapsedSeconds | int | Timer value in seconds |
| board | 9x9 int array | Current board state (0 = empty) |
| solution | 9x9 int array | Solution grid |
| isGiven | 9x9 bool array | Which cells were originally given |
| isError | 9x9 bool array | Current error state |
| undoStack | array | Move history for undo feature |
| savedAt | ISO8601 string | When the game was saved |

## User Interface

### Export Flow

1. User taps "Share" icon button in game header (between timer and lightbulb)
2. System shows native share sheet with JSON file
3. File named `sudoku-{difficulty}-{timestamp}.sudoku`

### Import Flow

**Option A: Continue Button**
- On difficulty screen, add "Continue" button alongside difficulty buttons
- Opens file picker to select .sudoku file

**Option B: File Picker**
- In settings or menu, add "Import Game" option
- Opens system file picker filtered to .sudoku files

**Option C: Clipboard Paste**
- On difficulty screen, check clipboard on app resume/focus
- If valid JSON detected, show toast prompt "Import saved game?"

### UI Components

- Share button: Icon in header (Icons.share_outlined)
- Continue button: Outlined button on difficulty screen
- Import option in settings: ListTile with file picker

## Architecture

### New Files

1. `lib/logic/game_state.dart` — Serialization logic
   - `GameState` class with all fields
   - `toJson()` method
   - `fromJson()` factory constructor
   - `toFile()` and `fromFile()` helpers

2. `lib/logic/export_service.dart` — Platform-specific export
   - `ExportService` abstract class
   - `WebExportService` implementation using File System Access API
   - Fallback: Copy to clipboard

3. `lib/logic/import_service.dart` — Platform-specific import
   - `ImportService` abstract class
   - `WebImportService` implementation

### Modified Files

1. `lib/screens/game_screen.dart`
   - Add share button to header
   - Add `_exportGame()` method
   - Load state from GameState instead of generating new

2. `lib/screens/difficulty_screen.dart`
   - Add "Continue" button
   - Add import handling

3. `lib/main.dart`
   - Route handling for imported game state

## Error Handling

| Scenario | Handling |
|----------|----------|
| Invalid JSON | Show snackbar "Invalid game file" |
| Wrong version | Show snackbar "Game file is from newer version" |
| Corrupted board | Show snackbar "Game file is corrupted" |
| No file selected | Cancel silently |

## Testing Strategy

1. Unit tests for GameState serialization
2. Test edge cases: empty board, full board, invalid JSON
3. Manual testing of export/import flow in browser

## Future Considerations

- Add cloud sync via Firebase/Supabase
- Add password protection for exported files
- Support for sharing via QR code
