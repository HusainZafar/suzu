# Suzu (鈴)

A mindful interval bell app for Android & iOS. Plays a gentle chime at your chosen frequency to keep you aware of time. Forever free, no ads.

## Features

- **Configurable intervals** — 5, 10, 15, 30, or 60 minutes
- **Background chiming** — works when the app is backgrounded or screen is locked
- **Custom tones** — upload your own chime sound or use the built-in bell
- **Schedule** — set active hours so it only chimes when you want (e.g., 08:00 to 23:00)
- **Clean, minimal UI** — one card, one toggle, nothing else
- **Dark mode** — follows your system theme
- **Privacy first** — no data collection, no analytics, no network calls. Everything stays on your device.

## Why?

Time slips away. Suzu gives you a gentle nudge — a soft bell at regular intervals — so you stay aware without being overwhelmed. No notifications cluttering your screen, just a sound.

## Building

```bash
flutter pub get
flutter run
```

Run in Chrome (useful for quick testing without a device):
```bash
flutter run -d chrome
```

Build a release APK:
```bash
flutter build apk --release
```

## Privacy

This app does not collect, store, or transmit any personal data. All settings and uploaded tones are stored locally on your device.

## License

GPL-3.0 — see [LICENSE](LICENSE) for details.
