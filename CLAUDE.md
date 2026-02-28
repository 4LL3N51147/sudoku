# CLAUDE.md — Sudoku Codebase Guide

A Flutter/Dart Sudoku game targeting web (and mobile).

## Project Structure

```
sudoku/
├── lib/
│   ├── main.dart                    # Entry point (SudokuApp)
│   ├── app_settings.dart            # App-wide settings (theme, hints)
│   ├── logic/
│   │   ├── sudoku_generator.dart    # Puzzle generation
│   │   ├── strategy_solver.dart     # Hint strategies (pure Dart, no Flutter imports)
│   │   ├── game_state.dart          # Game state serialization (import/export)
│   │   ├── web_export.dart          # Web-specific JSON download
│   │   └── web_export_stub.dart     # Non-web stub
│   ├── screens/
│   │   ├── difficulty_screen.dart   # Difficulty picker with import
│   │   └── game_screen.dart         # Main game: timer, animation, input guards
│   └── widgets/
│       ├── sudoku_board.dart        # Stateless board; driven entirely by props
│       ├── number_pad.dart          # Number input pad
│       └── settings_sheet.dart      # Bottom sheet for settings
├── test/
│   ├── widget_test.dart
│   └── logic/strategy_solver_test.dart
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

**`flutter test` is broken** on this machine due to a connectivity issue with
`storage.flutter-io.cn` (test runner tries to download assets and fails).
Use `flutter analyze` to verify correctness instead.

Logic tests live in `test/logic/` and import only `package:flutter_test/flutter_test.dart`
plus the pure-Dart logic files. Widget tests are in `test/widget_test.dart`.

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
