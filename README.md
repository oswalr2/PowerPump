# PowerPump ⚡

All-in-one iOS fitness app: gym workouts, GPS running, sports tracking, nutrition, and progress — built with SwiftUI. Free, no ads, no account, in 5 languages.

## Features

- 🏋️ **Gym workouts** — log sets/reps/weight, build routines, follow Push/Pull/Legs programs, track streaks & PRs
- 🏃 **GPS Run / Walk** — live map with your route traced in real time, pace, distance, calories; works with the screen locked
- ✨ **AI route planner** — pick a distance and PowerPump plans a loop from where you are (A → B → C stages) and guides you turn-by-turn **by voice** so you never get lost
- 📅 **Guided walk/run programs** — 4 science-based plans (Walk to Lose Weight 20w, Run to Lose Weight 12w, Running Academy 8w, My First 5K 12w) with a voice coach and progressive unlocking
- 🚴 **28 sports** — cycling, yoga, swimming, boxing, tennis, skiing and more, each with its own history & route maps
- 🍴 **Nutrition** — calorie & macro tracking with a 90+ food database
- 📸 **AI Food Scanner** — snap a photo, get instant nutrition (Claude Vision via a Cloudflare proxy)
- 📊 **Barcode Scanner** — scan packaged products via Open Food Facts (3M+ items)
- 🍳 **27 recipes** — including vegan & vegetarian options
- 🤖 **AI Coach** — personalized plans that adapt to injuries, diet, and goals (fully local, no internet needed)
- 💧 **Reminders** — workout, hydration, meals, bedtime, and weekly weigh-in
- ⌚ **Apple Watch** — companion app with complication
- 📱 **Home & Lock Screen widgets** + Live Activities
- 🌐 **5 languages** — English, Spanish, French, Italian, Portuguese (BR), with a real-time voice coach in each
- 🩺 **Apple Health** integration
- 🌓 **Dark & Light mode**
- 🔒 **Privacy-first** — all data stays on device, no account required

## Project structure

```
SpartanBody/                     iOS app (main target; folder keeps its
├── Core/                        original name to avoid a risky project rename)
│   ├── Models/                  Data models
│   ├── Services/                Business logic (stores, HealthKit, routing…)
│   └── DesignSystem.swift       Colors, typography, components
├── Features/                    UI by feature (Dashboard, Workout, ...)
├── Components/                  Reusable views (charts, scanners)
└── Localizable.xcstrings        Translations (5 languages)

SpartanBodyWatch/                watchOS companion
SpartanBodyWidget/               Home/Lock screen widgets + Live Activities

CloudflareWorker/                Backend proxy for the AI scanner
docs/                            Privacy policy, App Store copy, launch guide
```

> The app is branded **PowerPump** everywhere the user sees it. Internal
> folder and Xcode-project names are still `SpartanBody` on purpose —
> renaming an Xcode project in place is error-prone and offers no user-facing
> benefit.

## Requirements

- Xcode 26+
- iOS 16.0+
- macOS for development
- Apple Developer account for distribution (a free Personal Team works for local testing on your own device)

## Running locally

```bash
open SpartanBody.xcodeproj
```

Select your iPhone as the destination and press **Run**. The `DEVELOPMENT_TEAM`
is intentionally empty in the project — set your team under **Signing &
Capabilities**, or pass it on the command line:

```bash
xcodebuild -scheme SpartanBody -destination 'platform=iOS,id=<device-id>' \
  -allowProvisioningUpdates DEVELOPMENT_TEAM=<your-team-id> build
```

For the AI Food Scanner to work, deploy the Cloudflare Worker first (see `CloudflareWorker/README.md`).

## Configuration

- `SpartanBody/Core/Config.swift` — Cloudflare Worker URL, weekly scan limit, support email
- `CloudflareWorker/` — server-side proxy that holds the Anthropic API key (the key is stored as a Cloudflare secret and never lives in this repo)

## Privacy

No analytics, no ads, no account. All workouts, meals, routes, and progress
live in `UserDefaults` on the device. The only network calls are:

1. **AI Food Scanner** — photo sent to the Cloudflare Worker → Anthropic (Claude Vision). Photos are not stored.
2. **Barcode Scanner** — barcode looked up in the public [Open Food Facts](https://world.openfoodfacts.org) API.
3. **AI route planner** — walking directions via Apple Maps (MKDirections); your location never leaves the device.

See [`docs/privacy-policy.md`](docs/privacy-policy.md) for the full policy.

## License

Source-available. © 2026 PowerPump — all rights reserved. Not licensed for reuse or redistribution without permission.
