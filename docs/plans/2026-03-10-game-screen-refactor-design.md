# Game Screen Refactor Design

## Date: 2026-03-10

## Objective

Split the monolithic `game_screen.dart` (1209 lines) into smaller, focused widgets using a feature-based approach.

## Approach

**Selected: Feature-based split with callback passing**

Keep all state in GameScreen, pass callbacks to child widgets. This approach:
- Maintains consistency with existing codebase patterns
- Minimizes changes to data flow
- Achieves the goal of breaking down the large file

## Proposed File Structure

```
lib/
├── screens/
│   └── game_screen.dart          (~200 lines) - Main container, timer, pause, orchestration
├── widgets/
│   ├── game_board_container.dart (~300 lines) - Board + number pad + selection logic
│   ├── hint_controller.dart      (~350 lines) - Hint system, strategy picker, advance hint
│   └── game_header.dart          (~100 lines) - Timer, difficulty, pause/play button
```

## Component Responsibilities

### 1. GameScreen (main container)
- Holds ALL state (unchanged from current)
- Manages timer start/stop
- Handles pause/resume
- Orchestrates child widgets
- Builds layout (wide/narrow)

### 2. GameBoardContainer (board + input)
- Contains: SudokuBoard, NumberPad
- Handles: cell tap, number input, erase
- Receives: board data, selection, candidates, callbacks from parent

### 3. HintController (hint system)
- Contains: hint banner, strategy picker dialog, hint phase advancement
- Handles: hint request, strategy selection, hint animation steps
- Receives: strategy results, settings, callbacks from parent

### 4. GameHeader (timer + controls)
- Contains: timer display, difficulty, pause button
- Handles: pause toggle, new game trigger
- Receives: elapsed time, difficulty, callbacks from parent

## Data Flow

```
GameScreen (state holder)
    │
    ├───> GameBoardContainer(board, candidates, selection, onCellTap, onNumberInput, onErase)
    │
    ├───> HintController(strategyResult, settings, onHintRequested, onAdvanceHint, onApplyHint)
    │
    └───> GameHeader(elapsedSeconds, difficulty, onPauseToggle, onNewGame)
```

## Design Decisions

1. **No new state management** - Keep using StatefulWidget with callback pattern
2. **Minimal interface changes** - Child widgets receive simple callbacks, not complex objects
3. **Preserve animation guards** - All input handlers in child widgets remain guarded by `_isAnimating`

## Testing Strategy

- Existing tests should continue to pass (game_state_test, strategy_solver_test)
- Widget tests for new components (game_board_container_test, hint_controller_test, game_header_test)

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Breaking existing functionality | Keep all state in GameScreen, only refactor UI composition |
| Circular dependencies | Each widget imports only what it needs |
| Test breakage | Run tests after each extraction |

## Approval

Approved by: User
Date: 2026-03-10
