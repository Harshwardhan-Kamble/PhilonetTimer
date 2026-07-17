# 📖 Philonet Reading Timer

> A read-it-later iOS app that tracks how long you spend reading each article — with crash-safe dual-storage and transparent merge logic.

Built with **Swift 5.9** · **SwiftUI** · **iOS 17+**

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots & App Flow](#screenshots--app-flow)
- [Prerequisites](#prerequisites)
- [How to Run](#how-to-run)
- [Project Architecture](#project-architecture)
- [File Reference](#file-reference)
- [How the Timer Works](#how-the-timer-works)
- [Dual Storage & Merge Engine](#dual-storage--merge-engine)
- [Share Extension Setup](#share-extension-setup)
- [Debug Panel](#debug-panel)
- [Testing the App](#testing-the-app)
- [Troubleshooting](#troubleshooting)
- [Tech Stack](#tech-stack)
- [License](#license)

---

## Overview

Philonet is a simple iOS read-it-later app. Users can:

1. **Share** an article URL from Safari into the app (via Share Extension)
2. **Read** the article inside a built-in web view
3. **Track** how long they spend reading each article

The reading timer pauses when the app goes to background and resumes on foreground. Reading time is stored in **both memory and on disk** — they can disagree (e.g. after a crash). The app uses explicit **merge rules** to reconcile them, and a **debug panel** lets you inspect the logic in real time.

---

## Features

| Feature | Description |
|---------|-------------|
| 🔗 **Share Extension** | Share any URL from Safari directly into Philonet |
| 📖 **In-App Reader** | Read articles inside a WKWebView |
| ⏱️ **Live Timer HUD** | Floating glassmorphic timer overlay while reading |
| ⏸️ **Auto Pause/Resume** | Timer pauses on background, resumes on foreground |
| 💾 **Dual Storage** | Reading time maintained in both memory and on disk |
| 🔀 **Merge Engine** | 5 explicit rules to reconcile memory/disk disagreements |
| 🐜 **Debug Panel** | Inspect memory vs disk values, view merge audit log |
| 💥 **Simulate Crash** | Wipe memory to test disk recovery — time never goes backward |
| ➕ **Manual URL Add** | Paste a URL directly without using Safari |
| 📊 **Stats Dashboard** | Article count and total reading time at a glance |

---

## Screenshots & App Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│             │     │             │     │             │     │             │
│  Safari     │────▶│  Share      │────▶│  Article    │────▶│  Reader     │
│  (any URL)  │     │  Extension  │     │  List       │     │  + Timer    │
│             │     │             │     │             │     │             │
└─────────────┘     └─────────────┘     └──────┬──────┘     └─────────────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │  Debug      │
                                        │  Panel 🐜   │
                                        └─────────────┘
```

**Flow:**
1. User shares a URL from Safari → Share Extension saves it to App Group
2. On next app launch, pending articles are imported into the article list
3. User taps an article → Reader opens with live timer
4. Timer pauses on background, resumes on foreground
5. Debug Panel (🐜 icon) shows memory vs disk values and merge history

---

## Prerequisites

Before running the app, ensure you have:

| Requirement | Version | How to Check |
|-------------|---------|--------------|
| **macOS** | 13.0+ (Ventura or later) | Apple Menu → About This Mac |
| **Xcode** | 15.0+ | `xcode-select --version` or App Store |
| **XcodeGen** | Latest | `brew install xcodegen` |
| **iOS Simulator** | iOS 17.0+ | Comes with Xcode 15+ |
| **Apple Developer Account** | Free or Paid | For code signing (free account works for simulators) |

### Install XcodeGen (one-time)

```bash
brew install xcodegen
```

If you don't have Homebrew:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install xcodegen
```

---

## How to Run

### Step 1: Generate the Xcode Project

```bash
cd PhilonetTimer
xcodegen generate
```

This reads `project.yml` and generates `PhilonetTimer.xcodeproj` with both targets (host app + share extension) and all build settings pre-configured.

### Step 2: Open in Xcode

```bash
open PhilonetTimer.xcodeproj
```

### Step 3: Configure Code Signing

1. In Xcode, click on the **PhilonetTimer** project in the navigator (blue icon, top-left)
2. Select the **PhilonetTimer** target
3. Go to **Signing & Capabilities** tab
4. Check **"Automatically manage signing"**
5. Select your **Team** from the dropdown
6. **Repeat** for the **PhilonetShare** target

> ⚠️ Both targets MUST use the same team, otherwise the App Group entitlement won't work.

### Step 4: Select a Simulator

- In the Xcode toolbar (top center), click the device dropdown
- Select **iPhone 15 Pro** (or any iOS 17+ simulator)

### Step 5: Build & Run

Press **⌘R** (Command + R) or click the ▶️ Play button.

The app will compile, install on the simulator, and launch automatically.

### Quick Reference

```bash
# Full setup in 4 commands:
cd PhilonetTimer
brew install xcodegen          # skip if already installed
xcodegen generate
open PhilonetTimer.xcodeproj   # then ⌘R in Xcode
```

---

## Project Architecture

```
PhilonetTimer/
│
├── project.yml                              # XcodeGen project spec
├── README.md                                # This file
│
├── Shared/                                  # ── Shared between app & extension ──
│   ├── AppGroupConstants.swift              #    App Group ID, keys, container URL
│   └── SharedArticle.swift                  #    Minimal Codable struct for IPC
│
├── PhilonetTimer/                           # ── Host App Target ──
│   ├── PhilonetTimerApp.swift               #    @main entry point + lifecycle
│   │
│   ├── Models/
│   │   ├── Article.swift                    #    Article data model
│   │   └── TimeMergeLog.swift               #    MergeRule enum + TimeMergeEntry
│   │
│   ├── Services/
│   │   ├── ArticleStore.swift               #    Article CRUD + persistence
│   │   ├── TimeStore.swift                  #    ⭐ Dual-storage merge engine
│   │   └── ReadingTimer.swift               #    Per-article 1-second timer
│   │
│   ├── Views/
│   │   ├── ArticleListView.swift            #    Home screen (article list + stats)
│   │   ├── ArticleRowView.swift             #    Single article row component
│   │   ├── ReaderView.swift                 #    WebView + floating timer HUD
│   │   ├── WebViewRepresentable.swift       #    UIViewRepresentable for WKWebView
│   │   └── DebugPanelView.swift             #    Memory vs Disk inspection panel
│   │
│   └── Helpers/
│       └── TimeFormatter.swift              #    "4m 12s" / "00:04:12" formatting
│
└── PhilonetShare/                           # ── Share Extension Target ──
    ├── ShareViewController.swift            #    Receives URLs from Safari
    └── Info.plist                            #    Extension activation rules
```

### Target Configuration

| Target | Bundle ID | Type | Purpose |
|--------|-----------|------|---------|
| `PhilonetTimer` | `com.philonet.timer` | iOS App | Main app with article list, reader, timer |
| `PhilonetShare` | `com.philonet.timer.share` | App Extension | Safari share sheet integration |

Both targets share the **App Group** `group.com.philonet.timer` for cross-process data access.

---

## File Reference

### Shared Files (compiled into both targets)

| File | Purpose |
|------|---------|
| `AppGroupConstants.swift` | Defines the App Group suite name (`group.com.philonet.timer`), UserDefaults keys, and JSON filenames. Single source of truth for all cross-target identifiers. |
| `SharedArticle.swift` | Lightweight `Codable` struct (`url`, `title`, `dateShared`) that the Share Extension writes and the host app reads. Kept minimal so the extension doesn't depend on the full `Article` model. |

### Models

| File | Purpose |
|------|---------|
| `Article.swift` | Full article model with `id`, `url`, `title`, `dateAdded`, `readingTimeSeconds`. Includes a convenience initializer from `SharedArticle` and a computed `domain` property. |
| `TimeMergeLog.swift` | `MergeRule` enum (5 cases: `memoryWins`, `diskWins`, `clampToMax`, `deduplication`, `freshStart`) and `TimeMergeEntry` struct for the merge audit log. Each rule has a `displayName` and `colorName` for the debug UI. |

### Services (Business Logic)

| File | Purpose |
|------|---------|
| `TimeStore.swift` | ⭐ **Core of the app.** Maintains reading times in both an in-memory `Dictionary` and an on-disk JSON file. Implements the merge engine with 5 rules. Provides `flush`, `reconcileOnLaunch`, `simulateCrash`, and `forceFlush` operations. Logs every merge event for the debug panel. |
| `ReadingTimer.swift` | Fires a 1-second `Timer` that increments `TimeStore`'s in-memory counter on each tick. Added to `RunLoop.common` mode so it fires even during scrolling. Exposes `start`, `pause`, `resume`, `stop`. |
| `ArticleStore.swift` | `ObservableObject` managing the article array. Handles CRUD, JSON persistence to the App Group container, and importing pending articles from the Share Extension's UserDefaults queue. |

### Views (UI)

| File | Purpose |
|------|---------|
| `ArticleListView.swift` | Home screen with dark gradient background, stats header (article count + total reading time), sorted article list, empty state, manual URL add dialog, and navigation to the debug panel. |
| `ArticleRowView.swift` | Single list row: gradient icon, article title, domain, reading time badge, relative date. |
| `ReaderView.swift` | Full-screen WKWebView with a floating glassmorphic timer HUD (capsule with blur material). Integrates with `scenePhase` to pause/resume the timer on background/foreground. Flushes time to disk on disappear. |
| `WebViewRepresentable.swift` | `UIViewRepresentable` wrapping `WKWebView` with back/forward gesture support. |
| `DebugPanelView.swift` | Sheet with 3 sections: (1) per-article memory/disk/resolved comparison table, (2) action buttons (Force Flush, Simulate Crash, Clear Log), (3) scrollable merge audit log with color-coded rule badges. |

### Helpers

| File | Purpose |
|------|---------|
| `TimeFormatter.swift` | Three format modes: compact (`4m 12s`), timer display (`04:12`), and debug (`120.0s` / `nil`). |

---

## How the Timer Works

```
┌──────────────┐  1s tick  ┌──────────────┐   flush    ┌──────────────┐
│ ReadingTimer │─────────▶│  TimeStore   │──────────▶│  Disk (JSON) │
│  (Timer obj) │           │  (memory)    │            │  (App Group) │
└──────┬───────┘           └──────────────┘            └──────────────┘
       │
       │ scenePhase == .background → pause()
       │ scenePhase == .active     → resume()
```

1. When you open an article, `ReadingTimer.start()` is called with the article's current accumulated time
2. Every **1 second**, the timer fires and calls `TimeStore.incrementMemory()`
3. When the app **backgrounds**: timer pauses, `TimeStore.flushAll()` writes memory to disk
4. When the app **returns**: timer resumes from the paused value
5. When you **navigate back**: timer stops, final time is flushed and the article list is updated

### Why RunLoop.common?

The timer is added to `RunLoop.current.add(timer, forMode: .common)` so it continues firing even when the user is scrolling the web view. Without this, `Timer` defaults to `.default` mode and pauses during scroll tracking.

---

## Dual Storage & Merge Engine

This is the core complexity of the app. Reading time lives in two places simultaneously:

| Layer | Location | Updated When |
|-------|----------|-------------- |
| **Memory** | `Dictionary<UUID, TimeInterval>` inside `TimeStore` | Every 1-second timer tick |
| **Disk** | `times.json` in the App Group container | On flush (background, navigate away, periodic) |

### Why Two Layers?

- **Memory** is fast (no I/O overhead per tick) but volatile (lost on crash/kill)
- **Disk** is durable but slower and potentially stale

They can **disagree** — for example:
- After a crash: disk has the last flushed value, memory is empty
- During active reading: memory is ahead of disk (not yet flushed)
- After a Share Extension write: disk might have data memory doesn't know about

### The 5 Merge Rules

```
merge(memoryTime, diskTime) → (resolvedTime, rule)

  ┌─────────────────────────────────────────────────────────────┐
  │  1. Both nil?        → (0, freshStart)                     │
  │  2. Disk nil?        → (memory, memoryWins)    ← first save│
  │  3. Memory nil?      → (disk, diskWins)      ← crash recv  │
  │  4. Equal?           → (memory, deduplication)  ← no-op    │
  │  5. Memory > Disk?   → (memory, memoryWins)    ← normal    │
  │  6. Disk > Memory?   → (disk, diskWins)    ← never go back │
  └─────────────────────────────────────────────────────────────┘

  INVARIANT: resolved = max(memory ?? 0, disk ?? 0)
             Time NEVER goes backward.
```

| Rule | Color | Meaning |
|------|-------|---------|
| `freshStart` | 🔘 Gray | Brand new article, no prior data |
| `memoryWins` | 🟢 Green | Normal — memory is ahead, user is actively reading |
| `diskWins` | 🟠 Orange | Recovery — disk preserved time that memory lost |
| `deduplication` | 🔵 Blue | No-op — values already match |
| `clampToMax` | 🔴 Red | Safety clamp — should never occur if rules 1-6 are correct |

### Deduplication Guard

A subtle optimization: if `flushToDisk()` is called twice with the same memory value (e.g. app backgrounds twice quickly), the second call is skipped to avoid logging a spurious merge event.

```swift
if mem == lastFlushedValues[articleID] { return } // skip — already flushed
```

### Key Design Decision: Absolute Times, Not Deltas

The merge engine stores **cumulative totals**, never deltas. This makes the merge function:
- **Idempotent** — calling it twice produces the same result
- **Simple** — always `max(a, b)`, no addition that could double-count
- **Safe** — impossible to lose time or add phantom time

---

## Share Extension Setup

The Share Extension lets users share URLs from Safari (or any app) directly into Philonet.

### How It Works

1. User taps **Share** in Safari → selects **Philonet**
2. `ShareViewController` extracts the URL and page title
3. A `SharedArticle` struct is appended to a JSON array in **App Group UserDefaults**
4. When the host app launches/foregrounds, `ArticleStore.importPendingFromShareExtension()` reads and clears this queue

### Activation Rule (Info.plist)

```xml
<key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
<integer>1</integer>
```

This means the extension only appears when sharing **exactly one web URL** — not images, text, or files.

### App Group (IPC Mechanism)

Both targets use `group.com.philonet.timer`:
- Share Extension writes to `UserDefaults(suiteName: "group.com.philonet.timer")`
- Host app reads from the same UserDefaults suite
- Both read/write JSON files in the shared container directory

---

## Debug Panel

Access via the **🐜 ant icon** in the top-left of the article list.

### Sections

**1. Memory vs Disk Comparison Table**
```
Article              │ Memory  │ Disk    │ Resolved
─────────────────────┼─────────┼─────────┼─────────
Swift Concurrency    │ 45.0s   │ 42.0s   │ 45.0s  ← memoryWins
Apple Developer      │ 0.0s    │ 30.0s   │ 30.0s  ← diskWins (after crash)
```

**2. Action Buttons**
- **Force Flush** — Bypasses the deduplication guard and writes all memory to disk
- **Simulate Crash** — Clears all in-memory values while keeping disk intact
- **Clear Log** — Empties the merge audit log

**3. Merge Audit Log**
- Scrollable list of every merge event, newest first
- Each entry shows: article name, memory value, disk value, resolved value, rule badge (color-coded), and timestamp

---

## Testing the App

### Test 1: Basic Flow
1. Launch app → see empty state
2. Tap **+** → enter a URL (e.g. `https://en.wikipedia.org/wiki/Swift_(programming_language)`)
3. Article appears in list with `0s` reading time
4. Tap to read → timer counts up in the HUD
5. Tap Back → reading time is preserved in the list

### Test 2: Background/Foreground
1. Open an article, wait for timer to reach ~15s
2. Swipe up to go Home (background)
3. Wait 10 real seconds
4. Return to app → timer shows `15s` (NOT `25s`) — background time was NOT counted
5. Timer resumes counting from `15s`

### Test 3: Simulate Crash Recovery
1. Read an article for 30+ seconds
2. Open Debug Panel → tap **Force Flush** (ensures disk is synced)
3. Tap **Simulate Crash** → memory resets to `0.0s`, disk stays at `30.0s`
4. Dismiss panel → article still shows `30s` → **time never went backward**
5. Re-open Debug Panel → see orange **"Disk Wins"** badge in merge log

### Test 4: Share Extension (requires device or simulator Safari)
1. Build & run the app once
2. Open Safari → navigate to any page
3. Tap Share → find Philonet → tap Post
4. Switch back to Philonet → article appears in list

### Test 5: Persistence Across Kills
1. Add articles, read some
2. Stop the app in Xcode (⌘.)
3. Re-run (⌘R) → articles and times persist

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| **Build fails with signing error** | No team selected | Select your team in Signing & Capabilities for BOTH targets |
| **Share Extension not visible in Safari** | App not installed or extension disabled | Build & run the main app first. In Safari share sheet, tap "More" and toggle Philonet ON |
| **Timer doesn't pause on background** | `scenePhase` observer missing | Verify `.onChange(of: scenePhase)` exists in `ReaderView.swift` and `PhilonetTimerApp.swift` |
| **Articles disappear on relaunch** | App Group container not accessible | Confirm both targets have `group.com.philonet.timer` in their App Group entitlements |
| **Reading time resets to 0** | Memory cleared without flushing to disk first | Ensure `flushAll()` is called in the `.background` scene phase handler |
| **Debug panel shows all nil** | `TimeStore` not injected | Verify `.environmentObject(timeStore)` is passed through the view hierarchy |
| **`xcodegen generate` fails** | XcodeGen not installed | Run `brew install xcodegen` |
| **Timer stops during scrolling** | Timer not on common RunLoop mode | Verify `RunLoop.current.add(timer, forMode: .common)` in `ReadingTimer.swift` |

---

## Tech Stack

| Technology | Purpose |
|------------|---------|
| **Swift 5.9** | Programming language |
| **SwiftUI** | Declarative UI framework |
| **WKWebView** | Article rendering (via `UIViewRepresentable`) |
| **App Groups** | Cross-target data sharing (host ↔ extension) |
| **UserDefaults** (App Group suite) | Share Extension → Host App IPC |
| **JSON** (Codable) | On-disk persistence for articles, times, merge log |
| **XcodeGen** | Project file generation from `project.yml` |
| **Timer + RunLoop** | 1-second reading time tracking |
| **ScenePhase** | SwiftUI-native app lifecycle observation |

### iOS Frameworks Used

- `SwiftUI` — All views and navigation
- `WebKit` — `WKWebView` for article rendering
- `Social` — `SLComposeServiceViewController` for share extension
- `UniformTypeIdentifiers` — `UTType.url` for URL type matching
- `Combine` — `@Published` properties for reactive state
- `Foundation` — `FileManager`, `JSONEncoder/Decoder`, `Timer`

---

## License

MIT — see [LICENSE](LICENSE) for details.
