# AdMob (mobile) + AdSense (web) Banner - Design

## Overview
Add AdSense support for web while keeping AdMob for mobile.

## Architecture

### Dependencies
- Existing: `google_mobile_ads` for mobile

### Components

1. **Web HTML** (`web/index.html`)
   - Add AdSense script in `<head>`

2. **AdSense Widget** (`lib/widgets/adsense_banner.dart`)
   - New widget for web ads

3. **Update AdBanner** (`lib/widgets/ad_banner.dart`)
   - Mobile: Show AdMob banner
   - Web: Show AdSense banner

## Configuration
- AdMob: Test ID `ca-app-pub-3940256099942544/6300978111`
- AdSense: Placeholder `ca-pub-XXXXXXXXXX` (replace with real ID)
