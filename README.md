# Sudoku

A clean, web-first Sudoku game built with Flutter — featuring animated strategy hints that teach you *why* a move works, not just what it is.

## Features

- **Four difficulty levels** — Easy (46 givens), Medium (35), Hard (29), Master (25)
- **Animated strategy hints** — tap the lightbulb to trigger a step-by-step walkthrough:
  1. *Scan* — highlights the row, column, or box being analyzed
  2. *Elimination* — shows which filled cells block every other candidate
  3. *Target* — reveals the only valid cell, then fills it in
- **Pencil marks** — toggle pencil mode to add candidate numbers to cells
- **Undo** — step back through your moves at any time
- **Keyboard shortcuts** — use number keys to input, arrows to navigate
- **Game export/import** — save and share your game as JSON
- **Settings panel** — toggle hints, error highlighting, and theme
- **Live error highlighting** — incorrect entries are flagged immediately
- **Game timer** — tracks your solve time, displayed on the win screen
- **Pause / resume** — hides the board and stops the clock until you're ready

## Getting Started

**Prerequisites:** Flutter 3.x with web support enabled.

```bash
# Run on web (dev mode)
flutter run -d chrome

# Build for web
flutter build web

# Serve the build locally
python3 -m http.server 8080 --directory build/web
```

Then open `http://localhost:8080`.

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── app_settings.dart            # App-wide settings
├── logic/
│   ├── sudoku_generator.dart    # Puzzle generation
│   ├── strategy_solver.dart     # Hint strategies (pure Dart)
│   ├── game_state.dart          # Game serialization
│   ├── web_export.dart          # Web export helpers
│   └── web_export_stub.dart     # Non-web stub
├── screens/
│   ├── difficulty_screen.dart   # Difficulty picker with import
│   └── game_screen.dart         # Game loop, timer, hint animation
└── widgets/
    ├── sudoku_board.dart        # Stateless board widget
    ├── number_pad.dart          # Input controls
    └── settings_sheet.dart      # Settings bottom sheet
```

Logic in `lib/logic/` has no Flutter dependencies — it's pure Dart and fully unit-testable.

## Development

```bash
# Static analysis
flutter analyze
```

Tests live in `test/logic/` for solver logic and `test/widget_test.dart` for widgets.
