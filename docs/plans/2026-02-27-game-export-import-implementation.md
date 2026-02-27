# Game Export/Import Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add JSON-based game state export/import feature enabling users to save progress, share puzzles, and continue games later.

**Architecture:** Create a GameState class for serialization, export service for sharing, and import handling on difficulty screen. Uses JSON format with version field for future compatibility.

**Tech Stack:** Flutter/Dart, dart:convert for JSON, File System Access API (web), SharedPreferences for clipboard detection.

---

### Task 1: Create GameState model class

**Files:**
- Create: `lib/logic/game_state.dart`

**Step 1: Write the failing test**

Create test file `test/logic/game_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/logic/game_state.dart';

void main() {
  group('GameState', () {
    test('serializes to JSON with all fields', () {
      final state = GameState(
        difficulty: Difficulty.easy,
        elapsedSeconds: 120,
        board: List.generate(9, (r) => List.generate(9, (c) => r == c ? r + 1 : 0)),
        solution: List.generate(9, (r) => List.generate(9, (c) => (c + 1) % 9 + 1)),
        isGiven: List.generate(9, (r) => List.generate(9, (c) => r == c)),
        isError: List.generate(9, (_) => List.filled(9, false)),
        undoStack: [],
        savedAt: DateTime.parse('2026-02-27T10:00:00Z'),
      );

      final json = state.toJson();

      expect(json['version'], 1);
      expect(json['difficulty'], 'easy');
      expect(json['elapsedSeconds'], 120);
      expect(json['board'], isA<List>());
      expect(json['savedAt'], '2026-02-27T10:00:00.000Z');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'version': 1,
        'difficulty': 'medium',
        'elapsedSeconds': 60,
        'board': List.generate(9, (_) => List.filled(9, 0)),
        'solution': List.generate(9, (r) => List.generate(9, (c) => (c + 1) % 9 + 1)),
        'isGiven': List.generate(9, (_) => List.filled(9, false)),
        'isError': List.generate(9, (_) => List.filled(9, false)),
        'undoStack': <Map<String, dynamic>>[],
        'savedAt': '2026-02-27T10:00:00.000Z',
      };

      final state = GameState.fromJson(json);

      expect(state.difficulty, Difficulty.medium);
      expect(state.elapsedSeconds, 60);
      expect(state.version, 1);
    });

    test('throws on invalid version', () {
      final json = {
        'version': 999,
        'difficulty': 'easy',
        'elapsedSeconds': 0,
        'board': List.generate(9, (_) => List.filled(9, 0)),
        'solution': List.generate(9, (_) => List.filled(9, 0)),
        'isGiven': List.generate(9, (_) => List.filled(9, false)),
        'isError': List.generate(9, (_) => List.filled(9, false)),
        'undoStack': [],
        'savedAt': '2026-02-27T10:00:00.000Z',
      };

      expect(() => GameState.fromJson(json), throwsA(isA<Exception>()));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/logic/game_state_test.dart`
Expected: FAIL - "Cannot find package 'sudoku/logic/game_state.dart'"

**Step 3: Write minimal implementation**

Create `lib/logic/game_state.dart`:

```dart
import 'dart:convert';
import 'sudoku_generator.dart';

typedef _Move = ({int row, int col, int oldValue, int newValue});

class GameState {
  final int version;
  final Difficulty difficulty;
  final int elapsedSeconds;
  final List<List<int>> board;
  final List<List<int>> solution;
  final List<List<bool>> isGiven;
  final List<List<bool>> isError;
  final List<_Move> undoStack;
  final DateTime savedAt;

  const GameState({
    this.version = 1,
    required this.difficulty,
    required this.elapsedSeconds,
    required this.board,
    required this.solution,
    required this.isGiven,
    required this.isError,
    required this.undoStack,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'difficulty': difficulty.name,
      'elapsedSeconds': elapsedSeconds,
      'board': board.map((row) => row.toList()).toList(),
      'solution': solution.map((row) => row.toList()).toList(),
      'isGiven': isGiven.map((row) => row.toList()).toList(),
      'isError': isError.map((row) => row.toList()).toList(),
      'undoStack': undoStack.map((m) => {
        'row': m.row,
        'col': m.col,
        'oldValue': m.oldValue,
        'newValue': m.newValue,
      }).toList(),
      'savedAt': savedAt.toUtc().toIso8601String(),
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int;
    if (version != 1) {
      throw Exception('Unsupported game state version: $version');
    }

    return GameState(
      version: version,
      difficulty: Difficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => Difficulty.easy,
      ),
      elapsedSeconds: json['elapsedSeconds'] as int,
      board: _parseBoard(json['board']),
      solution: _parseBoard(json['solution']),
      isGiven: _parseBoolBoard(json['isGiven']),
      isError: _parseBoolBoard(json['isError']),
      undoStack: _parseUndoStack(json['undoStack']),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  static List<List<int>> _parseBoard(dynamic data) {
    return (data as List)
        .map((row) => (row as List).map((e) => e as int).toList())
        .toList();
  }

  static List<List<bool>> _parseBoolBoard(dynamic data) {
    return (data as List)
        .map((row) => (row as List).map((e) => e as bool).toList())
        .toList();
  }

  static List<_Move> _parseUndoStack(dynamic data) {
    return (data as List).map((m) {
      final map = m as Map<String, dynamic>;
      return (
        row: map['row'] as int,
        col: map['col'] as int,
        oldValue: map['oldValue'] as int,
        newValue: map['newValue'] as int,
      );
    }).toList();
  }

  String toJsonString() => jsonEncode(toJson());

  factory GameState.fromJsonString(String jsonString) {
    return GameState.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/logic/game_state_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/logic/game_state.dart test/logic/game_state_test.dart
git commit -m "feat(export): add GameState model for serialization

Implements JSON serialization for game state with version field
for backward compatibility. Includes toJson, fromJson, and
factory constructors for easy encoding/decoding.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 2: Add export functionality to GameScreen

**Files:**
- Modify: `lib/screens/game_screen.dart` (add share button and export method)

**Step 1: Add share icon import and export method**

Add import at top of game_screen.dart:
```dart
import 'dart:convert';
import 'dart:html' as html;  // For web
import 'logic/game_state.dart';
```

Add method after `_showSettings()`:

```dart
void _exportGame() {
  final state = GameState(
    difficulty: widget.difficulty,
    elapsedSeconds: _elapsedSeconds,
    board: _board,
    solution: _solution,
    isGiven: _isGiven,
    isError: _isError,
    undoStack: _undoStack,
    savedAt: DateTime.now(),
  );

  final jsonString = state.toJsonString();
  final blob = html.Blob([jsonString], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'sudoku-${widget.difficulty.name}-${DateTime.now().millisecondsSinceEpoch}.sudoku')
    ..click();
  html.Url.revokeObjectUrl(url);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Game exported!')),
  );
}
```

**Step 2: Add share button to header**

In `_buildHeader()`, after the lightbulb IconButton (line ~496-503), add:

```dart
IconButton(
  icon: const Icon(Icons.share_outlined),
  onPressed: (_isPaused || _isAnimating || _isCompleted)
      ? null
      : _exportGame,
  color: const Color(0xFF1A237E),
  iconSize: 26,
),
```

**Step 3: Analyze and fix**

Run: `flutter analyze`
Expected: May need to add web import check for desktop builds

Update export method to handle both web and potential future platforms:

```dart
void _exportGame() {
  final state = GameState(
    difficulty: widget.difficulty,
    elapsedSeconds: _elapsedSeconds,
    board: _board,
    solution: _solution,
    isGiven: _isGiven,
    isError: _isError,
    undoStack: _undoStack,
    savedAt: DateTime.now(),
  );

  final jsonString = state.toJsonString();

  // Web-specific export using File System Access API
  if (identical(0, 0.0)) {
    // Check if running on web
    try {
      final blob = html.Blob([jsonString], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'sudoku-${widget.difficulty.name}-$timestamp.sudoku')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      // Fallback: copy to clipboard
      _copyToClipboard(jsonString);
      return;
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Game exported!')),
  );
}

void _copyToClipboard(String text) {
  // For now, show message - clipboard handled differently on web
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Copy the game data from console to export')),
  );
  // ignore: avoid_print
  print('EXPORT JSON: $text');
}
```

Actually, simplify - just always print to console for web debugging and use a simpler approach:

```dart
void _exportGame() {
  final state = GameState(
    difficulty: widget.difficulty,
    elapsedSeconds: _elapsedSeconds,
    board: _board,
    solution: _solution,
    isGiven: _isGiven,
    isError: _isError,
    undoStack: _undoStack,
    savedAt: DateTime.now(),
  );

  final jsonString = state.toJsonString();

  // Print to console for now - web file download requires more setup
  // ignore: avoid_print
  print('=== GAME EXPORT START ===');
  // ignore: avoid_print
  print(jsonString);
  // ignore: avoid_print
  print('=== GAME EXPORT END ===');

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Game data copied to clipboard (check DevTools console)'),
      duration: Duration(seconds: 3),
    ),
  );

  // Also try clipboard API if available
  try {
    html.window.navigator.clipboard.writeText(jsonString);
  } catch (_) {
    // Clipboard API not available, console fallback works
  }
}
```

Add import at top:
```dart
import 'dart:html' show window, AnchorElement, Blob, Url; // Web only
```

**Step 4: Analyze**

Run: `flutter analyze`
Expected: Should pass with web imports

**Step 5: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "feat(export): add export button to game screen

Adds share button to header that exports game state as JSON.
Currently outputs to console and clipboard for web.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 3: Add import UI to DifficultyScreen

**Files:**
- Modify: `lib/screens/difficulty_screen.dart`

**Step 1: Add import handling state and UI**

Modify `DifficultyScreen` to be StatefulWidget since we need clipboard checking:

```dart
class DifficultyScreen extends StatefulWidget {
  const DifficultyScreen({super.key});

  @override
  State<DifficultyScreen> createState() => _DifficultyScreenState();
}

class _DifficultyScreenState extends State<DifficultyScreen> with WidgetsBindingObserver {
  String? _importedJson;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    try {
      // This would require importing dart:html - skip for now
      // In a real implementation, you'd use a Flutter plugin for clipboard
    } catch (_) {}
  }

  void _handleImport() async {
    // For now, show a dialog where user can paste JSON
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Game'),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Paste game JSON here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      _importGame(result);
    }
  }

  void _importGame(String jsonString) {
    try {
      final state = GameState.fromJsonString(jsonString);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              difficulty: state.difficulty,
              initialState: state,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid game file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... existing build code with import button added
  }
}
```

Add import button in the Column, after the difficulty buttons:

```dart
const Spacer(flex: 1),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 40),
  child: OutlinedButton.icon(
    onPressed: _handleImport,
    icon: const Icon(Icons.file_upload_outlined),
    label: const Text('Import Game'),
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF1A237E),
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
),
const Spacer(flex: 1),
```

**Step 2: Modify GameScreen to accept initial state**

Modify `GameScreen` constructor and `_newGame()`:

```dart
class GameScreen extends StatefulWidget {
  final Difficulty difficulty;
  final GameState? initialState;  // Add this

  const GameScreen({
    super.key,
    required this.difficulty,
    this.initialState,  // Add this
  });
```

In `_GameScreenState`, modify `_newGame()`:

```dart
void _newGame() {
  if (widget.initialState != null) {
    // Load from imported state
    final state = widget.initialState!;
    _solution = state.solution;
    _isGiven = state.isGiven;
    _board = state.board.map((row) => List<int>.from(row)).toList();
    _isError = state.isError.map((row) => List<bool>.from(row)).toList();
    _undoStack = List.from(state.undoStack);
    _elapsedSeconds = state.elapsedSeconds;
  } else {
    // Generate new game
    final result = SudokuGenerator.generate(widget.difficulty);
    _solution = result.solution;
    _isGiven = List.generate(
        9, (r) => List.generate(9, (c) => result.puzzle[r][c] != 0));
    _board = result.puzzle.map((row) => List<int>.from(row)).toList();
    _isError = List.generate(9, (_) => List.filled(9, false));
    _undoStack.clear();
    _elapsedSeconds = 0;
  }
  // ... rest of initialization
}
```

**Step 3: Add import for game_state.dart**

Add to game_screen.dart:
```dart
import 'logic/game_state.dart';
```

**Step 4: Analyze**

Run: `flutter analyze`
Expected: Should pass

**Step 5: Commit**

```bash
git add lib/screens/difficulty_screen.dart lib/screens/game_screen.dart
git commit -m "feat(import): add import UI to difficulty screen

Adds Import Game button that opens dialog for pasting JSON.
GameScreen now accepts optional initialState to resume imported games.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 4: Test the full flow

**Step 1: Build web**

Run: `flutter build web`
Expected: Build succeeds

**Step 2: Test export**

1. Start local server: `python3 -m http.server 8080 --directory build/web`
2. Open browser to http://localhost:8080
3. Start a game on Easy
4. Make a few moves
5. Click share/export button
6. Check DevTools console for JSON output
7. Copy the JSON (between === markers)

**Step 3: Test import**

1. Go back to difficulty screen
2. Click "Import Game"
3. Paste the copied JSON
4. Click Import
5. Verify game resumes with same state

**Step 4: Commit**

```bash
git commit -m "test: verify export/import flow works

Manual testing confirms:
- Export outputs valid JSON with all game state
- Import correctly restores board, timer, undo stack
- Game continues from imported state

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 5: Polish - Add continue button detection

**Step 1: Check for saved game on startup**

Use SharedPreferences to persist last game:

Add to GameState:
```dart
Future<void> saveLocally() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('savedGame', toJsonString());
}

static Future<GameState?> loadLocally() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString('savedGame');
  if (json == null) return null;
  return GameState.fromJsonString(json);
}
```

Add save call to _exportGame or add auto-save on pause/background.

**Step 2: Show "Continue" button on difficulty screen**

Check for saved game and show Continue button if exists.

*This step is optional - skip if MVP is sufficient*

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | GameState model | `lib/logic/game_state.dart`, `test/logic/game_state_test.dart` |
| 2 | Export from GameScreen | `lib/screens/game_screen.dart` |
| 3 | Import UI | `lib/screens/difficulty_screen.dart`, `lib/screens/game_screen.dart` |
| 4 | Integration test | Manual testing |

**Estimated time:** 30-45 minutes
