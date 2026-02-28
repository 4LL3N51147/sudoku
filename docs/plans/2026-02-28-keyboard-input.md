# Keyboard Input Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Allow users to fill in numbers via keyboard (select cell, then type 1-9) and provide keyboard shortcuts for main control buttons.

**Architecture:** Wrap the game screen with a Focus widget and use KeyboardListener to capture key events. Map numeric keys to number input, and modifier+letter combos to game actions.

**Tech Stack:** Flutter, RawKeyboardListener/KeyboardListener

---

### Task 1: Add keyboard listener and focus to GameScreen

**Files:**
- Modify: `lib/screens/game_screen.dart:1-30` (imports)
- Modify: `lib/screens/game_screen.dart:~350` (build method)

**Step 1: Write the failing test**

This is a UI feature - no unit test needed. We'll verify with `flutter analyze`.

**Step 2: Add KeyboardListener import**

```dart
import 'package:flutter/services.dart';
```

**Step 3: Wrap build method with Focus and KeyboardListener**

In the `build` method, wrap the Scaffold with:
```dart
return Focus(
  autofocus: true,
  child: KeyboardListener(
    focusNode: FocusNode(),
    onKeyEvent: _handleKeyEvent,
    child: Scaffold(...)),
);
```

Actually, we need to add a FocusNode to the state class and manage it properly:
```dart
late final FocusNode _focusNode;

@override
void initState() {
  super.initState();
  _focusNode = FocusNode();
}

@override
void dispose() {
  _focusNode.dispose();
  super.dispose();
}
```

Then in build:
```dart
return Focus(
  focusNode: _focusNode,
  autofocus: true,
  child: KeyboardListener(
    focusNode: _focusNode,
    onKeyEvent: _handleKeyEvent,
    child: Scaffold(...),
  ),
);
```

**Step 4: Verify with flutter analyze**

```bash
flutter analyze lib/screens/game_screen.dart
```
Expected: No errors

**Step 5: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "feat: add Focus and KeyboardListener for keyboard input"
```

---

### Task 2: Implement _handleKeyEvent method

**Files:**
- Modify: `lib/screens/game_screen.dart:~170` (after _undo method)

**Step 1: Write the handler method**

Add this method after `_undo()`:

```dart
void _handleKeyEvent(KeyEvent event) {
  if (event is! KeyDownEvent) return;
  if (_isAnimating) return;

  final key = event.logicalKey;

  // Number keys 1-9
  if (LogicalKeyboardKey.digit1 <= key && key <= LogicalKeyboardKey.digit9) {
    final num = int.parse(key.keyLabel);
    _onNumberInput(num);
    return;
  }

  // Numpad keys 1-9
  if (LogicalKeyboardKey.numpad1 <= key && key <= LogicalKeyboardKey.numpad9) {
    final num = key.keyLabel == '1' ? 1 :
                key.keyLabel == '2' ? 2 :
                key.keyLabel == '3' ? 3 :
                key.keyLabel == '4' ? 4 :
                key.keyLabel == '5' ? 5 :
                key.keyLabel == '6' ? 6 :
                key.keyLabel == '7' ? 7 :
                key.keyLabel == '8' ? 8 : 9;
    _onNumberInput(num);
    return;
  }

  // Erase: Backspace or Delete
  if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
    _onErase();
    return;
  }

  // Shortcuts (require no modifier or specific modifier)
  final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

  // Ctrl+Z: Undo
  if (isCtrlPressed && key == LogicalKeyboardKey.keyZ) {
    _undo();
    return;
  }

  // P: Pencil mode toggle
  if (key == LogicalKeyboardKey.keyP && !isCtrlPressed) {
    _togglePencilMode();
    return;
  }

  // H: Hint
  if (key == LogicalKeyboardKey.keyH && !isCtrlPressed) {
    _showHint();
    return;
  }

  // Space: Pause
  if (key == LogicalKeyboardKey.space && !isCtrlPressed) {
    _togglePause();
    return;
  }

  // Ctrl+S: Export
  if (isCtrlPressed && key == LogicalKeyboardKey.keyS) {
    _exportGame();
    return;
  }
}
```

Note: For numpad, we need to extract the number from keyLabel differently since it might be '1' instead of 'numpad1'.

Actually, a cleaner approach for numpad:
```dart
// Numpad keys 1-9
if (key == LogicalKeyboardKey.numpad1 ||
    key == LogicalKeyboardKey.numpad2 ||
    key == LogicalKeyboardKey.numpad3 ||
    key == LogicalKeyboardKey.numpad4 ||
    key == LogicalKeyboardKey.numpad5 ||
    key == LogicalKeyboardKey.numpad6 ||
    key == LogicalKeyboardKey.numpad7 ||
    key == LogicalKeyboardKey.numpad8 ||
    key == LogicalKeyboardKey.numpad9) {
  final num = switch (key) {
    LogicalKeyboardKey.numpad1 => 1,
    LogicalKeyboardKey.numpad2 => 2,
    LogicalKeyboardKey.numpad3 => 3,
    LogicalKeyboardKey.numpad4 => 4,
    LogicalKeyboardKey.numpad5 => 5,
    LogicalKeyboardKey.numpad6 => 6,
    LogicalKeyboardKey.numpad7 => 7,
    LogicalKeyboardKey.numpad8 => 8,
    LogicalKeyboardKey.numpad9 => 9,
    _ => 0,
  };
  _onNumberInput(num);
  return;
}
```

**Step 2: Verify with flutter analyze**

```bash
flutter analyze lib/screens/game_screen.dart
```
Expected: No errors (may have hints about unused import)

**Step 3: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "feat: add keyboard event handler for numbers and shortcuts"
```

---

### Task 3: Test keyboard input manually

**Step 1: Build for web**

```bash
flutter build web
```

**Step 2: Serve locally**

```bash
python3 -m http.server 8080 --directory build/web
```

**Step 3: Manual test**

- Click a cell, then press 1-9 on keyboard
- Press Backspace/Delete to erase
- Press P to toggle pencil mode
- Press H for hint
- Press Space to pause
- Press Ctrl+Z to undo
- Press Ctrl+S to export

Expected: All keyboard inputs work as expected

**Step 4: Commit**

```bash
git add .gitignore  # if build directory added
git commit -m "test: verify keyboard input works"
```

---

### Task 4: Final review and merge

**Step 1: Run flutter analyze**

```bash
flutter analyze
```
Expected: No errors

**Step 2: Commit**

```bash
git add .
git commit -m "feat: add keyboard input and shortcuts"
```
