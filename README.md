# Upcoming

A minimal SwiftUI menu bar app for macOS that hooks into the system calendar (EventKit) to show your upcoming events at a glance.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift 5.10+](https://img.shields.io/badge/Swift-5.10%2B-orange)

## Features

- **Menu bar label** — always-visible icon with your next event's name and a live countdown (e.g. `Meeting · in 3h`), ticking precisely on each minute boundary
- **Popover** — click the menu bar item to expand; click again to dismiss
- **Three sections** — events split into **Today**, **Tomorrow**, and **This Week** (next 7 days)
- **Up Next banner** — highlights the currently-in-progress event or the soonest upcoming one
- **Event details** — color-coded calendar accent bar, location, attendee count, meeting-link badge, conflict warnings
- **Context menu** — right-click any event row to copy the title or notes
- **Auto-refresh** — calendar data refreshes every 60 seconds; events re-fetch when the popover opens
- **Low CPU** — idle at ~0% CPU between minute ticks

## Prerequisites

- macOS 14 (Sonoma) or later
- Xcode (with command-line tools) — any recent version
- Swift 5.10+

## Clone & Build

```bash
# Clone the repo
git clone git@github.com:radther/Upcoming.git
cd Upcoming

# Build the release binary
swift build -c release

# Assemble and ad-hoc codesign the .app bundle
chmod +x bundle.sh
./bundle.sh

# Launch
open build/Upcoming.app
```

## How It Works

1. **SwiftPM executable target** — the app is a single `Sources/Upcoming/` target built via `swift build`. No Xcode project file needed.
2. **Bundle assembly** — `bundle.sh` copies the release binary into a proper `Upcoming.app` structure with `Info.plist` and ad-hoc code signs it with hardened runtime + calendar entitlements.
3. **`LSUIElement`** — the `Info.plist` sets this to `true`, so the app runs as a menu-bar-only agent (no Dock icon, no main window).
4. **Calendar access** — on first launch the system prompts for calendar permission (`NSCalendarsFullAccessUsageDescription`). If denied, the popover shows a button to open System Settings.

## Project Layout

```
Upcoming/
├── Package.swift                  # SwiftPM package definition (macOS 14+)
├── bundle.sh                      # Builds .app bundle from swift build output
├── README.md
└── Sources/Upcoming/
    ├── UpcomingApp.swift          # @main entry point, MenuBarExtra scene
    ├── CalendarManager.swift       # EventKit access, fetch, categorization
    ├── Clock.swift                # Minute-boundary timer for live countdowns
    ├── PopoverContentView.swift   # Header, banner, sections, footer
    ├── MenuBarLabel.swift          # Menu bar icon + next-event countdown
    ├── EventRowView.swift          # Individual event row (time, title, meta)
    ├── EventFormatting.swift       # Date formatters + relative countdown logic
    ├── Info.plist                  # LSUIElement, calendar usage descriptions
    └── Upcoming.entitlements      # Calendar access entitlement
```

## Rebuilding After Changes

```bash
swift build -c release && ./bundle.sh
# Then relaunch:
open build/Upcoming.app
```

## License

Private repository — all rights reserved.
