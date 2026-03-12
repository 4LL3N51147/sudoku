# AdMob Banner Under NumberPad - Design

## Overview
Add an AdMob banner advertisement under the NumberPad input section in the Sudoku game screen.

## Architecture

### Dependencies
- Add `google_mobile_ads: ^5.0.0` to pubspec.yaml

### Components

1. **AdBanner Widget** (`lib/widgets/ad_banner.dart`)
   - Wraps AdMob's `BannerAd`
   - Uses test Ad ID: `ca-app-pub-3940256099942544/6300978111`
   - Shows empty container on load failure

2. **Main Initialization** (`lib/main.dart`)
   - Initialize AdMob with `MobileAds.instance.initialize()` before runApp()

3. **GameBoardContainer Update** (`lib/widgets/game_board_container.dart`)
   - Add AdBanner after NumberPad widget

## Layout Structure
```
Column
├── SudokuBoard (9x9 grid)
├── HintBanner
├── NumberPad (input: 1-9 + erase)
└── AdBanner (320x50)
```

## Configuration
- Ad Size: `AdSize.banner` (320x50)
- Test Ad Unit ID: `ca-app-pub-3940256099942544/6300978111`
- Placeholder App ID: `ca-app-pub-0000000000000000~0000000000000000`

## Error Handling
- Ad load failure: Show empty container (no broken UI)
- Wrap in SafeArea for proper mobile rendering

## Platform Notes
- Android: Requires Google Play Services
- iOS: Requires GADApplicationIdentifier in Info.plist
- Web: AdMob not fully supported, banner will show placeholder
