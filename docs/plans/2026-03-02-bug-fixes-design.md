# Design: Bug Fixes - Export Button, Mobile Layout, About Page

**Date:** 2026-03-02

## 1. Remove Duplicate Export Button

### Problem
The game screen has two export buttons that call the same `_exportGame()` function.

### Solution
Delete the duplicate `IconButton` widget at lines 629-636 in `lib/screens/game_screen.dart`.

## 2. Mobile Responsive Layout

### Problem
The game screen layout breaks on mobile devices due to fixed/row-based layout.

### Solution
Add responsive layout using `LayoutBuilder`:

- **Breakpoint:** 600px width
- **Wide (>600px):** Current row layout - header bar + board + number pad in row
- **Narrow (≤600px):** Vertical column layout:
  1. Header bar (timer, controls)
  2. Sudoku board (centered, smaller)
  3. Number pad (bottom, scrollable if needed)

### Implementation
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isWide = constraints.maxWidth > 600;
    if (isWide) {
      return _buildWideLayout();
    } else {
      return _buildNarrowLayout();
    }
  },
)
```

## 3. About Page with Build Information

### Problem
No way to display app version or build info to users.

### Solution
Generate build info at build time and display via Settings.

### Build Info Generation

**Script:** `scripts/generate_build_info.sh`
```bash
#!/bin/bash
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

cat > lib/build_info.dart << EOF
/// Build information - auto-generated at build time
class BuildInfo {
  static const String version = '1.0.0+1';
  static const String commit = '$COMMIT';
  static const String buildTime = '$BUILD_TIME';
}
EOF
```

### UI Display

**Location:** `lib/widgets/settings_sheet.dart`

**Content:**
- Version: `BuildInfo.version`
- Build Time: `BuildInfo.buildTime`
- Commit: `BuildInfo.commit` (short 7-char hash)

### Integration
- Run build script before `flutter build web` in deployment
- Or add to pubspec.yaml scripts/pre-build hook
