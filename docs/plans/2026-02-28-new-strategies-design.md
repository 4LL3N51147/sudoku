# New Sudoku Strategies Design

## Overview
Add three new solving strategies (Naked Single, Naked/Hidden Pair, Naked Triple/Quad) to the existing hint system. Strategies are displayed in order of difficulty and show animated steps when selected.

## Strategy Order (by difficulty)

| # | Strategy | Difficulty | Description |
|---|----------|------------|-------------|
| 1 | Naked Single | Easiest | Cell has only one possible digit |
| 2 | Hidden Single | Easy | Digit can only go in one cell in a row/col/box |
| 3 | Naked Pair | Medium | Two cells in a unit have the same two candidates |
| 4 | Hidden Pair | Medium | Two digits appear only in two cells in a unit |
| 5 | Naked Triple | Hard | Three cells in a unit have candidates that are subsets of three digits |
| 6 | Naked Quad | Hardest | Four cells in a unit with four shared candidates |

## Architecture

### Strategy Result Classes
Each strategy returns a result class with:
- **Target cells** - Cells to highlight
- **Eliminator cells** - Cells to show as blocked (for animation)
- **Candidates to remove** - Pencil marks to eliminate
- **Unit type info** - Row/column/box being analyzed
- **Phase info** - For animation sequencing

### New Result Types

```dart
class NakedSingleResult {
  final int row;
  final int col;
  final int digit;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final UnitType unitType;
}

class NakedPairResult {
  final Set<(int, int)> pairCells;  // The two cells with the pair
  final Set<int> digits;  // The two digits
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final UnitType unitType;
}

class NakedTripleResult {
  final Set<(int, int)> tripleCells;
  final Set<int> digits;
  final Set<(int, int)> unitCells;
  final Set<(int, int)> eliminatorCells;
  final UnitType unitType;
}
```

### Strategy Solver Functions

1. **findNakedSingle(board, pencilMarks)** - Find cell with only one candidate
2. **findNakedPair(board, pencilMarks)** - Find two cells with same two candidates
3. **findHiddenPair(board, pencilMarks)** - Find two digits only in two cells
4. **findNakedTriple(board, pencilMarks)** - Find three cells with shared candidates
5. **findNakedQuad(board, pencilMarks)** - Find four cells with shared candidates

Each function returns the result or null if no strategy found.

### UI Integration

#### Strategy Picker (game_screen.dart)
- Add new ListTile entries in `_showStrategyPicker()`
- Display in difficulty order (easiest first)
- Each has icon, title, subtitle describing the strategy

#### Strategy Runners
Add methods:
- `_runNakedSingleHint()` - Calls findNakedSingle
- `_runNakedPairHint()` - Calls findNakedPair + removes candidates
- `_runHiddenPairHint()` - Calls findHiddenPair + removes candidates
- `_runNakedTripleHint()` - Calls findNakedTriple + removes candidates
- `_runNakedQuadHint()` - Calls findNakedQuad + removes candidates

Each runner:
1. Calls the strategy solver function
2. Animates through phases (scan → elimination → target)
3. For elimination strategies: removes pencil marks from affected cells

### Animation Phases

Each strategy has appropriate phases:

**Naked Single:**
- Scan: Highlight the cell with one candidate
- Target: Fill in the digit

**Naked Pair/Triple/Quad:**
- Scan: Highlight the unit being analyzed
- Elimination: Highlight the cells with the pair/triple/quad
- Target: Show "Remove X from other cells"

**Hidden Pair:**
- Scan: Highlight the unit
- Elimination: Show digits that only appear in two cells
- Target: Reveal the pair

## Data Flow

```
Strategy Picker UI
       ↓
Strategy Runner Method
       ↓
Strategy Solver Function (pure Dart)
       ↓
Result with cells/candidates
       ↓
Animation Controller
       ↓
Apply: fill cell OR remove pencil marks
```

## Testing

Each strategy function is pure Dart in `lib/logic/strategy_solver.dart`:
- Add unit tests for each strategy
- Test edge cases (empty board, full board, no candidates)
- Test that candidates are correctly identified and removed

## Acceptance Criteria

1. ✓ All six strategies appear in strategy picker in difficulty order
2. ✓ Each strategy animates through appropriate phases
3. ✓ Naked Single fills cells
4. ✓ Pair/Triple/Quad strategies remove pencil marks from affected cells
5. ✓ If no strategy found, show appropriate message
6. ✓ All strategy functions have unit tests
7. ✓ Analyzer shows no new warnings
