# Settings Panel Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a settings panel to the game header exposing three per-phase hint animation speed sliders, persisted via SharedPreferences.

**Architecture:** A pure-Dart `AppSettings` class handles load/save. A new `SettingsSheet` widget owns the slider UI. `_GameScreenState` holds a `_settings` field, loads it in `initState`, replaces the three hardcoded `Future.delayed` literals in `_runHiddenSingleHint`, and opens the sheet via a gear `IconButton` in the header.

**Tech Stack:** Flutter 3.x / Dart 3.x, `shared_preferences` package. Use `flutter analyze` to verify (flutter test is broken on this machine — network issue with storage.flutter-io.cn).

---

### Task 1: Add `shared_preferences` dependency

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies:`, add `shared_preferences`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.3.0
```

**Step 2: Fetch packages**

```bash
flutter pub get
```

Expected output: `Got dependencies!`

**Step 3: Analyze**

```bash
flutter analyze
```

Expected: no new errors (8 pre-existing `info` hints in `difficulty_screen.dart` are unrelated).

**Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat(settings): add shared_preferences dependency"
```

---

### Task 2: Create `AppSettings` class

**Files:**
- Create: `lib/logic/app_settings.dart`

**Step 1: Create the file**

```dart
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final int hintScanMs;
  final int hintEliminationMs;
  final int hintTargetMs;

  static const int _defaultScanMs = 1500;
  static const int _defaultEliminationMs = 2000;
  static const int _defaultTargetMs = 1500;

  static const String _keyScan = 'hint_scan_ms';
  static const String _keyElimination = 'hint_elimination_ms';
  static const String _keyTarget = 'hint_target_ms';

  const AppSettings({
    this.hintScanMs = _defaultScanMs,
    this.hintEliminationMs = _defaultEliminationMs,
    this.hintTargetMs = _defaultTargetMs,
  });

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      hintScanMs: prefs.getInt(_keyScan) ?? _defaultScanMs,
      hintEliminationMs: prefs.getInt(_keyElimination) ?? _defaultEliminationMs,
      hintTargetMs: prefs.getInt(_keyTarget) ?? _defaultTargetMs,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyScan, hintScanMs);
    await prefs.setInt(_keyElimination, hintEliminationMs);
    await prefs.setInt(_keyTarget, hintTargetMs);
  }

  AppSettings copyWith({
    int? hintScanMs,
    int? hintEliminationMs,
    int? hintTargetMs,
  }) {
    return AppSettings(
      hintScanMs: hintScanMs ?? this.hintScanMs,
      hintEliminationMs: hintEliminationMs ?? this.hintEliminationMs,
      hintTargetMs: hintTargetMs ?? this.hintTargetMs,
    );
  }
}
```

**Step 2: Analyze**

```bash
flutter analyze
```

Expected: no new errors.

**Step 3: Commit**

```bash
git add lib/logic/app_settings.dart
git commit -m "feat(settings): add AppSettings class with SharedPreferences persistence"
```

---

### Task 3: Create `SettingsSheet` widget

**Files:**
- Create: `lib/widgets/settings_sheet.dart`

**Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import '../logic/app_settings.dart';

class SettingsSheet extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  const SettingsSheet({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late int _scanMs;
  late int _eliminationMs;
  late int _targetMs;

  @override
  void initState() {
    super.initState();
    _scanMs = widget.settings.hintScanMs;
    _eliminationMs = widget.settings.hintEliminationMs;
    _targetMs = widget.settings.hintTargetMs;
  }

  void _update({int? scan, int? elimination, int? target}) {
    final newScan = scan ?? _scanMs;
    final newElimination = elimination ?? _eliminationMs;
    final newTarget = target ?? _targetMs;
    setState(() {
      _scanMs = newScan;
      _eliminationMs = newElimination;
      _targetMs = newTarget;
    });
    widget.onChanged(AppSettings(
      hintScanMs: newScan,
      hintEliminationMs: newElimination,
      hintTargetMs: newTarget,
    ));
  }

  String _label(int ms) => '${(ms / 1000).toStringAsFixed(1)}s';

  Widget _slider({
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(title, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 500,
            max: 4000,
            divisions: 7,
            onChanged: (v) => onChanged(v.round()),
            activeColor: const Color(0xFF1A237E),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(_label(value), style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'HINT ANIMATION',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _slider(
            title: 'Scan',
            value: _scanMs,
            onChanged: (v) => _update(scan: v),
          ),
          _slider(
            title: 'Elimination',
            value: _eliminationMs,
            onChanged: (v) => _update(elimination: v),
          ),
          _slider(
            title: 'Target',
            value: _targetMs,
            onChanged: (v) => _update(target: v),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Analyze**

```bash
flutter analyze
```

Expected: no new errors.

**Step 3: Commit**

```bash
git add lib/widgets/settings_sheet.dart
git commit -m "feat(settings): add SettingsSheet widget with per-phase sliders"
```

---

### Task 4: Integrate `AppSettings` into `GameScreen`

**Files:**
- Modify: `lib/screens/game_screen.dart`

**Step 1: Add import at the top of the file**

After the existing imports, add:

```dart
import '../logic/app_settings.dart';
```

**Step 2: Add `_settings` field to `_GameScreenState`**

After `final List<_Move> _undoStack = [];` (line ~34), add:

```dart
AppSettings _settings = const AppSettings();
```

**Step 3: Load settings in `initState`**

Replace the current `initState`:

```dart
@override
void initState() {
  super.initState();
  _newGame();
  _loadSettings();
}

Future<void> _loadSettings() async {
  final settings = await AppSettings.load();
  if (mounted) setState(() => _settings = settings);
}
```

**Step 4: Replace hardcoded durations in `_runHiddenSingleHint`**

There are three `Future.delayed` calls with hardcoded milliseconds. Replace them:

- `await Future.delayed(const Duration(milliseconds: 1500));` after Phase 1 setState →
  `await Future.delayed(Duration(milliseconds: _settings.hintScanMs));`

- `await Future.delayed(const Duration(milliseconds: 2000));` after Phase 2 setState →
  `await Future.delayed(Duration(milliseconds: _settings.hintEliminationMs));`

- `await Future.delayed(const Duration(milliseconds: 1500));` after Phase 3 setState →
  `await Future.delayed(Duration(milliseconds: _settings.hintTargetMs));`

**Step 5: Analyze**

```bash
flutter analyze
```

Expected: no new errors.

**Step 6: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "feat(settings): wire AppSettings into GameScreen hint durations"
```

---

### Task 5: Add gear button to header and open settings sheet

**Files:**
- Modify: `lib/screens/game_screen.dart`
- Modify: `lib/screens/game_screen.dart` (add import for SettingsSheet)

**Step 1: Add `SettingsSheet` import**

Add at the top with the other widget imports:

```dart
import '../widgets/settings_sheet.dart';
```

**Step 2: Add `_showSettings()` method**

Add this method anywhere in `_GameScreenState`, for example after `_showStrategyPicker()`:

```dart
void _showSettings() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SettingsSheet(
      settings: _settings,
      onChanged: (newSettings) {
        setState(() => _settings = newSettings);
        newSettings.save();
      },
    ),
  );
}
```

**Step 3: Add gear `IconButton` to `_buildHeader()`**

In `_buildHeader()`, after the undo `IconButton` (the one with `Icons.undo`) and before the `Expanded` title, add:

```dart
IconButton(
  icon: const Icon(Icons.settings),
  onPressed: (_isPaused || _isAnimating || _isCompleted)
      ? null
      : _showSettings,
  color: const Color(0xFF1A237E),
),
```

**Step 4: Analyze**

```bash
flutter analyze
```

Expected: no new errors.

**Step 5: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "feat(settings): add gear button and settings bottom sheet to game header"
```
