# Suzu (鈴) - Specification

## Overview
Suzu — a cross-platform (Android & iOS) Flutter app that plays a chime sound at configurable intervals. Useful as a mindfulness bell, time-awareness tool, or hourly reminder. Named after the Japanese word for "bell."

**Business model:** Forever free. No ads, no in-app purchases. Optional "Buy me a coffee" link in settings.

## App Layout

### Home Screen
- **Top card** — the main control:
  - Shows selected interval (e.g., "Every 15 minutes") — tap to change
  - Toggle switch to enable/disable chiming
  - When active: green dot + countdown ("Next chime in 14 min 32s")
  - Schedule display (e.g., "08:00 to 23:00") — shown in the card
- **Rest of screen** — clean and empty, minimal design
- **Settings gear** — top-right app bar icon

### Settings Screen
- **Chime Tone** — current tone name, preview button, upload custom / reset to default
- **Buy me a coffee** — link to support the developer

## Core Features

### 1. Interval Selection
- **Default: 60 minutes**
- Options: 1, 5, 10, 15, 30, 60 minutes (1 min is for testing)
- Selected via bottom sheet picker from home screen card
- Changing interval resets timer to the full new duration (no clock alignment)
- Toggle on/off via switch in the card

### 2. Schedule (TODO)
- User can set active hours (e.g., 08:00 to 23:00)
- Chimes only fire within the scheduled window
- Schedule displayed in the home screen card
- Default: all day (no restriction)

### 3. Chime Tone
- App ships with a **built-in default chime** (bell tone, WAV, 1.5s, 129KB)
- User can **upload their own tone** from device storage
- Validation for uploaded tones:
  - Max file size: ~500 KB
  - Supported formats: MP3, WAV, AAC/M4A
- Preview tone before confirming selection
- Reset to default option always available

### 4. Background Execution (TODO)
- Chimes must fire when the app is backgrounded or screen is locked
- **Android:** foreground service with persistent notification + WAKE_LOCK
  - Permissions: `FOREGROUND_SERVICE`, `WAKE_LOCK` (declared in manifest, no user prompt)
  - Persistent notification: "Chime is running"
- **iOS:** local notifications scheduled with custom sound
  - Requires notification permission (user prompt on first enable)
- **Current limitation:** Timer only works while app is in foreground

### 5. Buy Me a Coffee
- Settings row: coffee icon + "Buy me a coffee" label
- Opens external link in system browser via `url_launcher`
- URL configurable (set once in code, easy to change)

### 6. Do Not Disturb / Quiet Hours (v2 — future)
- Configurable quiet hours — may merge with Schedule feature

## Platform Targets
- **Android** (minSdk 21+)
- **iOS** (iOS 14+)

## App Store Publishing

### App Identity
- **App name:** Suzu (or "Suzu — Mindful Bell" for discoverability)
- **Bundle ID:** `app.suzu` (Android + iOS)
- **Category:** Utilities / Productivity

### Requirements for Publishing
- [ ] App icon (1024x1024 + adaptive icon for Android)
- [ ] Splash screen
- [ ] Privacy policy (minimal — no data collection)
- [ ] App store screenshots (phone + tablet if possible)
- [ ] Short & long descriptions
- [ ] Apple Developer account ($99/year)
- [ ] Google Play Developer account ($25 one-time)

### Privacy
- No data collection, no analytics, no network calls
- All data stays on device (settings + uploaded tones)
- Privacy policy: "This app does not collect, store, or transmit any personal data."

## Technical Details

### Architecture
- Home screen with top card + settings screen
- State: plain `StatefulWidget` with `setState` (no state management library needed)
- Persistence: `shared_preferences`
- Uploaded tones copied to app documents directory

### Key Packages
| Package | Purpose | Status |
|---|---|---|
| `audioplayers` | Play chime sounds | Installed |
| `flutter_local_notifications` | Schedule notifications with sound | Installed (not wired) |
| `shared_preferences` | Persist user settings | Installed, in use |
| `android_alarm_manager_plus` | Background scheduling on Android | Installed (not wired) |
| `file_picker` | User picks audio file from device | Installed, in use |
| `path_provider` | App documents dir for uploaded tones | Installed, in use |
| `url_launcher` | Open coffee link in browser | Installed, in use |

### File Structure
```
lib/
  main.dart                    — App entry, Material 3 + dark mode
  models/
    chime_settings.dart        — Settings model (interval, tonePath, enabled)
  services/
    settings_service.dart      — SharedPreferences load/save
    chime_service.dart         — Timer scheduling + audio playback
  screens/
    home_screen.dart           — Main screen: top card + toggle + countdown
    settings_screen.dart       — Tone upload/preview, buy-me-a-coffee
assets/
  tones/
    default_chime.wav          — Generated bell tone (1.5s, 129KB)
```

### Data Storage
- `shared_preferences`: interval (int), tone path (string), enabled (bool)
- Uploaded tones: copied to `getApplicationDocumentsDirectory()/tones/`

## Status

### Completed
- [x] Flutter project scaffolded (Android, iOS, macOS, web)
- [x] Dependencies added and installed
- [x] Directory structure (models/, services/, screens/)
- [x] `ChimeSettings` model with copyWith
- [x] `SettingsService` — SharedPreferences persistence
- [x] `ChimeService` — foreground timer scheduling + audioplayers playback
- [x] Home screen — top status card with toggle, interval picker (bottom sheet), countdown
- [x] Settings screen — tone upload/preview/reset, buy-me-a-coffee link
- [x] Default chime tone generated (synthesized bell, WAV, 1.5s, 129KB)
- [x] `main.dart` — ChimeApp with Material 3, dark mode, indigo theme
- [x] Interval options: 1, 5, 10, 15, 30, 60 minutes
- [x] Interval change resets timer to full new duration
- [x] Static analysis clean

### Remaining
1. [ ] **Schedule** — active hours (e.g., 08:00–23:00), display in home card
2. [ ] **Background execution** — Android foreground service + iOS local notifications
3. [ ] **Android testing** — build APK, test on real device
4. [ ] **iOS testing** — build and test on real device
5. [ ] **App icon** and splash screen
6. [ ] **Privacy policy**
7. [ ] **Store listings** and publish
