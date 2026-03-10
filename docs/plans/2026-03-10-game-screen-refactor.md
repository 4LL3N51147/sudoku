# Game Screen Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Split the monolithic `game_screen.dart` (1209 lines) into 4 smaller focused widgets using a feature-based approach with callback passing.

**Architecture:** Keep all state in GameScreen, pass simple callbacks to child widgets. This maintains consistency with existing codebase patterns and minimizes data flow changes.

**Tech Stack:** Flutter 3.x, StatefulWidget, callback pattern

---

## Pre-requisite: Run existing tests to establish baseline

**Step 1: Run all tests to verify baseline**

Run: `flutter test`
Expected: All 44 tests pass

---

## Task 1: Extract GameHeader widget

**Files:**
- Create: `lib/widgets/game_header.dart`
- Modify: `lib/screens/game_screen.dart`

**Step 1: Create game_header.dart with Timer display, difficulty, and pause button**

```dart
import 'package:flutter/material.dart';

class GameHeader extends StatelessWidget {
  final int elapsedSeconds;
  final String difficulty;
  final bool isPaused;
  final VoidCallback onPauseToggle;
  final VoidCallback onNewGame;

  const GameHeader({
    super.key,
    required this.elapsedSeconds,
    required this.difficulty,
    required this.isPaused,
    required this.onPauseToggle,
    required this.onNewGame,
  });

  String get _formattedTime {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAF6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF1A237E)),
              const SizedBox(width: 6),
              Text(
                _formattedTime,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ),
        // Difficulty
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAF6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            difficulty,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A237E),
            ),
          ),
        ),
        // Action buttons
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onNewGame,
              tooltip: 'New game',
              color: const Color(0xFF1A237E),
            ),
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
              onPressed: onPauseToggle,
              tooltip: isPaused ? 'Resume' : 'Pause',
              color: const Color(0xFF1A237E),
            ),
          ],
        ),
      ],
    );
  }
}
```

**Step 2: Add import and replace header section in game_screen.dart build method**

In `lib/screens/game_screen.dart`:
1. Add import: `import '../widgets/game_header.dart';`
2. Find the header section in `_buildHeader` method (lines ~1023-1080) and replace with:
   ```dart
   Widget _buildHeader({required bool isWide}) {
     return GameHeader(
       elapsedSeconds: _elapsedSeconds,
       difficulty: widget.difficulty.name,
       isPaused: _isPaused,
       onPauseToggle: _togglePause,
       onNewGame: _newGame,
     );
   }
   ```

**Step 3: Run tests to verify nothing broke**

Run: `flutter test`
Expected: All 44 tests pass

**Step 4: Commit**

```bash
git add lib/widgets/game_header.dart lib/screens/game_screen.dart
git commit -m "refactor: extract GameHeader widget from game_screen"
```

---

## Task 2: Extract GameBoardContainer widget

**Files:**
- Create: `lib/widgets/game_board_container.dart`
- Modify: `lib/screens/game_screen.dart`

**Step 1: Create game_board_container.dart with board, number pad, and input handling**

```dart
import 'package:flutter/material.dart';
import '../logic/strategy_solver.dart';
import 'sudoku_board.dart';
import 'number_pad.dart';

class GameBoardContainer extends StatelessWidget {
  final List<List<int>> board;
  final List<List<bool>> isGiven;
  final List<List<bool>> isError;
  final int selectedRow;
  final int selectedCol;
  final bool isPaused;
  final bool isAnimating;
  final Map<(int, int), Set<int>> candidates;
  final Set<int>? matchingCandidates;
  final StrategyHighlight? strategyHighlight;
  final void Function(int row, int col) onCellTap;
  final void Function(int num) onNumberInput;
  final VoidCallback onErase;

  const GameBoardContainer({
    super.key,
    required this.board,
    required this.isGiven,
    required this.isError,
    required this.selectedRow,
    required this.selectedCol,
    required this.isPaused,
    required this.isAnimating,
    required this.candidates,
    this.matchingCandidates,
    this.strategyHighlight,
    required this.onCellTap,
    required this.onNumberInput,
    required this.onErase,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return isWide
        ? Row(
            children: [
              Expanded(
                flex: 3,
                child: SudokuBoard(
                  board: board,
                  isGiven: isGiven,
                  isError: isError,
                  selectedRow: selectedRow,
                  selectedCol: selectedCol,
                  isPaused: isPaused,
                  onCellTap: isAnimating ? (_row, _col) {} : onCellTap,
                  strategyHighlight: strategyHighlight,
                  candidates: candidates,
                  matchingCandidates: matchingCandidates,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: NumberPad(
                  onNumberInput: isAnimating ? (_) {} : onNumberInput,
                  onErase: isAnimating ? () {} : onErase,
                ),
              ),
            ],
          )
        : Column(
            children: [
              Expanded(
                child: SudokuBoard(
                  board: board,
                  isGiven: isGiven,
                  isError: isError,
                  selectedRow: selectedRow,
                  selectedCol: selectedCol,
                  isPaused: isPaused,
                  onCellTap: isAnimating ? (_row, _col) {} : onCellTap,
                  strategyHighlight: strategyHighlight,
                  candidates: candidates,
                  matchingCandidates: matchingCandidates,
                ),
              ),
              const SizedBox(height: 16),
              NumberPad(
                onNumberInput: isAnimating ? (_) {} : onNumberInput,
                onErase: isAnimating ? () {} : onErase,
              ),
            ],
          );
  }
}
```

**Step 2: Add import and replace board/numpad section in game_screen.dart**

In `lib/screens/game_screen.dart`:
1. Add import: `import '../widgets/game_board_container.dart';`
2. Find the wide/narrow layout methods `_buildWideLayout` and `_buildNarrowLayout` and replace both with simple call to `GameBoardContainer`

**Step 3: Run tests to verify nothing broke**

Run: `flutter test`
Expected: All 44 tests pass

**Step 4: Commit**

```bash
git add lib/widgets/game_board_container.dart lib/screens/game_screen.dart
git commit -m "refactor: extract GameBoardContainer widget from game_screen"
```

---

## Task 3: Extract HintController widget

**Files:**
- Create: `lib/widgets/hint_controller.dart`
- Modify: `lib/screens/game_screen.dart`

**Step 1: Create hint_controller.dart with hint banner, strategy picker, and hint phase handling**

This widget will contain:
- Hint banner display
- Strategy picker dialog (entire `_showStrategyPicker` method)
- Strategy tile builder (`_strategyTile` method)
- Hint phase advancement logic

```dart
import 'package:flutter/material.dart';
import '../logic/strategy_solver.dart';
import '../app_settings.dart';
import 'hint_banner.dart';

class HintController extends StatelessWidget {
  final StrategyResult? currentStrategyResult;
  final AppSettings settings;
  final StrategyHighlight? strategyHighlight;
  final String? hintMessage;
  final int? hintPhase;
  final bool isAnimating;
  final VoidCallback onHintRequested;
  final VoidCallback onAdvanceHint;
  final VoidCallback onApplyHint;
  final void Function(StrategyType) onStrategySelected;

  const HintController({
    super.key,
    this.currentStrategyResult,
    required this.settings,
    this.strategyHighlight,
    this.hintMessage,
    this.hintPhase,
    required this.isAnimating,
    required this.onHintRequested,
    required this.onAdvanceHint,
    required this.onApplyHint,
    required this.onStrategySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hint banner
        if (hintMessage != null && strategyHighlight != null)
          HintBanner(
            message: hintMessage!,
            phase: hintPhase,
            onNext: isAnimating ? null : onAdvanceHint,
            isLastPhase: hintPhase == 2,
          ),
        // Hint button
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isAnimating ? null : onHintRequested,
          icon: const Icon(Icons.lightbulb_outline),
          label: const Text('Hint'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1A237E),
            side: const BorderSide(color: Color(0xFF1A237E)),
          ),
        ),
      ],
    );
  }

  // Static method for strategy picker dialog (callable from GameScreen)
  static Future<StrategyType?> showStrategyPicker(
    BuildContext context,
    List<StrategyType> availableTypes,
  ) async {
    return showModalBottomSheet<StrategyType>(
      context: context,
      builder: (context) => _StrategyPickerSheet(availableTypes: availableTypes),
    );
  }
}

class _StrategyPickerSheet extends StatelessWidget {
  final List<StrategyType> availableTypes;

  const _StrategyPickerSheet({required this.availableTypes});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Choose Strategy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...availableTypes.map((type) => ListTile(
            title: Text(_strategyName(type)),
            subtitle: Text(_strategyDescription(type)),
            onTap: () => Navigator.pop(context, type),
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _strategyName(StrategyType type) {
    switch (type) {
      case StrategyType.hiddenSingle:
        return 'Hidden Single';
      case StrategyType.nakedPair:
        return 'Naked Pair';
      case StrategyType.hiddenPair:
        return 'Hidden Pair';
      case StrategyType.nakedTriple:
        return 'Naked Triple';
      case StrategyType.hiddenTriple:
        return 'Hidden Triple';
      case StrategyType.nakedQuad:
        return 'Naked Quad';
      case StrategyType.hiddenQuad:
        return 'Hidden Quad';
    }
  }

  String _strategyDescription(StrategyType type) {
    switch (type) {
      case StrategyType.hiddenSingle:
        return 'Find the only place a number can go in a row, column, or box';
      case StrategyType.nakedPair:
        return 'Find two cells with the same two candidates';
      case StrategyType.hiddenPair:
        return 'Find two numbers that can only go in two cells';
      case StrategyType.nakedTriple:
        return 'Find three cells with the same three candidates';
      case StrategyType.hiddenTriple:
        return 'Find three numbers that can only go in three cells';
      case StrategyType.nakedQuad:
        return 'Find four cells with the same four candidates';
      case StrategyType.hiddenQuad:
        return 'Find four numbers that can only go in four cells';
    }
  }
}
```

**Step 2: Add import and integrate HintController in game_screen.dart**

In `lib/screens/game_screen.dart`:
1. Add import: `import '../widgets/hint_controller.dart';`
2. Replace hint-related UI sections with HintController widget

**Step 3: Run tests to verify nothing broke**

Run: `flutter test`
Expected: All 44 tests pass

**Step 4: Commit**

```bash
git add lib/widgets/hint_controller.dart lib/screens/game_screen.dart
git commit -m "refactor: extract HintController widget from game_screen"
```

---

## Task 4: Verify final state

**Step 1: Run all tests**

Run: `flutter test`
Expected: All 44 tests pass

**Step 2: Check game_screen.dart line count**

Run: `wc -l lib/screens/game_screen.dart`
Expected: ~200-300 lines (down from 1209)

**Step 3: Verify all new widget files exist**

Run: `ls -la lib/widgets/game_header.dart lib/widgets/game_board_container.dart lib/widgets/hint_controller.dart`
Expected: All 3 files exist

**Step 4: Final commit**

```bash
git add -A
git commit -m "refactor: complete game_screen split into 4 focused widgets"
```

---

## Summary of New Files

| File | Lines | Responsibility |
|------|-------|----------------|
| `lib/widgets/game_header.dart` | ~80 | Timer, difficulty, pause/new game buttons |
| `lib/widgets/game_board_container.dart` | ~100 | Board, number pad, layout (wide/narrow) |
| `lib/widgets/hint_controller.dart` | ~150 | Hint banner, strategy picker, hint phases |
| `lib/screens/game_screen.dart` | ~200 | Main container, timer orchestration, state |

**Total reduction:** ~1000 lines moved to focused widgets
