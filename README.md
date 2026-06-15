# SpartanBody 💪

All-in-one iOS fitness app: workouts, nutrition, hydration, and progress — built with SwiftUI.

## Features

- 🏋️ **Workouts** — log sets/reps/weight, build routines, follow programs
- 🍴 **Nutrition** — calorie & macro tracking with a 50+ food database
- 📸 **AI Food Scanner** — snap a photo, get instant nutrition (Claude Vision via Cloudflare proxy)
- 📊 **Barcode Scanner** — scan packaged products via Open Food Facts (3M+ items)
- 🍳 **28 recipes** — including vegan & vegetarian options
- 🤖 **AI Coach** — personalized 7-day plans (fully local, no internet needed)
- 💧 **Reminders** — workout, hydration, meals, and bedtime
- ⌚ **Apple Watch** — companion app with complication
- 📱 **Home & Lock Screen widgets**
- 🌐 **5 languages** — English, Spanish, French, Italian, Portuguese (BR)
- 🩺 **Apple Health** integration
- 🌓 **Dark & Light mode**
- 🔒 **Privacy-first** — all data stays on device, no account required

## Project structure

```
SpartanBody/                     iOS app (main target)
├── Core/
│   ├── Models/                  Data models
│   ├── Services/                Business logic (stores, HealthKit, etc.)
│   └── DesignSystem.swift       Colors, typography, components
├── Features/                    UI by feature (Dashboard, Workout, ...)
├── Components/                  Reusable views (charts, scanners)
└── Localizable.xcstrings        All translations (5 languages)

SpartanBodyWatch/                watchOS companion
SpartanBodyWidget/               Home/Lock screen widgets + Live Activities

CloudflareWorker/                Backend proxy for the AI scanner
docs/                            Privacy policy, App Store copy, launch guide
```

## Requirements

- Xcode 26+
- iOS 17.0+
- macOS for development
- Apple Developer account (for distribution; free Personal Team works for local testing on your own device)

## Running locally

```bash
open SpartanBody.xcodeproj
```

Select your iPhone as the destination and press **Run**. For the AI Food Scanner to work, deploy the Cloudflare Worker first (see `CloudflareWorker/README.md`).

## Configuration

- `SpartanBody/Core/Config.swift` — Cloudflare Worker URL, weekly scan limit
- `CloudflareWorker/` — server-side proxy holding the Anthropic API key

## Privacy

This app collects no analytics, has no ads, and requires no account. All workouts, meals, and progress data live in `UserDefaults` on the device. The only network calls are:

1. **AI Food Scanner** — photo sent to the Cloudflare Worker → Anthropic (Claude Vision). Photos are not stored.
2. **Barcode Scanner** — barcode looked up in the public [Open Food Facts](https://world.openfoodfacts.org) API.

See [`docs/privacy-policy.md`](docs/privacy-policy.md) for the full policy.

## License

All rights reserved. This is private source code — not licensed for public reuse.
