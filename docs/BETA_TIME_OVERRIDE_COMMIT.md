# Commit Message — Beta Time Override

## Summary

Add beta-only admin time override for testing historical data

## Description

Implements a time-snapshotted mode that allows the app to freeze "now" to a specific date/time for testing historical games. This enables deterministic replay of completed games without affecting production behavior.

### Key Features

- **Centralized time service**: Single source of truth for current time
- **Environment variable support**: `IOS_BETA_ASSUME_NOW=2024-02-15T04:00:00Z`
- **Admin UI**: Long-press gesture to access settings (debug only)
- **Snapshot filtering**: Excludes live games, shows only completed/scheduled
- **Visual indicator**: Subtle orange badge when active
- **Debug-only**: Production builds unaffected

### What Changed

**New Files**:
- `ScrollDown/Sources/Services/TimeService.swift` — Core time override logic
- `ScrollDown/Sources/Screens/AdminSettingsView.swift` — Admin control panel
- `docs/BETA_TIME_OVERRIDE.md` — Comprehensive documentation
- `.env.example` — Environment variable examples

**Modified Files**:
- `ScrollDown/Sources/AppConfig.swift` — Integration and filtering
- `ScrollDown/Sources/Screens/Home/HomeView.swift` — UI and filtering application

### Why This Matters

Enables beta testing of:
- Deep scrolling through historical data
- Recap replay with known outcomes
- Timeline validation with completed games
- Reveal state testing with deterministic data

Without requiring backend modifications or risking production stability.

### Usage

```bash
# Set environment variable
export IOS_BETA_ASSUME_NOW=2024-02-15T04:00:00Z

# Launch app from Xcode
# Orange "Testing mode" badge will appear
```

Or use Admin UI (long press on "Updated X ago" text).

### Safety

- Debug builds only (`#if DEBUG`)
- Production builds ignore all override attempts
- Comprehensive logging for diagnostics
- No changes to API or backend

---

## Suggested Commit Commands

### Single Commit (Recommended)

```bash
git add ScrollDown/Sources/Services/TimeService.swift
git add ScrollDown/Sources/Screens/AdminSettingsView.swift
git add ScrollDown/Sources/AppConfig.swift
git add ScrollDown/Sources/Screens/Home/HomeView.swift
git add docs/BETA_TIME_OVERRIDE.md
git add .env.example
git add ScrollDown.xcodeproj/project.pbxproj

git commit -m "feat: Add beta-only admin time override for testing historical data

Implements time-snapshotted mode that freezes 'now' to a specific date/time.
Enables deterministic replay of completed games without affecting production.

Key features:
- Centralized TimeService with environment variable support
- Admin UI with quick presets (NBA Opening Night, Super Bowl, etc.)
- Snapshot filtering (excludes live games)
- Visual indicator (orange badge)
- Debug-only enforcement

Usage: export IOS_BETA_ASSUME_NOW=2024-02-15T04:00:00Z

See docs/BETA_TIME_OVERRIDE.md for full documentation."
```

### Multiple Commits (Alternative)

```bash
# Commit 1: Core time service
git add ScrollDown/Sources/Services/TimeService.swift
git add ScrollDown/Sources/AppConfig.swift
git commit -m "feat: Add centralized TimeService with beta time override support

- Single source of truth for current time
- Environment variable support (IOS_BETA_ASSUME_NOW)
- Debug-only enforcement
- Comprehensive logging"

# Commit 2: Snapshot filtering
git add ScrollDown/Sources/Screens/Home/HomeView.swift
git commit -m "feat: Add snapshot mode filtering to HomeView

- Exclude live games in snapshot mode
- Show only completed and scheduled games
- Deterministic replay support"

# Commit 3: Admin UI
git add ScrollDown/Sources/Screens/AdminSettingsView.swift
git commit -m "feat: Add admin settings UI for time override

- Long-press gesture to access (debug only)
- Date picker with quick presets
- Visual indicator (orange badge)
- Clear override functionality"

# Commit 4: Documentation
git add docs/BETA_TIME_OVERRIDE.md
git add .env.example
git commit -m "docs: Add beta time override documentation

- Comprehensive usage guide
- Troubleshooting section
- Example .env configuration
- Technical architecture details"

# Commit 5: Xcode project
git add ScrollDown.xcodeproj/project.pbxproj
git commit -m "chore: Add new files to Xcode project"
```

---

## Changelog Entry

```markdown
### Added - Beta Time Override

- Beta-only admin time override for testing historical data
- Centralized TimeService for consistent time handling
- Environment variable support: `IOS_BETA_ASSUME_NOW`
- Admin settings UI with quick presets (NBA Opening Night, Super Bowl, etc.)
- Snapshot mode filtering (excludes live games)
- Visual indicator (orange badge) when snapshot mode active
- Comprehensive documentation in `docs/BETA_TIME_OVERRIDE.md`

### Changed - Beta Time Override

- AppDate.now() now respects TimeService override
- HomeView applies snapshot filtering in snapshot mode
- Long-press on data freshness text opens admin settings (debug only)
```

---

## Pull Request Template

```markdown
## 🎯 Beta Time Override — Time Travel for Testing

### Summary

Adds a beta-only admin feature that allows the app to operate in a time-snapshotted mode, freezing "now" to a specific date/time for testing historical data.

### Motivation

To enable deep beta validation of:
- Completed games with full timelines and recaps
- Large historical datasets (entire seasons)
- Reveal state behavior with deterministic data

Without requiring backend modifications or risking production stability.

### Implementation

1. **TimeService** — Centralized time resolution with override support
2. **Snapshot Filtering** — Excludes live games, shows only completed/scheduled
3. **Admin UI** — Long-press gesture to access settings (debug only)
4. **Visual Indicator** — Subtle orange badge when active
5. **Debug-Only** — Production builds completely unaffected

### Usage

```bash
export IOS_BETA_ASSUME_NOW=2024-02-15T04:00:00Z
# Launch app, orange badge appears
```

Or long-press "Updated X ago" text to access admin settings.

### Safety

- ✅ Debug builds only (`#if DEBUG`)
- ✅ Production builds ignore overrides
- ✅ No API changes
- ✅ No backend modifications
- ✅ Comprehensive logging

### Testing

- [x] Normal behavior without env var
- [x] Snapshot mode freezes time correctly
- [x] Live games excluded in snapshot mode
- [x] Completed games render fully
- [x] Admin UI accessible via long-press
- [x] Visual indicator appears/disappears correctly
- [x] Production builds unaffected

### Documentation

See `docs/BETA_TIME_OVERRIDE.md` for full documentation.

### Screenshots

_Add screenshots of:_
1. Orange "Testing mode" badge
2. Admin settings screen
3. Date picker with presets
```

---

## Release Notes

```markdown
## Beta Features

### Time Override (Beta Testing Only)

Added admin-only time override feature for testing historical data. This allows beta testers to "time travel" the app to specific dates to validate completed games, timelines, and recaps.

**Access**: Long-press on "Updated X ago" text in home screen (debug builds only)

**Usage**: Set environment variable `IOS_BETA_ASSUME_NOW=2024-02-15T04:00:00Z`

**Note**: This feature is not available in production builds and is strictly for beta testing purposes.
```
