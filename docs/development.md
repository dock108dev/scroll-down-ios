# Development

Guide for local development, testing, and debugging.

## Environments

The app supports three runtime environments via `AppConfig.shared.environment`:

| Mode | Description | Use Case |
|------|-------------|----------|
| `.live` | Production backend API | Default, real data |
| `.localhost` | Local dev server (port 8000) | Backend development |
| `.mock` | Generated local data via `MockGameService` | Offline development |

**Default:** Live mode. Mock mode does not provide flow data, team colors, or unified timelines.

### Switching Modes

```swift
// In code
AppConfig.shared.environment = .localhost
```

**Note:** The Admin Settings UI (`AdminSettingsView`) exists but the long-press trigger on the freshness text is not currently rendered in the home layout. Access admin settings by setting `showingAdminSettings = true` in code.

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

Or use Admin Settings (see note above about current access).

See [beta-time-override.md](beta-time-override.md) for full documentation.

## QA Checklist

### UI
- [ ] System, light, and dark themes
- [ ] Long team names and 4-char abbreviations display correctly
- [ ] iPad adaptive layout (4-column grid, constrained content width)
- [ ] PBP tiers visually distinct (T1 badges, T2 accent lines, T3 dots)

### Data
- [ ] Empty states show contextual messages
- [ ] Loading skeletons appear
- [ ] Team stats show all API-returned fields (not just a fixed subset)
- [ ] Section collapse states persist within session
- [ ] Search filters games by team name
- [ ] Reading position saves on scroll and restores on re-open
- [ ] Score reveal respects user preference (onMarkRead, resumed, always)
- [ ] `markRead` is silently ignored for non-final games

### Live Games
- [ ] Live game detail shows PBP as primary content (not Game Flow)
- [ ] Auto-polling starts for live games (~45s interval)
- [ ] Polling stops on dismiss or game transitioning to final
- [ ] Game transitioning to final switches from PBP to Game Flow
- [ ] Header shows pulsing LIVE badge with live score
- [ ] Resume prompt appears when returning to a game with saved position

### Navigation
- [ ] Scrolling stable when expanding sections
- [ ] Back navigation preserves state
- [ ] Games/FairBet/Settings tabs work
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

**Timeline artifact empty:**
- Check `timelineArtifactState` — should be `.loaded`
- Verify `/api/admin/sports/games/{id}/timeline` returns a `TimelineArtifactResponse` with `timelineJson`
- Not all games have timeline artifacts generated
- Flow-based timeline (`buildUnifiedTimelineFromFlow`) is the primary PBP source for completed games
