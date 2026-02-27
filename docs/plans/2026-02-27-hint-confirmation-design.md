# User-Confirmed Hint Animation Design

**Date:** 2026-02-27

## Overview

Change the hint animation from timed delays to user-confirmed steps. Each phase waits for the user to tap "Next" before advancing, giving them time to understand each step.

## UI Changes

### Hint Banner with Next Button

The hint banner (`_buildHintBanner`) gets a "Next" button added to its right side:

```
┌─────────────────────────────────────────────────┐
│ ℹ️ Scanning this row — looking for digit 5  [Next →] │
└─────────────────────────────────────────────────┘
```

- "Next" button is disabled when no hint is active (`_hintPhase == null`)
- Same disabled conditions as other buttons: `_isPaused || _isAnimating || _isCompleted`

## State Changes

### New Field

```dart
int? _hintPhase; // null = no hint, 0 = scan, 1 = elimination, 2 = target
```

### New Method

`_advanceHintPhase()`:
- If `_hintPhase == null` → do nothing (button disabled)
- If `_hintPhase! < 2` → increment phase, update highlight/message
- If `_hintPhase == 2` → fill the cell, reset `_hintPhase = null`, end animation

## Flow Changes

### Before (timed)

1. Set Phase 1 → wait 1.5s → Set Phase 2 → wait 2s → Set Phase 3 → wait 1.5s → Fill cell

### After (user-confirmed)

1. Set Phase 1, wait for Next → Set Phase 2, wait for Next → Set Phase 3 → Fill cell

The three animation-duration settings (`hintScanMs`, `hintEliminationMs`, `hintTargetMs`) are no longer used for the hint flow since it's now user-driven.
