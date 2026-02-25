# PomodoroTimer

A native macOS 15+ Pomodoro timer. Lives in the menu bar with a minimal floating panel that blends transparently into your desktop while you work.

## Features

- **Menu bar app** — no Dock icon; dropdown shows current phase, remaining time, and all controls
- **Floating panel** — small, always-on-top transparent timer ring (220×220 pt) that stays out of the way; close button appears on hover
- **Focus / Short Break / Long Break** cycles with configurable durations and intervals
- **Forced break screen** — optional full-screen blurred overlay covers all connected displays at the end of each focus session; skip button available to resume focus immediately
- **Statistics** — daily/weekly/monthly/yearly bar charts, session history, CSV export
- **Global hotkeys** — system-wide shortcuts that work regardless of which app is focused
- **Accurate timer** — wall-clock date-diff; survives sleep/wake and app restarts

## Requirements

- macOS 15.0+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Install

Build and install PomodoroTimer into `/Applications/` with one command:

```bash
make install
```

After install, launch via **Spotlight** (⌘Space → "PomodoroTimer") or from `/Applications/`. The app runs entirely from the menu bar — no Dock icon.

To uninstall:

```bash
make uninstall
```

## Build from Source

```bash
# 1. Install XcodeGen
brew install xcodegen

# 2. Generate the Xcode project
xcodegen generate

# 3. Open in Xcode and run (⌘R)
open PomodoroTimer.xcodeproj
```

## Tests

```bash
xcodebuild test -scheme PomodoroTimer -destination 'platform=macOS'
```

26 unit tests cover `TimerEngine` (cycle logic, state transitions, sleep/wake, snapshot persistence) and `PersistenceService` (JSON roundtrips, atomic writes, CSV export).

## Data Storage

All data is stored locally — no network calls are ever made.

```
~/Library/Application Support/com.koki.PomodoroTimer/
  settings.json          — user preferences (durations, theme, hotkeys, …)
  timer_snapshot.json    — timer state saved on quit; restored on next launch
  sessions.json          — history of all completed/skipped sessions
```

Writes are atomic (write to temp → rename) to prevent corruption.

## Global Hotkey Defaults

| Action | Shortcut |
|---|---|
| Start / Pause | ⌃P |
| Skip | ⌃⇧S |
| Reset | ⌃R |
| Show / Hide Panel | ⌃⌥P |

Hotkeys work system-wide and require **App Sandbox** to be disabled (already configured). Bindings are configurable in **Settings → Shortcuts**.

## Architecture

```
PomodoroTimer/
  App/                     — @main entry + AppDelegate (wires all services)
  Models/                  — TimerState, AppSettings, Session, TimerSnapshot
  Core/
    TimerEngine/           — TimerEngine (date-diff countdown), SessionCycle (phase logic)
    Services/              — PersistenceService, HotkeyService (Carbon API), SleepWakeObserver
    Stats/                 — StatsStore, StatsAggregator
  ViewModels/              — TimerViewModel, SettingsViewModel, StatsViewModel
  WindowControllers/       — MenuBarController, MainPanelController,
                             BreakOverlayController, SettingsWindowController
  Views/
    MainPanel/             — MainPanelView, TimerRingView
    BreakOverlay/          — BreakOverlayView
    Settings/              — SettingsView + Timer, Shortcuts, Appearance tabs
    Stats/                 — StatsView, StatsChartView, SessionHistoryView
    MenuBar/               — MenuBarInfoView
  Utilities/               — TimeFormatter, CSVExporter
  Resources/               — Info.plist, entitlements, Assets.xcassets
PomodoroTimerTests/        — 26 unit tests
```

**Timer accuracy:** Stores the wall-clock start time and computes `remaining = remainingAtRunStart − (now − runStart)` on each tick — immune to CPU throttling, RunLoop stalls, and system sleep.

**Forced break screen:** `BreakOverlayController` creates one `NSWindow` per `NSScreen.screens` at `.screenSaverWindowLevel`, covering every connected display with an `NSVisualEffectView` blur. Windows are rebuilt on each show so display configuration changes (connect/disconnect) are always reflected.

**Global hotkeys:** Carbon `RegisterEventHotKey` API — the only macOS API for truly system-wide hotkeys without accessibility permissions. Requires App Sandbox disabled.

**Persistence:** JSON files with atomic writes. Simple and reliable for the data volume involved (< 10 KB for typical daily use).
