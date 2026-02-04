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

**Note:** Mock service does not generate stories. Story data comes from the real API only.

## Story Architecture

Stories are rendered using a **blocks-based** system from the `/games/{id}/story` endpoint:

1. **Blocks** — Primary narrative units (4-7 per game)
   - Each block has: narrative text, mini box score, period range, scores
   - `blockStars` array highlights top performers
   - Server provides semantic `role` (not displayed to users)

2. **Views:**
   - `StoryContainerView` — Block list with visual spine
   - `StoryBlockCardView` — Single block with mini box at bottom
   - `MiniBoxScoreView` — Compact player stats per block

3. **Fallback:** When story data isn't available, PBP events render chronologically grouped by period.

## Building & Testing

```bash
# Build for simulator
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Build for specific iOS version
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,OS=18.0,name=iPhone 16 Pro' build

# Run tests
xcodebuild test -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

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
- [ ] iPad adaptive layout (4-column grid, constrained width)

### Data
- [ ] Empty states show contextual messages
- [ ] Loading skeletons appear
- [ ] Outcomes stay hidden until revealed
- [ ] Section collapse states persist within session

### Navigation
- [ ] Scrolling stable when expanding sections
- [ ] Back navigation preserves state
- [ ] Tab bar scrolls to section reliably
- [ ] Team headers are tappable

### Interactions
- [ ] Tap feedback on all interactive elements
- [ ] Chevrons rotate consistently on expand
- [ ] Animations feel smooth (spring timing)

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
| `routing` | Navigation and game routing |
| `networking` | API calls and responses |

### Common Issues

**Sections not scrolling to position:**
- Verify `scrollToSection` state is being set
- Check anchor offset in `UnitPoint(x: 0.5, y: -0.08)`

**Story not loading:**
- Check `viewModel.hasStoryData` returns true
- Verify API responses in network logs
- Confirm game has story generated (not all games have stories)

**Mock data not appearing:**
- Confirm `environment = .mock`
- Check `AppDate.now()` returns expected date
