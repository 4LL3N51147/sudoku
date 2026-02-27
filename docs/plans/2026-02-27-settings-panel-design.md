# Settings Panel Design

**Date:** 2026-02-27

## Overview

Add a settings panel to the game screen, accessible via a gear icon in the header. For now it exposes only hint animation speed settings. Settings persist across sessions using `SharedPreferences`.

## Entry Point

A gear `IconButton` (`Icons.settings`) is added to the game header after the undo button. Tapping it opens a modal bottom sheet. The button is disabled when `_isPaused || _isAnimating || _isCompleted`.

## Settings Panel UI

Modal bottom sheet titled "Settings" with one section: **Hint Animation**.

Three labeled sliders:

| Setting | Default | Range | Step |
|---------|---------|-------|------|
| Scan duration | 1500ms | 500–4000ms | 500ms |
| Elimination duration | 2000ms | 500–4000ms | 500ms |
| Target duration | 1500ms | 500–4000ms | 500ms |

Each slider shows its current value as a label (e.g. "1.5s") to its right. Changes apply immediately — no save/cancel button.

## Data Model

New file: `lib/logic/app_settings.dart` (pure Dart, no Flutter imports).

```dart
class AppSettings {
  final int hintScanMs;        // default: 1500
  final int hintEliminationMs; // default: 2000
  final int hintTargetMs;      // default: 1500

  const AppSettings({
    this.hintScanMs = 1500,
    this.hintEliminationMs = 2000,
    this.hintTargetMs = 1500,
  });

  static Future<AppSettings> load() async { ... }
  Future<void> save() async { ... }
}
```

Keys for `SharedPreferences`: `hint_scan_ms`, `hint_elimination_ms`, `hint_target_ms`.

## Integration in GameScreen

- `AppSettings _settings` field added to `_GameScreenState`
- Loaded in `initState()` via `AppSettings.load()`
- The three `Future.delayed` calls in `_runHiddenSingleHint` read from `_settings` instead of hardcoded literals
- `SettingsSheet` receives `_settings` and an `onChanged` callback that calls `setState(() => _settings = newSettings)` then `newSettings.save()`

## Settings Sheet Widget

New file: `lib/widgets/settings_sheet.dart` — a `StatefulWidget` that owns slider state locally and calls `onChanged(AppSettings)` on every slider move.

```dart
class SettingsSheet extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  ...
}
```

## Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  shared_preferences: ^2.0.0
```
