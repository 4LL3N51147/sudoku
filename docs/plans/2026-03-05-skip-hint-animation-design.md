# Design: Skip Hint Animation — Fill Immediately

**Date:** 2026-03-05

## Goal

When the "Skip Animation" toggle is ON, hints should bypass all animation phases and hint banners, applying results instantly.

## Current Behavior

When `skipHintAnimation` is true:
- `_runHiddenSingleHint()`: jumps to phase 2 (target highlight), shows banner with "Next →"
- `_runStrategyHint()`: jumps to phase 2 (elimination), shows banner with "Next →"

Both paths still require a user click to complete.

## New Behavior

### Hidden Single (both legacy and strategy paths)
- Immediately fill the target cell
- Add move to undo stack
- Clear all hint state (`_strategyHighlight`, `_hintMessage`, `_hintPhase`, `_isAnimating = false`)
- Check for win
- No banner, no clicks required

### Elimination Strategies (Naked/Hidden Pair/Triple/Quad)
- Immediately apply the candidate eliminations to `_candidates`
- Show a brief snackbar: e.g. "Naked Pair applied — candidates updated"
- No banner, no animation

## Files Changed

- `lib/screens/game_screen.dart`
  - `_runHiddenSingleHint()`: replace skip-animation block with immediate fill
  - `_runStrategyHint()`: replace skip-animation block with immediate fill (Hidden Single) or immediate candidate update + snackbar (elimination strategies)
