# Development

Guide for local development, testing, and debugging.

## Environments

The app supports two runtime environments via `AppConfig.shared.environment`:

| Mode | Description | Use Case |
|------|-------------|----------|
| `.live` | Production backend API | Default, real data |
| `.localhost` | Local dev server (port 8000) | Backend development |

**Default:** Live mode.

A `.mock` environment also exists in code (uses `MockGameService` with generated data) but is not the standard development path.

### Switching Modes

```swift
// In code
AppConfig.shared.environment = .localhost

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

**Note:** Mock service does not generate flow data, team colors, or unified timelines. These come from the real API only.

## Building & Testing

```bash
# Build for simulator
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

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

See [beta-time-override.md](beta-time-override.md) for full documentation.

## QA Checklist

### UI
- [ ] Dark and light mode
- [ ] Long team names truncate gracefully
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

## Debugging

### Console logs
Filter by subsystem `com.scrolldown.app` in Console.app:

| Category | Content |
|----------|---------|
| `time` | Snapshot mode events |
| `routing` | Navigation and game routing |
| `networking` | API calls and responses |
| `teamColors` | Team color cache loading |
| `timeline` | Timeline and flow loading |

### Common Issues

**Flow not loading:**
- Check `viewModel.hasFlowData` returns true
- Verify API responses in network logs
- Confirm game has flow data generated (not all games have flow)

**Team colors showing default indigo:**
- Check `TeamColorCache` loaded successfully (filter logs by `teamColors`)
- Verify `/api/admin/sports/teams` returns color hex values for the team
- Cache expires after 7 days — force refresh by clearing UserDefaults

**Unified timeline empty:**
- Check `unifiedTimelineState` — should be `.loaded`
- Verify `/api/admin/sports/games/{id}/timeline` returns events
- Not all games have unified timelines generated
