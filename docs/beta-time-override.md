# Snapshot Mode (Time Override)

Debug-only feature that freezes the app's clock to a specific date for testing historical data.

## How It Works

All time logic flows through `TimeService.shared.now` and `AppDate.now()`. No view or viewmodel calls `Date()` directly.

When active:
- "Now" is frozen to the specified date
- Only completed and scheduled games appear (live games excluded)
- An orange badge shows the active snapshot date on the home screen

## Enabling

### Environment Variable

```bash
export IOS_BETA_ASSUME_NOW=2024-10-23T04:00:00Z
```

Format: ISO8601 with timezone. App reads this on launch (debug builds only).

### Admin Settings UI

**Note:** The long-press trigger on the freshness text is not currently rendered in the home layout. Set `showingAdminSettings = true` in code to access. Quick presets available:
- NBA Opening Night 2024
- Super Bowl LVIII
- March Madness 2024 Final
- Yesterday / One Week Ago

## Architecture

```
TimeService (singleton)
    ├── overrideDate: Date?
    ├── now: Date (computed)
    └── isSnapshotModeActive: Bool

AppDate.now() → TimeService override → mock dev date → real time

AppConfig.filterGamesForSnapshotMode() → excludes live games
```

### Key Files

- `Sources/Services/TimeService.swift` — Time override logic
- `Sources/AppConfig.swift` — Integration and game filtering
- `Sources/Screens/Home/HomeView.swift` — UI indicator
- `Sources/Screens/AdminSettingsView.swift` — Admin controls

## Production Safety

Snapshot mode is **debug-only**. In release builds:
- `TimeService.shared.now` returns `Date()`
- `setTimeOverride()` is ignored
- Admin Settings is inaccessible
- No snapshot filtering occurs

## Troubleshooting

| Problem | Check |
|---------|-------|
| Not activating | Verify debug build, correct ISO8601 format, relaunched after export |
| No games appearing | Backend may lack data for that date; try a preset |
| Live games still showing | Confirm orange badge is visible; check logs for "excluded X live games" |

Logs: filter Console.app by `com.scrolldown.app`, category `time`.
