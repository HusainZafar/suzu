# Suzu (鈴) - Specification

## Overview
Suzu — a cross-platform (Android & iOS) Flutter app that plays a chime sound at configurable intervals. Useful as a mindfulness bell, time-awareness tool, or hourly reminder. Named after the Japanese word for "bell."

**Business model:** Forever free. No ads, no in-app purchases.

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

## Core Features

### 1. Interval Selection
- **Default: 60 minutes**
- Options: 0 (10 seconds, testing only), 1, 5, 10, 15, 30, 60 minutes
- Selected via bottom sheet picker from home screen card
- Changing interval resets timer to the full new duration (no clock alignment)
- Toggle on/off via switch in the card

### 2. Schedule
- User can set active hours (e.g., 08:00 to 23:00) via bottom sheet
- Chimes only fire within the scheduled window
- Schedule displayed in the home screen card (tap to edit)
- Supports overnight ranges (e.g., 22:00–06:00)
- Default: all day (no restriction)

### 3. Chime Tone
- App ships with a **built-in default chime** (bell tone, WAV, 1.5s, 129KB)
- User can **upload their own tone** from device storage
- Validation for uploaded tones:
  - Max file size: ~500 KB
  - Supported formats: MP3, WAV, AAC/M4A
- Preview tone before confirming selection
- Reset to default option always available

### 4. Background Execution
- Chimes fire when the app is backgrounded or screen is locked
- **Android:** exact periodic alarms via `android_alarm_manager_plus`
  - Alarm callback runs in a background isolate
  - Plays chime via local notification with sound (not audioplayers, which doesn't work in isolates)
  - Flags: `exact: true`, `wakeup: true`, `allowWhileIdle: true`, `rescheduleOnReboot: true`
  - Permissions: `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `FOREGROUND_SERVICE`, `POST_NOTIFICATIONS`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
  - Battery optimization exemption requested when user enables chiming (via platform channel)
  - Notification permission requested at initialization
- **iOS:** repeating local notifications with custom sound
  - Requires notification permission (user prompt on first enable)
- **Foreground/background coordination:**
  - When app is in foreground, countdown timer plays chime directly and cancels the background notification to avoid double sound
  - When app is backgrounded, alarm callback fires and plays via notification
  - `nextChimeAt` timestamp persisted so countdown syncs correctly on app resume

### 5. Do Not Disturb / Quiet Hours (v2 — future)
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
| Package | Purpose |
|---|---|
| `audioplayers` | Play chime sounds (foreground only) |
| `flutter_local_notifications` | Background chime via notification sound + permission requests |
| `shared_preferences` | Persist user settings |
| `android_alarm_manager_plus` | Exact periodic alarms for background chiming on Android |
| `file_picker` | User picks audio file from device |
| `path_provider` | App documents dir for uploaded tones |

### File Structure
```
lib/
  main.dart                    — App entry, Material 3 + dark mode
  models/
    chime_settings.dart        — Settings model (interval, tonePath, enabled, schedule)
  services/
    settings_service.dart      — SharedPreferences load/save
    chime_service.dart         — Foreground timer scheduling + audio playback
    background_service.dart    — Android alarms + iOS notifications for background chiming
  screens/
    home_screen.dart           — Main screen: top card + toggle + countdown + schedule editor
    settings_screen.dart       — Tone upload/preview
android/
  app/src/main/kotlin/app/suzu/
    MainActivity.kt            — Platform channel for battery optimization exemption
assets/
  tones/
    default_chime.wav          — Built-in bell tone (1.5s, ~130KB)
```

### Data Storage
- `shared_preferences` keys:
  - `interval_minutes` — chime interval (int)
  - `custom_tone_path` — path to user's tone file (string, nullable)
  - `chime_enabled` — master toggle (bool)
  - `schedule_enabled` — whether schedule is active (bool)
  - `schedule_start_hour`, `schedule_start_minute` — schedule start time (ints)
  - `schedule_end_hour`, `schedule_end_minute` — schedule end time (ints)
  - `next_chime_at` — timestamp of next scheduled chime in ms (int, nullable)
- Uploaded tones: copied to `getApplicationDocumentsDirectory()/tones/`

## Status

### Completed
- [x] Flutter project scaffolded (Android, iOS, macOS, web)
- [x] Dependencies added and installed
- [x] Directory structure (models/, services/, screens/)
- [x] `ChimeSettings` model with copyWith (interval, tone, enabled, schedule)
- [x] `SettingsService` — SharedPreferences persistence (all keys)
- [x] `ChimeService` — foreground timer scheduling + audioplayers playback
- [x] `BackgroundService` — Android exact alarms + iOS repeating notifications
- [x] Home screen — status card with toggle, interval picker, countdown, schedule editor
- [x] Settings screen — tone upload/preview/reset
- [x] Default chime tone generated (synthesized bell, WAV, 1.5s, ~130KB)
- [x] `main.dart` — ChimeApp with Material 3, dark mode, indigo theme
- [x] Interval options: 0 (10s test), 1, 5, 10, 15, 30, 60 minutes
- [x] Interval change resets timer to full new duration
- [x] Schedule — active hours with overnight range support
- [x] Background execution — Android alarms, iOS notifications, foreground/background coordination
- [x] Battery optimization exemption request (Android)
- [x] Notification permission requests (Android + iOS)
- [x] Boot-completed receiver for alarm rescheduling
- [x] Static analysis clean

### Remaining
1. [ ] **OEM device testing** — Samsung/Xiaomi/etc. aggressive battery management workarounds
2. [ ] **Debug logging** — file-based logging for diagnosing background chime failures on device
3. [ ] **iOS testing** — build and test on real device
4. [ ] **App icon** and splash screen
5. [ ] **Privacy policy**
6. [ ] **Store listings** and publish
