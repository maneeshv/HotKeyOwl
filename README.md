# HotKeyOwl

A macOS menu bar utility that displays keyboard shortcuts for the currently active application via a beautiful, toggle-activated overlay.

[![Build](https://github.com/maneeshv/HotKeyOwl/actions/workflows/build.yml/badge.svg)](https://github.com/maneeshv/HotKeyOwl/actions/workflows/build.yml)
<img src="https://img.shields.io/badge/macOS-13.0+-blue.svg" alt="macOS 13.0+">
<img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift 5.9">
<img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License">

## Features

✨ **Customizable Global Hotkey**: Set your own hotkey combination via Settings (default: `⌃⌥⌘0`)
🎯 **Auto-detection**: Automatically detects the frontmost application
🎨 **Beautiful Overlay**: Semi-transparent (80% opacity), centered overlay with app icon and shortcuts list
📱 **Menu Bar App**: Easy access via menu bar icon, no Dock presence
⌨️ **Interactive Shortcut Capture**: Press actual keys instead of typing - no more manual entry!
✏️ **Shortcut Management**: Add, edit, and delete shortcuts for any application
💾 **Persistent Storage**: Shortcuts saved locally in JSON format
📤 **Import/Export**: Back up and restore your shortcuts configuration as JSON
📦 **Pre-configured**: Includes shortcuts for Safari, Finder, Chrome, and VS Code

## Demo

**Press Your Hotkey** (default: `⌃⌥⌘0`): Overlay appears showing shortcuts for the current app
**Press Again**: Overlay disappears instantly

The overlay stays on top, centered, and preserves your active window focus.

**New in v1.1:**
- 🎛️ Customize your global hotkey in Settings
- ⌨️ Add shortcuts by pressing actual keys (no manual typing!)
- 📤 Export and import your shortcuts configuration

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0+ (for building)
- Accessibility permission (for hotkey registration)

## Installation

### Option 1: Build from Source

1. **Clone the repository**:
   ```bash
   git clone https://github.com/maneeshv/HotKeyOwl.git
   cd HotKeyOwl
   ```

2. **Build the app**:
   ```bash
   ./scripts/build.sh
   ```

3. **Grant Accessibility Permission** (see [Permissions](#permissions) below)

4. **Launch the app**:
   ```bash
   open /Applications/ShortcutOverlay.app
   ```

### Option 2: Development Mode

```bash
./scripts/run.sh
```

This builds and runs the Debug version automatically.

## Permissions

ShortcutOverlay requires **Accessibility** permission to register the global hotkey.

### Granting Permission

1. Launch ShortcutOverlay
2. When prompted, click "Open System Settings"
3. Navigate to **System Settings > Privacy & Security > Accessibility**
4. Enable **ShortcutOverlay** in the list
5. Restart ShortcutOverlay

**Without this permission**, the app will still work, but the global hotkey won't function.

### Why This Permission?

ShortcutOverlay uses macOS's Carbon Hot Key API to respond to your configured hotkey system-wide. This requires Accessibility permission as per macOS security requirements.

## Usage

### Show Shortcuts Overlay

1. **Press** your configured hotkey (default: `⌃⌥⌘0`)
2. The overlay appears showing shortcuts for the active application
3. **Press the hotkey again** to hide the overlay

### Configure Custom Hotkey

**NEW!** You can now set your own global hotkey:

1. Click the menu bar icon (⌘)
2. Select **"Settings..."** (or press `⌘,`)
3. Click the hotkey field and press your desired key combination
4. Click **"Save"**

**Tips:**
- Must include at least one modifier key (⌘⌃⌥⇧) or be a function key (F1-F12)
- Avoid system shortcuts like `⌘Q`, `⌘W`, `⌘Tab`
- The app will warn you if you try to use a reserved shortcut
- Your hotkey is saved automatically and persists across restarts

### Manage Shortcuts

**Via Menu Bar Icon**:

1. Click the menu bar icon (⌘)
2. Select **"Edit Shortcuts..."**
3. Choose an application from the dropdown
4. Click **"Add Shortcut"** to add a new one
5. **NEW!** Click the shortcut field and **press the actual keys** (e.g., press `⌘⇧N`)
   - The field turns red while recording
   - Press `Escape` to cancel
   - Click "Clear" to remove a captured shortcut
6. Enter a description (e.g., "New Window")
7. Click **"Save"**

**Edit or Delete**:
- Click the pencil icon to edit an existing shortcut
- Click the trash icon to delete

**Benefits of Interactive Capture:**
- ✅ No manual typing - press the actual keys!
- ✅ Automatically handles special keys (arrows, delete, function keys)
- ✅ Real-time validation prevents invalid combinations
- ✅ Visual feedback with color-coded states

### Choose Specific App

1. Click the menu bar icon
2. Hover over **"Choose App..."**
3. Select an application to quickly edit its shortcuts

### Import/Export Configuration

**NEW!** Back up and restore your shortcuts:

**Export:**
1. Click the menu bar icon → **"Export Configuration..."**
2. Choose save location
3. File is saved as pretty-printed JSON (e.g., `shortcuts-2026-01-09.json`)

**Import:**
1. Click the menu bar icon → **"Import Configuration..."**
2. Select a JSON configuration file
3. Choose merge strategy:
   - **Replace All**: Replace all existing shortcuts with imported ones
   - **Merge**: Keep existing shortcuts for unlisted apps, replace apps in import
   - **Append**: Add imported shortcuts to existing (may create duplicates)
4. Click your choice to import

**Use Cases:**
- 📁 **Backup**: Export before making major changes
- 🔄 **Sync**: Share configurations between machines
- 📝 **Version Control**: Track shortcuts in Git
- 👥 **Team Sharing**: Share standard shortcuts with colleagues
- ✏️ **Bulk Editing**: Export, edit JSON in text editor, re-import

## Pre-configured Apps

ShortcutOverlay includes default shortcuts for:

- **Safari**: New Tab, Close Tab, Reload, Focus URL Bar, etc.
- **Finder**: New Window, Move to Trash, Get Info, Duplicate, etc.
- **Chrome**: New Tab, Close Tab, Reload, Open DevTools, etc.
- **VS Code**: Quick Open, Command Palette, Toggle Sidebar, Format Document, etc.

You can customize or delete these defaults anytime.

## Architecture

### Technology Stack
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI + AppKit (hybrid)
- **Pattern**: MVVM with Services Layer
- **Persistence**: JSON file in `~/Library/Application Support/HotKeyOwl/`

### Key Components

**Services Layer**:
- `HotkeyService`: Global keyboard monitoring via Carbon Hot Key API
- `AppMonitorService`: Detects frontmost app using `NSWorkspace`
- `ShortcutStore`: JSON persistence and CRUD operations
- `PermissionManager`: Accessibility permission checks

**Views**:
- `OverlayWindow`: Borderless `NSPanel` that floats above other windows
- `OverlayView`: Main SwiftUI view displaying shortcuts
- `EditorView`: Shortcut management interface

**Models**:
- `ShortcutItem`: Individual keyboard shortcut
- `AppShortcuts`: Collection of shortcuts per app
- `AppInfo`: Application metadata (name, icon, bundle ID)

### Project Structure

```
ShortcutOverlay/
├── App/                    # Entry point and app delegate
│   ├── ShortcutOverlayApp.swift
│   ├── AppDelegate.swift
│   └── Info.plist
├── Models/                 # Data models
│   ├── ShortcutItem.swift
│   ├── AppShortcuts.swift
│   └── AppInfo.swift
├── Services/               # Core services
│   ├── HotkeyService.swift
│   ├── AppMonitorService.swift
│   ├── ShortcutStore.swift
│   └── PermissionManager.swift
├── Views/                  # UI components
│   ├── Overlay/
│   │   ├── OverlayWindow.swift
│   │   ├── OverlayView.swift
│   │   ├── AppHeaderView.swift
│   │   ├── ShortcutRowView.swift
│   │   └── KeyCapView.swift
│   └── Editor/
│       └── EditorView.swift
├── Extensions/
│   └── Notification+Names.swift
└── Resources/
    ├── Assets.xcassets
    └── ShortcutOverlay.entitlements
```

## Development

### Building

```bash
# Debug build
./scripts/run.sh

# Release build
./scripts/build.sh
```

### Running Tests

```bash
xcodebuild test \
    -project ShortcutOverlay.xcodeproj \
    -scheme ShortcutOverlay \
    -destination 'platform=macOS'
```

### Regenerating Xcode Project

If you modify `project.yml`:

```bash
xcodegen generate
```

## Technical Details

### Toggle-Based Hotkey Detection

ShortcutOverlay uses the Carbon Hot Key API for reliable global hotkey detection:

1. Registers a global hotkey with the system
2. On hotkey press → toggle overlay state (show if hidden, hide if shown)
3. Includes 0.3s debounce to prevent rapid toggling

This ensures:
- ✅ Single press toggles the overlay
- ✅ Works reliably across all applications
- ✅ No interference with normal typing

### Overlay Window

The overlay is an `NSPanel` with:
- `styleMask: [.borderless, .nonactivatingPanel]`
- `level: .floating`
- `collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary]`
- `canBecomeKey = false` (preserves active window focus)

### Data Storage

Shortcuts are stored in:
```
~/Library/Application Support/HotKeyOwl/shortcuts.json
```

Format:
```json
{
  "com.apple.Safari": {
    "bundleIdentifier": "com.apple.Safari",
    "appName": "Safari",
    "shortcuts": [
      {
        "id": "UUID",
        "key": "T",
        "modifiers": ["⌘"],
        "description": "New Tab"
      }
    ],
    "lastModified": "2026-01-09T12:00:00Z"
  }
}
```

## Troubleshooting

### Overlay Doesn't Appear

1. **Check Accessibility Permission**:
   - Open System Settings > Privacy & Security > Accessibility
   - Ensure ShortcutOverlay is enabled
   - Restart the app after granting permission

2. **Check if App is Running**:
   - Look for keyboard icon in menu bar
   - If not visible, launch from Applications

3. **Check Console Logs**:
   ```bash
   log stream --predicate 'process == "ShortcutOverlay"' --level debug
   ```

### No Shortcuts Showing

- The overlay will still appear but show "No Shortcuts Configured"
- Click the menu bar icon → "Edit Shortcuts..." to add shortcuts

### Hotkey Handler Paused

If you see "Hotkey handler paused" in logs:
- This can happen under heavy system load
- The app automatically resumes the handler
- If persistent, restart the app

### Keyboard Not Responding

- Make sure you're pressing your configured hotkey (default: ⌃⌥⌘0)
- Check that the hotkey hasn't been changed in Settings
- Verify Accessibility permission is granted

## FAQ

**Q: Can I change the global hotkey?**
A: Yes! Go to Settings and click the hotkey field to record a new combination.

**Q: Does this work with non-standard apps?**
A: Yes! It works with any app that has a bundle identifier. You can add shortcuts for any application.

**Q: Can I export/import shortcuts?**
A: Shortcuts are stored in `~/Library/Application Support/ShortcutOverlay/shortcuts.json`. You can back up or share this file.

**Q: Why does the overlay sometimes show for the wrong app?**
A: There's a brief delay (~100ms) in detecting app switches. Try holding the hotkey slightly longer.

**Q: Is this safe?**
A: Yes, it's completely safe. The app only responds to your configured hotkey and stores your shortcut reference data locally.

## Roadmap

Potential future features:

- [x] Custom hotkey configuration
- [x] Keyboard shortcut recorder (record shortcuts live)
- [x] iCloud sync
- [x] Dark/light theme toggle
- [x] Shortcut categories
- [x] Search/filter shortcuts
- [ ] Import shortcuts from app documentation
- [ ] Multiple overlay layouts
- [ ] Export to PDF/Markdown

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License

Copyright (c) 2026 Maneesh Shaji

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Acknowledgments

- Built with Swift and SwiftUI
- Icons from SF Symbols
- Inspired by CheatSheet and other keyboard shortcut apps

## Contact

- **GitHub**: [@maneeshv](https://github.com/maneeshv)
- **Issues**: [GitHub Issues](https://github.com/maneeshv/HotKeyOwl/issues)

---

Made with ❤️ by Maneesh Shaji
