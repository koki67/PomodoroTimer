# PomodoroTimer

A native macOS 14+ Pomodoro timer. Lives in the menu bar with a minimal floating panel UI that blends into your desktop while you work.

## Features

- **Menu bar app** — no Dock icon; dropdown shows current mode, remaining time, and all controls
- **Floating panel** — small, always-on-top timer window that auto-shrinks and fades after you start a session
- **Focus / Short Break / Long Break** cycles with configurable durations and intervals
- **Ambient sounds** — 6 looping soundscapes (rain, crickets, river, café, city traffic, airplane)
- **Local notifications** with selectable sounds when sessions end
- **Statistics** — daily/weekly/monthly/yearly bar charts, session history, CSV export
- **Global hotkeys** — system-wide shortcuts that work regardless of focused app
- **Accurate timer** — uses wall-clock date-diff; survives sleep/wake and app restarts

## Requirements

- macOS 14.0+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Install as a Native App (Recommended)

Build and install PomodoroTimer into `/Applications/` with one command:

```bash
make install
```

After install, launch any time via **Spotlight** (⌘Space → "PomodoroTimer") or directly from
`/Applications/`. The app runs entirely from the menu bar — no Dock icon.

To uninstall:

```bash
make uninstall
```

## How to Build and Run (via Xcode)

```bash
# 1. Install XcodeGen if you haven't already
brew install xcodegen

# 2. Generate the Xcode project
cd /path/to/PomodoroTimer
xcodegen generate

# 3. Open in Xcode and run
open PomodoroTimer.xcodeproj
# Press ⌘R or Product → Run
```

The app runs as a menu bar accessory (no Dock icon). Click the timer icon in your menu bar to access all controls.

## How to Run Tests

```bash
xcodebuild test -scheme PomodoroTimer -destination 'platform=macOS'
```

26 unit tests cover `TimerEngine` (cycle logic, state transitions, sleep/wake handling, snapshot persistence) and `PersistenceService` (JSON roundtrips, atomic writes, CSV export).

## How Data Is Stored

All data is stored locally in:

```
~/Library/Application Support/com.koki.PomodoroTimer/
  settings.json          — user preferences (durations, theme, hotkeys, …)
  timer_snapshot.json    — timer state saved on quit; restored on next launch
  sessions.json          — history of all completed/skipped focus sessions
```

Data is written atomically (write to temp file → rename) to prevent corruption. No network calls are ever made.

## How to Add or Replace Ambient Audio Files

The app ships with silent placeholder `.m4a` files. To use real ambient sounds:

1. Prepare looping `.m4a` audio files for any of the six soundscapes:

   | Filename | Sound |
   |---|---|
   | `rain.m4a` | Rain |
   | `crickets.m4a` | Crickets |
   | `river.m4a` | River |
   | `cafe.m4a` | Café |
   | `city_traffic.m4a` | City Traffic |
   | `airplane.m4a` | Airplane |

2. Drop the files into `PomodoroTimer/Resources/Sounds/`

3. Rebuild the project (`xcodegen generate && xcodebuild …`)

The app loops each file indefinitely while a session is running. Any `.m4a` compatible with `AVAudioPlayer` on macOS will work (AAC, ALAC, etc.). Files encoded at 44.1 kHz stereo work best.

> **Tip:** Free ambient loop packs are available at [freesound.org](https://freesound.org) (CC0 licence) and [Pixabay](https://pixabay.com/sound-effects/). Export/convert to `.m4a` with `afconvert` or QuickTime Player → Export.

## Global Hotkey Defaults

| Action | Shortcut |
|---|---|
| Start / Pause | ⌃P |
| Skip | ⌃⇧S |
| Reset | ⌃R |
| Show / Hide Panel | ⌃⌥P |

Hotkeys work system-wide regardless of which app is in focus. They require **App Sandbox** to be disabled (already configured). You can view current bindings in **Settings → Hotkeys**.

## Architecture

```
PomodoroTimer/
  App/                     — @main entry + AppDelegate (wires all services)
  Models/                  — TimerState, AppSettings, Session, TimerSnapshot, AmbientSound
  Core/
    TimerEngine/           — TimerEngine (date-diff countdown), SessionCycle (phase logic)
    Services/              — PersistenceService, NotificationService, AudioService,
                             HotkeyService (Carbon API), SleepWakeObserver
    Stats/                 — StatsStore, StatsAggregator
  ViewModels/              — TimerViewModel, SettingsViewModel, StatsViewModel
  WindowControllers/       — MenuBarController, MainPanelController, SettingsWindowController
  Views/
    MainPanel/             — MainPanelView, ModeTabsView, TimerControlsView, StatusBarView
    Settings/              — SettingsView + 5 tab views
    Stats/                 — StatsView, StatsChartView, SessionHistoryView
    MenuBar/               — MenuBarInfoView
  Utilities/               — TimeFormatter, CSVExporter
  Resources/               — Info.plist, entitlements, Assets.xcassets, Sounds/
PomodoroTimerTests/        — 26 unit tests for TimerEngine and PersistenceService
```

**Persistence:** JSON files with atomic writes. Simple and reliable for the data volume involved (< 10 KB for typical daily use).

**Timer accuracy:** The engine stores the wall-clock time when each run starts and computes `remaining = remainingAtRunStart - (now - runStart)` on each tick. This makes it immune to CPU throttling, RunLoop stalls, and system sleep.

**Global hotkeys:** Carbon `RegisterEventHotKey` API — the only macOS API for truly system-wide hotkeys without accessibility permissions. Requires App Sandbox disabled.
