# Sudoku

A clean, web-first Sudoku game built with Flutter — featuring animated strategy hints that teach you *why* a move works, not just what it is.

## Features

- **Three difficulty levels** — Easy (46 givens), Medium (35), Hard (29)
- **Animated strategy hints** — tap the lightbulb to trigger a step-by-step walkthrough:
  1. *Scan* — highlights the row, column, or box being analyzed
  2. *Elimination* — shows which filled cells block every other candidate
  3. *Target* — reveals the only valid cell, then fills it in
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
├── logic/
│   ├── sudoku_generator.dart    # Puzzle generation
│   └── strategy_solver.dart     # Hint strategies (pure Dart)
├── screens/
│   ├── difficulty_screen.dart   # Difficulty picker
│   └── game_screen.dart         # Game loop, timer, hint animation
└── widgets/
    ├── sudoku_board.dart        # Stateless board widget
    └── number_pad.dart          # Input controls
```

Logic in `lib/logic/` has no Flutter dependencies — it's pure Dart and fully unit-testable.

## Development

```bash
# Static analysis
flutter analyze
```

Tests live in `test/logic/` for solver logic and `test/widget_test.dart` for widgets.
