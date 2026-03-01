# PomodoroTimer

A native macOS Pomodoro timer that lives in the menu bar. A small transparent floating panel shows the circular progress ring and controls; an optional full-screen overlay forces breaks at the end of every focus session.

---

## Features

### Timer
- Three phases: **Focus** (25 min), **Short Break** (5 min), **Long Break** (15 min) — all durations configurable
- Automatic phase cycling: short break after each focus session, long break every N sessions (default 4)
- Start / Pause / Skip / Reset controls on the floating panel and in the menu bar dropdown
- Optional auto-advance: start breaks or focus sessions automatically when a phase ends

### Floating Panel
- 220×220 pt transparent, always-on-top window — no title bar, no chrome
- Circular progress ring, color-coded by phase (warm brown / sage green / slate blue)
- Large monospaced MM:SS countdown in the center
- Close button that fades in on hover; draggable by clicking anywhere in the panel
- Panel position saved across launches

### Forced Break Screen
- When a focus session ends, an **optional full-screen overlay** covers every connected display
- Shows the break countdown centered on a blurred backdrop
- Includes a **skip** button; skipping immediately starts the next focus session
- Toggle on/off in Settings → Timer

### Menu Bar
- Timer icon and remaining time always visible in the menu bar
- Dropdown shows current phase, remaining time, and Start/Pause/Reset/Skip actions
- Quick access to **Open Timer Panel**, **Settings**, and **Quit**

### Statistics
- All sessions (focus and break, completed and skipped) are recorded automatically
- **Charts**: bar chart with selectable periods — Day (7 days), Week (4 weeks), Month (12 months), Year (3 years)
- **Session history**: scrollable list with phase, start time, duration, and completion status
- **CSV export** to the Downloads folder
- **Clear history** with confirmation dialog

### Global Hotkeys

| Action | Default |
|---|---|
| Start / Pause | ⌃P |
| Skip | ⌃⇧S |
| Reset | ⌃R |
| Show / Hide Panel | ⌃⌥P |

Work system-wide regardless of the focused app. Configurable in **Settings → Shortcuts**. Require App Sandbox to be disabled (already set).

### Persistence
- All data stored locally — no network calls
- `settings.json`, `timer_snapshot.json`, `sessions.json` in `~/Library/Application Support/com.koki.PomodoroTimer/`
- Timer state saved on quit; sessions that expired while the app was closed are silently completed on next launch
- Atomic writes (write to temp → rename) prevent data corruption

---

## Requirements

- macOS 15.0+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

---

## Install

```bash
make install
```

Builds a Release binary, installs it to `/Applications/`, and launches the app. No Dock icon — it runs entirely from the menu bar.

```bash
make uninstall   # remove from /Applications
```

## Build from Source

```bash
xcodegen generate          # generate PomodoroTimer.xcodeproj
open PomodoroTimer.xcodeproj  # then ⌘R in Xcode
```

## Run Tests

```bash
xcodebuild test -scheme PomodoroTimer -destination 'platform=macOS'
```

26 unit tests cover `TimerEngine` (cycle logic, state transitions, sleep/wake, snapshot persistence) and `PersistenceService` (JSON roundtrips, atomic writes, CSV export).

---

## Settings Reference

### Timer tab
| Setting | Range | Default |
|---|---|---|
| Focus duration | 5–90 min | 25 min |
| Short break | 1–30 min | 5 min |
| Long break | 5–60 min | 15 min |
| Long break after N sessions | 2–8 | 4 |
| Start breaks automatically | on/off | off |
| Start focus automatically | on/off | off |
| Cover screen at end of focus session | on/off | off |

### Shortcuts tab
Displays current key bindings. Edit `hotkeyStartPause`, `hotkeySkip`, `hotkeyReset`, `hotkeyTogglePanel` directly in `settings.json` if needed (Carbon key code + modifier flags).

### Appearance tab
System / Light / Dark theme selector (follows the floating panel).

---

## Architecture

```
PomodoroTimer/
  App/                      — @main entry (PomodoroTimerApp), AppDelegate (wires everything)
  Models/                   — AppSettings, TimerState enums, Session, TimerSnapshot
  Core/
    TimerEngine/            — TimerEngine (date-diff countdown), SessionCycle (phase logic)
    Services/               — PersistenceService, HotkeyService (Carbon), SleepWakeObserver
    Stats/                  — StatsStore (in-memory), StatsAggregator (chart bucketing)
  ViewModels/               — TimerViewModel, SettingsViewModel, StatsViewModel
  WindowControllers/        — MenuBarController, MainPanelController,
                              BreakOverlayController, SettingsWindowController
  Views/
    MainPanel/              — MainPanelView (ring + controls)
    BreakOverlay/           — BreakOverlayView (countdown + skip)
    MenuBar/                — MenuBarInfoView (dropdown content)
    Settings/               — SettingsView + Timer, Shortcuts, Appearance tabs
    Stats/                  — StatsView, StatsChartView, SessionHistoryView
  Utilities/                — TimeFormatter, CSVExporter
  Resources/                — Info.plist, entitlements, Assets.xcassets
PomodoroTimerTests/         — 26 unit tests (no TEST_HOST; sources compiled directly)
```

**Timer accuracy** — stores the wall-clock start time and computes `remaining = remainingAtRunStart − elapsed` on each 0.5 s tick. Immune to CPU throttling, RunLoop stalls, and system sleep.

**Break overlay** — `BreakOverlayController` iterates `NSScreen.screens` and creates one borderless `NSWindow` per display at `.screenSaverWindowLevel`, each backed by an `NSVisualEffectView`. Windows are rebuilt fresh on every `show()` so display configuration changes (connect/disconnect) are always reflected correctly.

**Global hotkeys** — Carbon `RegisterEventHotKey` API, the only macOS mechanism for truly system-wide shortcuts without requiring Accessibility permissions. Requires App Sandbox disabled (`ENABLE_APP_SANDBOX: NO` in `project.yml`).

**Observable pattern** — `@Observable` (Swift Observation framework, not `ObservableObject`) throughout. `@MainActor` on all services and view models.

## License

MIT — see [LICENSE](LICENSE).
