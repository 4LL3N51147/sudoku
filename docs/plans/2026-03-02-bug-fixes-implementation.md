# Bug Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix three bugs: duplicate export button, mobile responsive layout, and add About page with build info.

**Architecture:**
- Task 1: Remove duplicate IconButton in game_screen.dart
- Task 2: Add LayoutBuilder for responsive layout in game_screen.dart
- Task 3: Create build info generation script and About section in settings

**Tech Stack:** Flutter, Dart, shell script

---

## Task 1: Remove Duplicate Export Button

**Files:**
- Modify: `lib/screens/game_screen.dart:629-636`

**Step 1: Remove duplicate button**

Delete lines 629-636 (the second IconButton with Icons.share_outlined).

**Step 2: Verify no duplicate**

Run: `grep -n "share_outlined" lib/screens/game_screen.dart`
Expected: Only one occurrence

**Step 3: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "fix: remove duplicate export button"
```

---

## Task 2: Mobile Responsive Layout

**Files:**
- Modify: `lib/screens/game_screen.dart`

**Step 1: Add LayoutBuilder wrapper**

Find the main Scaffold body and wrap with LayoutBuilder to detect width.

**Step 2: Create narrow layout method**

Add `_buildNarrowLayout()` method that returns Column with:
1. Header bar (timer + controls)
2. Expanded Sudoku board
3. Number pad

**Step 3: Update build method**

Use LayoutBuilder to choose between wide and narrow layouts.

**Step 4: Test build**

Run: `flutter analyze`
Expected: No errors

**Step 5: Commit**

```bash
git add lib/screens/game_screen.dart
git commit -m "fix: add responsive layout for mobile"
```

---

## Task 3: Build Info Generation Script

**Files:**
- Create: `scripts/generate_build_info.sh`
- Create: `lib/build_info.dart` (generated)
- Modify: `lib/widgets/settings_sheet.dart`

**Step 1: Create build script**

Create `scripts/generate_build_info.sh`:
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

**Step 2: Run build script**

Run: `chmod +x scripts/generate_build_info.sh && ./scripts/generate_build_info.sh`

**Step 3: Verify generated file**

Run: `cat lib/build_info.dart`
Expected: File with version, commit, buildTime

**Step 4: Add About section to settings**

In `lib/widgets/settings_sheet.dart`, add:
- Import: `import '../build_info.dart';`
- Add ListTile at bottom with About info

**Step 5: Test build**

Run: `flutter build web 2>&1 | tail -5`
Expected: Build success

**Step 6: Commit**

```bash
git add scripts/generate_build_info.sh lib/build_info.dart lib/widgets/settings_sheet.dart
git commit -m "feat: add About page with build info"
```

---

## Task 4: Deploy to Production

**Step 1: Generate build info**

Run: `./scripts/generate_build_info.sh`

**Step 2: Build web**

Run: `flutter build web`

**Step 3: Push to openclaw**

Run: `rsync -avz --delete --exclude '.git' --exclude '.*' build/web/ openclaw:public_html/`

**Step 4: Commit build info**

```bash
git add lib/build_info.dart
git commit -m "chore: add generated build info"
git push
```
