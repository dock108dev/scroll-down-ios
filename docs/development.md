# Development

Guide for local development, testing, and debugging.

## Data Modes

The app supports two environments, controlled via `AppConfig.shared.environment`:

| Mode | Description | Use Case |
|------|-------------|----------|
| `.mock` | Structured local JSON data | UI development, offline work |
| `.live` | Live backend API calls | Integration testing, production |

**Default:** The app runs in mock mode. No backend connection required.

### Mock Data

Mock data lives in `ScrollDown/Sources/Mock/games/` and includes:
- `game-list.json` — Sample game feed
- `game-001.json`, `game-002.json` — Full game detail payloads
- `pbp-001.json` — Play-by-play event data
- Dynamically generated data via `MockDataGenerator`

The mock service uses a fixed dev clock (November 12, 2024) so temporal grouping (Earlier/Today/Upcoming) behaves consistently.

### Switching Modes

```swift
// In code (for debugging)
AppConfig.shared.environment = .live
```

A runtime toggle UI is planned for debug builds.

## Compact Timeline UX

The compact timeline presents game moments as expandable chapters:

1. **Collapsed state** — Shows moment summary (e.g., "Duke extends lead")
2. **Expanded state** — Reveals play-by-play slice with event details
3. **Score separators** — Scores appear at natural breakpoints (halftime, period end), not inline with individual plays

This design lets users control their pacing through the game narrative.

## Running Tests

```bash
# Run all tests
xcodebuild test -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test file
xcodebuild test -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:ScrollDownTests/GameDetailViewModelTests
```

## QA Checklist

Before submitting changes, verify:

- [ ] **Appearance** — Works in both dark and light mode
- [ ] **Text overflow** — Long team names truncate gracefully
- [ ] **Edge cases** — Games without ratings, mid-major conferences
- [ ] **Data modes** — UI works with both mock and (when available) API data
- [ ] **Timeline pacing** — Expanding a moment doesn't jump the scroll position
- [ ] **Accessibility** — VoiceOver labels are meaningful

## Debugging Tips

### Check current data mode
```swift
print(AppConfig.shared.environment)
```

### Inspect dev clock
```swift
print(AppDate.now())  // Should be Nov 12, 2024 in mock mode
```

### Force a specific game
The mock service generates unique detail for each game ID. Pass different IDs to test various states.
