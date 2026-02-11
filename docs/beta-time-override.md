# Beta Time Override — Snapshot Mode

## Purpose

The **Time Override** (Snapshot Mode) feature allows the Scroll Down iOS app to operate in a time-snapshotted mode where "now" is frozen to a specific date and time. This enables:

- **Historical data testing**: Replay completed games as if they're happening now
- **Deterministic validation**: Test timelines, recaps, and reveal states with known data
- **Deep scrolling**: Explore large datasets from past seasons
- **Beta validation**: Verify app behavior without risky backend hacks

This is **strictly a beta/testing feature** and has no impact on production behavior.

---

## How It Works

### 1. Time Centralization

All time-based logic in the app now flows through a single source of truth:

- **`TimeService.shared.now`** — Returns current time (real or overridden)
- **`AppDate.now()`** — High-level wrapper that respects TimeService

**No view or viewmodel should call `Date()` directly for logic.**

### 2. Priority Order

When determining "now", the app follows this priority:

1. **TimeService override** (if set) — Beta snapshot mode
2. **Mock mode dev date** (if in mock mode) — Development testing
3. **Real system time** (default) — Production behavior

### 3. Snapshot Mode Filtering

When snapshot mode is active:

- **Only completed and scheduled games appear**
- **Live/in-progress games are excluded**
- **Backend live status is ignored**

This ensures:
- Deterministic replay
- No partial timelines
- No unexpected live updates

---

## How to Enable

### Option 1: Environment Variable (Recommended)

Set the environment variable before launching the app:

```bash
export IOS_BETA_ASSUME_NOW=2024-02-15T04:00:00Z
```

**Format**: ISO8601 with timezone (e.g., `2024-02-15T04:00:00Z`)

The app will automatically load this on launch and freeze time to that moment.

### Option 2: Admin Settings UI (Debug Builds Only)

1. Launch the app in a debug build
2. Navigate to the home screen
3. **Long press** (2 seconds) on the data freshness text at the top
4. Admin Settings screen will appear
5. Choose "Set Snapshot Date" or select a quick preset

**Quick Presets Available:**
- NBA Opening Night 2024
- Super Bowl LVIII
- March Madness 2024 Final
- Yesterday at 4:00 AM
- One Week Ago

---

## What It Affects

### Home Feed

- **Earlier section**: Games completed before snapshot date
- **Today section**: Games completed on snapshot date
- **Coming Up section**: Games scheduled after snapshot date
- **Live games**: Excluded entirely

### Game Detail

- Timeline, recap, and reveal controls work normally
- Summary generation respects reveal state
- Social posts filtered to snapshot date context

### What It Doesn't Affect

- API endpoints (backend is unchanged)
- User preferences (reveal states, social opt-in)
- Production builds (feature is debug-only)

---

## Visual Indicator

When snapshot mode is active, a subtle orange badge appears at the top of the home screen:

```
🕐 Testing mode: Feb 15, 2024 at 4:00 AM
```

This badge:
- Only appears in debug builds
- Never shows in production
- Can be tapped to access admin settings

---

## Logging & Diagnostics

Snapshot mode logs key events to help with debugging:

### On Enable
```
⏰ Time override enabled: 2024-02-15T04:00:00Z
⏰ Real device time: 2025-01-09T12:30:00Z
```

### On Game Filtering
```
⏰ Snapshot mode: excluded 3 live/unknown games
```

### On Disable
```
⏰ Time override disabled, using real time
```

All logs use the `com.scrolldown.app.time` category and can be filtered in Console.app.

---

## Safety & Validation

### Pre-Flight Checklist

Before using snapshot mode:
- ✅ Ensure you're in a debug build
- ✅ Verify the snapshot date is in the past (for historical data)
- ✅ Check that backend has data for that date range
- ✅ Confirm no live games are expected

### Validation Checklist

After enabling snapshot mode:
- ✅ App behaves normally when env var is unset
- ✅ Snapshot mode freezes time correctly
- ✅ No live games appear in snapshot mode
- ✅ Completed games render fully
- ✅ Future games appear correctly
- ✅ Reveal controls, timelines, and recaps still work
- ✅ No production code paths are altered

---

## Example Usage

### Test NBA Opening Night 2024

```bash
# Set environment variable
export IOS_BETA_ASSUME_NOW=2024-10-23T04:00:00Z

# Launch app
open ScrollDown.app

# Verify:
# - Home feed shows games from Oct 22-24, 2024
# - No live games appear
# - Orange "Testing mode" badge visible
# - Timelines and recaps work normally
```

### Test Historical March Madness

```bash
# Set environment variable
export IOS_BETA_ASSUME_NOW=2024-04-09T04:00:00Z

# Launch app
open ScrollDown.app

# Verify:
# - Championship game appears in "Today" section
# - Previous rounds in "Earlier" section
# - No future games beyond Apr 9
```

---

## Troubleshooting

### Snapshot mode not activating

**Check:**
1. Environment variable is set correctly
2. Date format is ISO8601 with timezone
3. App was launched after setting the variable
4. You're in a debug build

**Solution:**
```bash
# Verify environment variable
echo $IOS_BETA_ASSUME_NOW

# Re-export with correct format
export IOS_BETA_ASSUME_NOW=2024-02-15T04:00:00Z

# Relaunch app
```

### No games appearing

**Check:**
1. Backend has data for that date range
2. Snapshot date is reasonable (not too far in past/future)
3. League filter is not excluding all games

**Solution:**
- Try a different snapshot date with known data
- Use a quick preset from Admin Settings
- Check backend logs for data availability

### Live games still appearing

**Check:**
1. Snapshot mode is actually active (check for orange badge)
2. Backend is returning correct game status
3. Filtering logic is applied in HomeView

**Solution:**
- Clear and re-apply time override
- Check logs for "excluded X live games" message
- Verify `filterGamesForSnapshotMode()` is called

---

## Technical Details

### Architecture

```
TimeService (singleton)
    ├── overrideDate: Date?
    ├── now: Date (computed)
    └── isSnapshotModeActive: Bool

AppDate (enum)
    ├── now() -> Date (uses TimeService)
    └── Helper properties (startOfToday, etc.)

AppConfig
    ├── isSnapshotModeActive: Bool
    └── filterGamesForSnapshotMode([GameSummary]) -> [GameSummary]

HomeView
    └── loadSection() -> applies snapshot filtering
```

### Key Files

- `ScrollDown/Sources/Services/TimeService.swift` — Time override logic
- `ScrollDown/Sources/AppConfig.swift` — Integration and filtering
- `ScrollDown/Sources/Screens/Home/HomeView.swift` — UI and filtering application
- `ScrollDown/Sources/Screens/AdminSettingsView.swift` — Admin control surface

---

## Production Safety

### Debug-Only Enforcement

Snapshot mode is **strictly limited to debug builds**:

```swift
#if DEBUG
// Time override allowed
#else
// Time override ignored, logged as warning
#endif
```

### No Production Impact

- Environment variable is only read in debug builds
- Admin UI is only accessible in debug builds
- Visual indicator only appears in debug builds
- Logs are only written in debug builds

### Release Build Behavior

In production builds:
- `TimeService.shared.now` always returns `Date()`
- `setTimeOverride()` calls are ignored
- Admin Settings screen is inaccessible
- No snapshot filtering occurs

---

## Troubleshooting Support

For issues with snapshot mode:

1. Check Console.app logs (filter: `com.scrolldown.app`, category: `time`)
2. Verify environment variable format is ISO8601
3. Confirm backend has data for the snapshot date
4. Ensure you're in a debug build

**Remember**: This is a beta testing tool. If something breaks in snapshot mode, it's not a production issue.
