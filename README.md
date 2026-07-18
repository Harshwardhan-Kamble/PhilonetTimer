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
| ⏱️ **Toolbar Timer** | Standard system timer indicator inside the navigation bar |
| ⏸️ **Auto Pause/Resume** | Timer pauses on background, resumes on foreground |
| 💾 **Dual Storage** | Reading time maintained in both memory and on disk |
| 🔀 **Merge Engine** | Explicit rules to reconcile memory/disk disagreements |
| 🐜 **Debug Panel** | Inspect memory vs disk values, view merge audit log |
| 💥 **Simulate Crash** | Wipe memory to test disk recovery — time never goes backward |
| ➕ **Manual URL Add** | Paste a URL directly without using Safari |

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

### Install XcodeGen

```bash
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

1. In Xcode, click on the **PhilonetTimer** project in the navigator
2. Select the **PhilonetTimer** target
3. Go to **Signing & Capabilities** tab
4. Check **"Automatically manage signing"**
5. Select your **Team** from the dropdown
6. **Repeat** for the **PhilonetShare** target

### Step 4: Select a Simulator

- Select **iPhone 15** or any iOS 17+ simulator

### Step 5: Build & Run

Press **⌘R** (Command + R) or click the ▶️ Play button.

---

## Project Architecture

```
PhilonetTimer/
│
├── project.yml                              # XcodeGen project spec
├── README.md                                # This file
│
├── Shared/                                  # Shared between app & extension
│   ├── AppGroupConstants.swift              # App Group ID, keys, container URL
│   └── SharedArticle.swift                  # Minimal Codable struct for IPC
│
├── PhilonetTimer/                           # Host App Target
│   ├── PhilonetTimerApp.swift               # Entry point + lifecycle
│   │
│   ├── Models/
│   │   ├── Article.swift                    # Article data model
│   │   └── TimeMergeLog.swift               # MergeRule enum + TimeMergeEntry
│   │
│   ├── Services/
│   │   ├── ArticleStore.swift               # Article CRUD + persistence
│   │   ├── TimeStore.swift                  # Dual-storage merge engine
│   │   └── ReadingTimer.swift               # Per-article 1-second timer
│   │
│   ├── Views/
│   │   ├── ArticleListView.swift            # Home screen (article list)
│   │   ├── ArticleRowView.swift             # Single article row component
│   │   ├── ReaderView.swift                 # WebView + system navigation timer
│   │   ├── WebViewRepresentable.swift       # UIViewRepresentable for WKWebView
│   │   └── DebugPanelView.swift             # Memory vs Disk inspection panel
│   │
│   └── Helpers/
│       └── TimeFormatter.swift              # Timer string formatting
│
└── PhilonetShare/                           # Share Extension Target
    ├── ShareViewController.swift            # Receives URLs from Safari
    └── Info.plist                           # Extension activation rules
```

---

## File Reference

### Shared Files

| File | Purpose |
|------|---------|
| `AppGroupConstants.swift` | Defines the App Group suite name (`group.com.philonet.timer`), UserDefaults keys, and JSON filenames. |
| `SharedArticle.swift` | Lightweight `Codable` struct that the Share Extension writes and the host app reads. |

### Models

| File | Purpose |
|------|---------|
| `Article.swift` | Full article model with `id`, `url`, `title`, `dateAdded`, `readingTimeSeconds`. |
| `TimeMergeLog.swift` | `MergeRule` enum (rules: `memoryWins`, `diskWins`, `deduplication`, `freshStart`) and `TimeMergeEntry` struct for the merge audit log. |

### Services

| File | Purpose |
|------|---------|
| `TimeStore.swift` | Maintains reading times in both an in-memory `Dictionary` and an on-disk JSON file. Implements the merge engine. |
| `ReadingTimer.swift` | Fires a 1-second `Timer` that increments `TimeStore`'s in-memory counter on each tick. |
| `ArticleStore.swift` | Managing the article array, CRUD operations, and importing pending articles from the Share Extension. |

### Views

| File | Purpose |
|------|---------|
| `ArticleListView.swift` | Home screen with standard system list styling, sorted article list, empty state, manual URL add dialog, and debug panel entry. |
| `ArticleRowView.swift` | Single list row component. |
| `ReaderView.swift` | WKWebView with a timer HUD integrated into the navigation bar. |
| `WebViewRepresentable.swift` | UIViewRepresentable wrapper for WKWebView. |
| `DebugPanelView.swift` | Native grouped list sheet showing compared times, action controls (Force Flush, Simulate Crash, Clear Log), and color-coded merge logs. |

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

1. When you open an article, `ReadingTimer.start()` is called
2. Every **1 second**, the timer fires and calls `TimeStore.incrementMemory()`
3. When the app **backgrounds**: timer pauses, `TimeStore.flushAll()` writes memory to disk
4. When the app **returns**: timer resumes from the paused value
5. When you **navigate back**: timer stops, final time is flushed

---

## Dual Storage & Merge Engine

Reading time lives in two places simultaneously:

| Layer | Location | Updated When |
|-------|----------|-------------- |
| **Memory** | `Dictionary<UUID, TimeInterval>` inside `TimeStore` | Every 1-second timer tick |
| **Disk** | `times.json` in the App Group container | On flush (background, navigate away, periodic) |

### The 5 Merge Rules

```
merge(memoryTime, diskTime) → (resolvedTime, rule)

  ┌─────────────────────────────────────────────────────────────┐
  │  1. Both nil?        → (0, freshStart)                     │
  │  2. Disk nil?        → (memory, memoryWins)                │
  │  3. Memory nil?      → (disk, diskWins)                    │
  │  4. Equal?           → (memory, deduplication)             │
  │  5. Memory > Disk?   → (memory, memoryWins)                │
  │  6. Disk > Memory?   → (disk, diskWins)                    │
  └─────────────────────────────────────────────────────────────┘
```

---

## Share Extension Setup

The Share Extension lets users share URLs from Safari directly into Philonet.

### App Group

Both targets use `group.com.philonet.timer`:
- Share Extension writes to `UserDefaults(suiteName: "group.com.philonet.timer")`
- Host app reads from the same UserDefaults suite
- Both read/write JSON files in the shared container directory

---

## Debug Panel

Access via the **🐜 ant icon** in the top-left of the article list.

### Sections

1. **Memory vs Disk Comparison Table**
2. **Action Buttons**
   - **Force Flush** — Writes current memory directly to disk
   - **Simulate Crash** — Wipes memory to test disk recovery
   - **Clear Log** — Empties the merge log
3. **Merge Audit Log** — Historical log of merge events

---

## Testing the App

### Test 1: Basic Flow
1. Launch app
2. Tap **+** → enter a URL
3. Tap to read → timer counts up in the top right
4. Tap Back → reading time is preserved in the list

### Test 2: Background/Foreground
1. Open an article, wait for timer to reach ~15s
2. Swipe up to go Home (background)
3. Wait 10 seconds
4. Return to app → timer resumes from `15s` (background time not counted)

### Test 3: Simulate Crash Recovery
1. Read an article for 30+ seconds
2. Open Debug Panel → tap **Force Flush**
3. Tap **Simulate Crash** → memory resets to `0.0s`, disk stays at `30.0s`
4. Dismiss panel → article still shows `30s` (time recovered from disk)
5. Re-open Debug Panel → see orange **"Disk Wins"** badge in merge log

### Test 4: Share Extension
1. Build & run the app once
2. Open Safari → navigate to any page
3. Tap Share → find Philonet → tap Post
4. Switch back to Philonet → article appears in list
