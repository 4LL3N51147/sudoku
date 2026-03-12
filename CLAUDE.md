# CLAUDE.md — Sudoku Codebase Guide

A Flutter/Dart Sudoku game targeting web (and mobile).

## Project Structure

```
sudoku/
├── lib/
│   ├── main.dart                    # Entry point (SudokuApp)
│   ├── app_settings.dart            # App settings/state management
│   ├── logic/
│   │   ├── sudoku_generator.dart    # Puzzle generation
│   │   ├── game_state.dart          # Game state management
│   │   └── strategy_solver.dart     # Hint strategies (pure Dart, no Flutter imports)
│   ├── screens/
│   │   ├── difficulty_screen.dart   # White bg, OutlinedButton per difficulty
│   │   └── game_screen.dart         # Main game: timer, animation, input guards
│   └── widgets/
│       ├── sudoku_board.dart        # Stateless board; driven entirely by props
│       ├── number_pad.dart
│       └── settings_sheet.dart      # Settings dialog (hint animation controls)
├── test/
│   ├── widget_test.dart
│   └── logic/
│       ├── game_state_test.dart
│       └── strategy_solver_test.dart
└── web/                             # Flutter web build assets
```

## Technology Stack

| Item | Details |
|------|---------|
| Language | Dart 3.x |
| Framework | Flutter 3.x |
| Platform | Web (primary), mobile-capable |
| Package name | `sudoku` |

## MCP Servers & Tools

This project has **Dart MCP server** available. Prioritize using them over shell commands:

- **Run tests**: Use `mcp__dart__run_tests` tool instead of `flutter test`
- **Analyze code**: Use `mcp__dart__analyze_files` tool instead of `flutter analyze`
- **Format code**: Use `mcp__dart__dart_format` tool instead of `dart format`
- **Run fixes**: Use `mcp__dart__dart_fix` tool
- **Launch app**: Use `mcp__dart__launch_app` to run on connected devices
- **List devices**: Use `mcp__dart__list_devices` to see available targets
- **Hot reload/restart**: Use `mcp__dart__hot_reload` or `mcp__dart__hot_restart`

**Flutter Inspector Workflow (for debugging UI):**
1. Launch app with `mcp__dart__launch_app` → returns DTD URI
2. Connect to DTD: `mcp__dart__connect_dart_tooling_daemon` with the URI
3. Use inspector tools: `get_widget_tree`, `get_selected_widget`, `get_runtime_errors`
4. Reconnect if app restarts or terminates — DTD URI changes each session

## Build & Run

```bash
# Analyze code (use this instead of flutter test — see Testing section)
flutter analyze

# Build for web
flutter build web

# Serve locally after building
python3 -m http.server 8080 --directory build/web

**Local dev server** — Port 8080 may already be in use from a previous session. Use
  `curl http://localhost:8080` to verify before starting a new server.
```

## Testing

Logic tests live in `test/logic/` (`game_state_test.dart`, `strategy_solver_test.dart`)
and import only `package:flutter_test/flutter_test.dart` plus the pure-Dart logic files.
Widget tests are in `test/widget_test.dart`.

`flutter analyze` runs code quality checks (7 info-level issues are expected: deprecated
`dart:html` usage for keyboard handling and minor style suggestions).

## Code Conventions

- **Pure logic in `lib/logic/`** — no Flutter imports; fully unit-testable.
- **Widgets are stateless and prop-driven** — `SudokuBoard` has zero knowledge
  of game state; all rendering flows from parameters.
- **Hint strategy elimination zones** — The elimination zone shows which specific constraint
  (column, row, or box) actually eliminates each empty cell, NOT all constraints containing
  the digit. Priority: box > row > column. When a box contains the digit, rows/cols are not
  added to avoid duplicates. Same priority applies for box hidden single (row > column).
  - `HintStep.eliminationBoxes` shows which 3x3 boxes contain the digit
  - `HintStep.eliminatorCells` should equal `eliminators` (the blocker cells from _findBlockers)
- **Animation guards** — when adding any async animation or timed sequence,
  guard ALL input handlers (`_onCellTap`, `_onNumberInput`, `_onErase`) and
  interactive buttons against the animating flag, not just the trigger button.
- **`_isAnimating` vs `_isPaused`** — these are separate flags; `_isPaused`
  shows the pause overlay; `_isAnimating` only stops the timer.
- **Widget extraction refactoring** — When extracting widgets (e.g., GameBoardContainer,
  HintController), verify the layout remains identical. The original used vertical Column
  for both wide and narrow screens. Avoid changing to horizontal Row layouts.

## Git Workflow

- **Default branch:** `main`
- Commit messages should be descriptive.

## Plan Execution Workflow

When executing implementation plans with multiple independent tasks, always use the
**subagent-driven-development** skill (`superpowers:subagent-driven-development`) rather
than executing tasks sequentially in the main session. This enables parallel execution
of independent tasks and better context management.

**Never use git worktrees** — modify the codebase in place on local branches.

## Playwright / Browser Automation

Flutter web renders to canvas; accessibility must be enabled before Playwright
can interact with semantic elements:
```js
await page.evaluate(() => {
  document.querySelector('flt-semantics-placeholder')?.click();
});
```
After this, use snapshot refs (`aria-ref`) to interact with elements. Refs change
after each navigation — always re-snapshot after page transitions.
