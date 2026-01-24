# AGENTS.md

This file guides agentic coding assistants working in this repo.
It consolidates commands, style, and repo conventions.

## Repository Summary
- macOS menu bar app showing app-specific shortcuts.
- Swift 5.9+, SwiftUI + AppKit hybrid, MVVM-ish with services.
- Main module: ShortcutOverlay, app name in scripts is HotKeyOwl.
- Scheme name: ShortcutOverlay; project file: ShortcutOverlay.xcodeproj.

## Build, Run, and Test
Use macOS 13+, Xcode 14+.
Build outputs land in `build/` when using scripts.

Debug build (script):
```bash
./scripts/build-debug.sh
```

Release build (script, prompts to copy to /Applications):
```bash
./scripts/build.sh
```

Build only (no scripts, Debug):
```bash
xcodebuild -scheme ShortcutOverlay -configuration Debug build
```

Run tests (no dedicated test target found yet):
```bash
xcodebuild test -project ShortcutOverlay.xcodeproj -scheme ShortcutOverlay -destination 'platform=macOS'
```

Run a single test (replace placeholders when tests exist):
```bash
xcodebuild test -project ShortcutOverlay.xcodeproj -scheme ShortcutOverlay -destination 'platform=macOS' -only-testing:ShortcutOverlayTests/SomeTestCase/testExample
```

Regenerate Xcode project if `project.yml` changes:
```bash
xcodegen generate
```

Launch built app from DerivedData:
```bash
open ~/Library/Developer/Xcode/DerivedData/ShortcutOverlay-*/Build/Products/Debug/ShortcutOverlay.app
```

Lint/format:
- No SwiftLint/SwiftFormat config found; use Xcode formatting defaults.

## Project Layout
- `ShortcutOverlay/App`: app entry point and delegates.
- `ShortcutOverlay/Models`: core data models.
- `ShortcutOverlay/Services`: hotkey, app monitor, persistence, sync.
- `ShortcutOverlay/ViewModels`: MVVM view models.
- `ShortcutOverlay/Views`: SwiftUI views, overlay, settings.
- `ShortcutOverlay/Utilities`: parsers and grouping helpers.
- `scripts/`: build scripts and shared config.

## Code Style and Conventions
**Imports**
- Use module imports only (no relative imports).
- Order imports from system to framework: Foundation, Combine, AppKit/SwiftUI, then Carbon or other system libs.

**Formatting**
- 4-space indentation; align wrapped parameters vertically.
- Keep lines readable; prefer SwiftUI view builders over long inline chains.
- Use `// MARK: -` sections for structure (properties, lifecycle, helpers).

**Naming**
- Types use UpperCamelCase; vars and functions use lowerCamelCase.
- SwiftUI view files match the view type name.
- Use descriptive boolean names (example: `isOverlayShown`).

**Types and State**
- Prefer `struct` for SwiftUI views and model types.
- Use `final class` for view models and services.
- Expose `@Published private(set)` for read-only public state.
- Use `@MainActor` on UI-facing classes (see `EditorViewModel`).

**SwiftUI + AppKit**
- Keep AppKit wrappers isolated (example: `OverlayWindow`, `VisualEffectBlur`).
- Use `NSPanel` with `.borderless` and `.nonactivatingPanel` for overlay behavior.
- Use `NSHostingView` for window content.

**Concurrency**
- Prefer `Task` and async/await for persistence and sync.
- Use `DispatchQueue.main` or `@MainActor` for UI updates.
- Use `[weak self]` in async closures to avoid retain cycles.

**Error Handling**
- Prefer `throws` and `do-catch` for IO and parsing.
- Surface user-facing failures with `NSAlert` or SwiftUI state.
- Log errors with `print` for now (logs already include simple markers).
- `fatalError` is only used for `init(coder:)` unavailability.

**Persistence**
- Preferences stored in UserDefaults with `PreferencesPersistence`.
- Shortcuts stored in `~/Library/Application Support/ShortcutOverlay/shortcuts.json`.
- When saving preferences, do not mutate `@Published preferences` inside `save()` to avoid recursion.

**Sync**
- iCloud sync uses last-write-wins via `lastModified`.
- Keep `isApplyingRemote` guards to avoid sync loops.

**Notifications**
- Use `Notification.Name` constants from `Notification+Names.swift`.
- Post `.showOverlay` and `.hideOverlay` for overlay control.

**Validation**
- Hotkey validation uses `PreferencesManager.validate` and `isSystemShortcut`.
- Shortcut parsing uses `ShortcutParser` and surfaces errors in UI state.

**Testing**
- No test targets currently present; if you add tests, keep them in `ShortcutOverlayTests` and use `xcodebuild -only-testing`.

## Agent Workflow Preferences
- Use context7 for library docs when needed.
- If Python tooling is introduced, prefer `uv` for dependency management.
- Avoid touching unrelated local changes in a dirty worktree.

## Cursor/Copilot Rules
- No `.cursor/rules`, `.cursorrules`, or `.github/copilot-instructions.md` found in this repo.

## Notes
- Accessibility permission is required for global hotkey monitoring.
- App name and bundle ID are set in `scripts/config.sh`.
- Build scripts sign the app for TCC compatibility (release build).
- Use `ConfigurationManager` for import/export flows.
- Prefer `ShortcutStore` and `PreferencesManager` as single sources of truth.
- Maintain app appearance via `preferencesManager.appearanceMode`.
- Use `LaunchAtLoginService` for startup toggles.
- Respect MVVM boundaries: views -> view models -> services.

## File References
- `CLAUDE.md` contains architecture and command notes.
- `scripts/build.sh` and `scripts/build-debug.sh` are canonical build scripts.
- `ShortcutOverlay/App/AppDelegate.swift` coordinates services and windows.
- `ShortcutOverlay/Services/` hosts persistence, hotkey, and sync logic.

## When Unsure
- Prefer minimal edits aligned with existing patterns.
- Ask before introducing new dependencies or build tools.
- Keep UI changes consistent with the current visual language.

## End
- Keep this file up to date as tools or conventions change.
