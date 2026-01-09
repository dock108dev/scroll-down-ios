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

## Beta Features

### 1. Time Override (Snapshot Mode)
Freeze the app to a specific date to test historical data. **Debug builds only.**

**Enable via Environment Variable:**
```bash
export IOS_BETA_ASSUME_NOW=2024-10-23T04:00:00Z
```

**Enable via Admin UI:**
1. Long-press (2s) on "Updated X ago" in the Home feed.
2. Select a date or preset.
3. Tap "Done" to reload with the override.

**Visual Indicator:** An orange badge appears at the top when active.

### 2. Admin Settings
Accessible via long-press on freshness text. Controls:
- Snapshot date selection
- Data mode info
- Environment toggle visibility

## QA & Validation Checklist

Verify these behaviors before submitting changes:

### General UI
- [ ] **Appearance** — Dark and light mode support
- [ ] **Text Overflow** — Long team names/titles truncate gracefully
- [ ] **Accessibility** — VoiceOver labels and Dynamic Type scaling

### Data & Logic
- [ ] **Empty States** — Contextual icons and messages show when data is missing
- [ ] **Loading** — Skeleton placeholders show before content flashes in
- [ ] **Reveal Logic** — Outcomes stay hidden until explicitly revealed
- [ ] **Persistence** — Reveal states and overrides persist correctly

### Navigation & Routing
- [ ] **Deep Linking** — Routing to specific games by ID
- [ ] **Stability** — Scrolling doesn't jump when expanding/collapsing sections
- [ ] **Logs** — Check `GameRoutingLogger` in Console for navigation tracing

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
