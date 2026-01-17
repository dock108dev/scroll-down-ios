# Development

Guide for local development, testing, and debugging.

## Data Modes

The app supports three environments, controlled via `AppConfig.shared.environment`:

| Mode | Description | Use Case |
|------|-------------|----------|
| `.live` | Production backend API | Default, real data |
| `.localhost` | Local dev server (port 8000) | Backend development |
| `.mock` | Generated local data | Offline UI development |

**Default:** Live mode. To use localhost by default, set `FeatureFlags.defaultToLocalhost = true` in `AppConfig.swift`.

### Mock Data

Static mock JSON lives in `ScrollDown/Sources/Mock/games/`:
- `game-list.json` — Sample game feed
- `game-001.json`, `game-002.json` — Full game detail payloads
- `pbp-001.json` — Play-by-play event data
- `moments-001.json` — Moment data samples

`MockDataGenerator` dynamically creates games with realistic data. The mock service uses a fixed dev clock (November 12, 2024) so temporal grouping behaves consistently.

### Switching Modes

```swift
// In code
AppConfig.shared.environment = .mock

// Or via Admin Settings (debug builds only)
// Long-press "Updated X ago" in Home feed
```

## Timeline Architecture

The timeline displays game progression in two modes:

### 1. Moments-Based (Primary)
When `Moment` data is available from the backend:
- Timeline is grouped by quarter
- Each moment shows a narrative summary
- Expanding a moment reveals its play-by-play events
- Highlights are marked with `isNotable`

### 2. Unified Timeline (Fallback)
When moments aren't available:
- `UnifiedTimelineEvent` entries render directly
- Events grouped by period
- Interleaves PBP plays with tweets chronologically

## Building & Testing

```bash
# Build for simulator
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build for iOS 26
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,OS=26.0,name=iPhone 16 Pro' build
```

## Beta Features

### Snapshot Mode (Time Override)
Freeze the app to a specific date to test historical data. **Debug builds only.**

```bash
# Enable via environment variable
export IOS_BETA_ASSUME_NOW=2024-10-23T04:00:00Z
```

Or use Admin Settings (long-press "Updated X ago" in Home feed).

See [BETA_TIME_OVERRIDE.md](BETA_TIME_OVERRIDE.md) for full documentation.

## QA Checklist

### General UI
- [ ] Dark and light mode support
- [ ] Long team names truncate gracefully
- [ ] VoiceOver labels present
- [ ] iPad adaptive layout works

### Data & Logic
- [ ] Empty states show contextual messages
- [ ] Loading skeletons appear before content
- [ ] Outcomes stay hidden until revealed
- [ ] Reveal states persist across sessions

### Navigation
- [ ] Deep linking to specific games works
- [ ] Scrolling stable when expanding sections
- [ ] Back navigation preserves state

## Debugging

### Check current environment
```swift
print(AppConfig.shared.environment)  // .live, .localhost, or .mock
```

### Inspect dev clock
```swift
print(AppDate.now())  // Nov 12, 2024 in mock mode
```

### Console logs
Filter by subsystem `com.scrolldown.app` in Console.app:
- `time` — Snapshot mode events
- `timeline` — Timeline loading
- `networking` — API calls
