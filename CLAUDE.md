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

## Build & Run

```bash
# Analyze code (use this instead of flutter test — see Testing section)
flutter analyze

# Build for web
flutter build web

# Serve locally after building
python3 -m http.server 8080 --directory build/web
```

## Testing

Logic tests live in `test/logic/` (`game_state_test.dart`, `strategy_solver_test.dart`)
and import only `package:flutter_test/flutter_test.dart` plus the pure-Dart logic files.
Widget tests are in `test/widget_test.dart`.

`flutter analyze` runs code quality checks (7 info-level issues are expected: deprecated
`dart:html` usage for keyboard handling and minor style suggestions).

**All changes must include Playwright integration tests**, regardless of change size.
Use the Playwright MCP tools (browser_navigate, browser_snapshot, browser_click, etc.)
to verify the web app works correctly in a real browser. See the Playwright section
below for setup details.

## Code Conventions

- **Pure logic in `lib/logic/`** — no Flutter imports; fully unit-testable.
- **Widgets are stateless and prop-driven** — `SudokuBoard` has zero knowledge
  of game state; all rendering flows from parameters.
- **Animation guards** — when adding any async animation or timed sequence,
  guard ALL input handlers (`_onCellTap`, `_onNumberInput`, `_onErase`) and
  interactive buttons against the animating flag, not just the trigger button.
- **`_isAnimating` vs `_isPaused`** — these are separate flags; `_isPaused`
  shows the pause overlay; `_isAnimating` only stops the timer.

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
