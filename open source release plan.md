# Plan: Open Source Release for HotKeyOwl

Prepare the HotKeyOwl macOS app for open source release with MIT license, rebranded bundle identifiers, and GitHub infrastructure.

## User Choices
- **License**: MIT
- **Bundle ID**: Change from `com.docketai.HotKeyOwl` to `io.hotkeyowl.HotKeyOwl`
- **Repository**: `github.com/maneeshv/HotKeyOwl`
- **CI/CD**: GitHub Actions build check

---

## Files to Create (8 files)

### 1. `LICENSE`
MIT License with copyright 2026 Maneesh Shaji

### 2. `CONTRIBUTING.md`
Contribution guidelines including:
- Bug reporting process
- Feature request process
- Development setup (reference AGENTS.md)
- Pull request process
- Code style guidelines

### 3. `CODE_OF_CONDUCT.md`
Contributor Covenant v2.1 (industry standard)

### 4. `.github/workflows/build.yml`
GitHub Actions workflow:
- Triggers on push/PR to main
- Uses macos-14 runner
- Installs XcodeGen, generates project
- Builds Debug and Release (code signing disabled for CI)

### 5. `.github/ISSUE_TEMPLATE/bug_report.md`
Bug report template with environment info, reproduction steps

### 6. `.github/ISSUE_TEMPLATE/feature_request.md`
Feature request template

### 7. `.github/pull_request_template.md`
PR template with checklist and type of change

---

## Files to Modify (6 files)

### 1. `project.yml`
- Line 4: `bundleIdPrefix: com.docketai` → `bundleIdPrefix: io.hotkeyowl`
- Line 29: `PRODUCT_BUNDLE_IDENTIFIER: com.docketai.HotKeyOwl` → `io.hotkeyowl.HotKeyOwl`

### 2. `scripts/config.sh`
- Line 7: `BUNDLE_ID="com.docketai.HotKeyOwl"` → `BUNDLE_ID="io.hotkeyowl.HotKeyOwl"`

### 3. `ShortcutOverlay/App/AppConstants.swift`
- Line 9: Fallback bundle ID `"com.docketai.HotKeyOwl"` → `"io.hotkeyowl.HotKeyOwl"`

### 4. `ShortcutOverlay/Extensions/Notification+Names.swift`
- Update all notification prefixes from `com.docketai.HotKeyOwl` to `io.hotkeyowl.HotKeyOwl`

### 5. `ShortcutOverlay/Resources/ShortcutOverlay.entitlements`
- iCloud container: `iCloud.com.docketai.ShortcutOverlay` → `iCloud.io.hotkeyowl.ShortcutOverlay`
- Keychain group: `com.docketai.ShortcutOverlay` → `io.hotkeyowl.ShortcutOverlay`

### 6. `README.md`
- Line 45: Clone URL → `https://github.com/maneeshv/HotKeyOwl.git`
- Line 46: `cd ShortcutOverlay` → `cd HotKeyOwl`
- Lines 423-425: Update contact info with actual GitHub username and issues URL
- Add CI badge at top

---

## Implementation Order

1. **Create community files** (LICENSE, CONTRIBUTING.md, CODE_OF_CONDUCT.md)
2. **Create GitHub infrastructure** (.github folder with workflows and templates)
3. **Update bundle identifiers** (project.yml, config.sh, AppConstants.swift, Notification+Names.swift, entitlements)
4. **Regenerate Xcode project** (`xcodegen generate`)
5. **Update README** (URLs and badge)
6. **Verify build** (`./scripts/build-debug.sh`)

---

## Important: iCloud Breaking Change

Changing the iCloud container identifier will break sync for existing users:
- Existing synced data will become inaccessible from the new identifier
- Users will need to re-enable iCloud sync after updating
- Document this clearly in release notes

---

## Verification

1. Build succeeds:
   ```bash
   xcodegen generate && ./scripts/build-debug.sh
   ```

2. No old bundle IDs remain:
   ```bash
   grep -r "com.docketai" . --include="*.swift" --include="*.yml" --include="*.sh" --include="*.entitlements"
   # Should return nothing
   ```

3. App launches and functions correctly

4. Push to GitHub and verify Actions workflow passes
