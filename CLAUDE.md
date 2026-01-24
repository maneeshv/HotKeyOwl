# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Debug build
./scripts/build-debug.sh

# Release build (prompts to copy to /Applications)
./scripts/build.sh

# Build only (no scripts)
xcodebuild -scheme ShortcutOverlay -configuration Debug build

# Run tests
xcodebuild test -project ShortcutOverlay.xcodeproj -scheme ShortcutOverlay -destination 'platform=macOS'

# Launch built app from DerivedData
open ~/Library/Developer/Xcode/DerivedData/ShortcutOverlay-*/Build/Products/Debug/ShortcutOverlay.app
```

## Architecture Overview

ShortcutOverlay is a macOS menu bar app that displays keyboard shortcuts for the active application via a toggle-activated overlay. It uses SwiftUI + AppKit hybrid with MVVM pattern.

### Core Services (ShortcutOverlay/Services/)

- **HotkeyService**: Global keyboard monitoring via Carbon Hot Key API. Detects toggle of configurable hotkey (press to show, press again to hide), posts `.showOverlay`/`.hideOverlay` notifications
- **AppMonitorService**: Detects frontmost app using `NSWorkspace` notifications
- **ShortcutStore**: CRUD operations for shortcuts, persists to `~/Library/Application Support/HotKeyOwl/shortcuts.json`
- **PreferencesManager**: Manages `AppPreferences` (global hotkey config), persists to UserDefaults. **Note**: The `save()` method must not directly modify `@Published preferences` to avoid infinite recursion via `didSet`
- **iCloudSyncService**: Syncs preferences via `NSUbiquitousKeyValueStore` and shortcuts via iCloud Documents. Uses last-write-wins based on `lastModified` timestamps
- **ConfigurationManager**: Handles import/export of shortcuts as JSON files

### Key Patterns

- **Overlay Window**: `NSPanel` with `.borderless`, `.nonactivatingPanel`, `.floating` level - doesn't steal focus
- **Notification-driven**: Services communicate via `NotificationCenter` (see `Notification+Names.swift`)
- **Hotkey Recording**: `HotkeyRecorderView` and `ShortcutRecorderField` use local event monitors to capture key combinations

### Data Flow

1. User presses hotkey → `HotkeyService` detects via Carbon Hot Key API → posts `.showOverlay`
2. `AppDelegate` receives notification → queries `AppMonitorService` for current app → queries `ShortcutStore` for shortcuts
3. `OverlayWindow` displays `OverlayView` with shortcuts
4. User presses hotkey again → `HotkeyService` posts `.hideOverlay` → overlay dismissed

### Models

- **AppPreferences**: Global hotkey configuration (keyCode, modifiers, displayString)
- **AppShortcuts**: Per-app shortcut collection with `lastModified` for sync
- **ShortcutItem**: Individual shortcut (key, modifiers array, description)

## Requirements

- macOS 13.0+ (Ventura)
- Accessibility permission required for Carbon Hot Key API (global hotkey monitoring)
- iCloud entitlement for sync features

## Data Storage

- Shortcuts: `~/Library/Application Support/HotKeyOwl/shortcuts.json`
- Preferences: UserDefaults (`appPreferences` key)
- iCloud shortcuts: `<iCloud Container>/Documents/shortcuts.json`
