# Development

Guide for local development, testing, and debugging.

## Environments

The app supports three environments via `AppConfig.shared.environment`:

| Mode | Description | Use Case |
|------|-------------|----------|
| `.live` | Production backend API | Default, real data |
| `.localhost` | Local dev server (port 8000) | Backend development |
| `.mock` | Generated local data | Offline UI development |

**Default:** Live mode. To use localhost by default, set `FeatureFlags.defaultToLocalhost = true` in `AppConfig.swift`.

### Switching Modes

```swift
// In code
AppConfig.shared.environment = .mock

// Or via Admin Settings (debug builds only)
// Long-press "Updated X ago" in Home feed
```

## Mock Data

Static mock JSON lives in `ScrollDown/Sources/Mock/games/`:

| File | Content |
|------|---------|
| `game-list.json` | Sample game feed |
| `game-001.json` | Full game detail |
| `game-002.json` | Full game detail (variant) |
| `pbp-001.json` | Play-by-play events |
| `social-posts.json` | Social post samples |

`MockDataGenerator` dynamically creates games with realistic data. The mock service uses a fixed dev clock (November 12, 2024) so temporal grouping behaves consistently.

## Timeline Architecture

### 1. Story-Based (Primary)
When story data is available from `/games/{id}/story`:
- Timeline grouped by period
- Each section has a narrative header and beat type
- Expanding a section reveals play-by-play
- Social posts matched to sections

### 2. PBP-Based (Fallback)
When story data isn't available:
- `UnifiedTimelineEvent` entries grouped by quarter/period
- Chronological play-by-play
- Collapsible period sections

## Building & Testing

```bash
# Build for simulator
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build for specific iOS version
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,OS=18.0,name=iPhone 16 Pro' build

# Clean build
xcodebuild -scheme ScrollDown clean build
```

## Snapshot Mode (Time Override)

Freeze the app to a specific date to test historical data. **Debug builds only.**

```bash
export IOS_BETA_ASSUME_NOW=2024-10-23T04:00:00Z
```

Or use Admin Settings (long-press "Updated X ago" in Home feed).

See [BETA_TIME_OVERRIDE.md](BETA_TIME_OVERRIDE.md) for full documentation.

## QA Checklist

### UI
- [ ] Dark and light mode
- [ ] Long team names truncate gracefully
- [ ] VoiceOver labels present
- [ ] iPad adaptive layout

### Data
- [ ] Empty states show contextual messages
- [ ] Loading skeletons appear
- [ ] Outcomes stay hidden until revealed
- [ ] Reveal states persist

### Navigation
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

| Category | Content |
|----------|---------|
| `time` | Snapshot mode events |
| `timeline` | Timeline loading |
| `networking` | API calls |
