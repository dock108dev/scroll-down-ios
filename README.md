# Scroll Down — iOS App

The native iOS client for **Scroll Down Sports** — a thoughtful way to catch up on games after they've been played.

## The Concept

Sports fans don't always watch games live. When you come back to a game hours or days later, most apps immediately surface the final score — robbing you of the experience of following how the game actually unfolded.

**Scroll Down** takes a different approach:

- **Pace yourself.** Move through key moments in order, from tip-off to final whistle.
- **Context first.** See matchups, storylines, and game flow before outcomes.
- **Reveal on your terms.** You decide when to uncover scores and results.

This isn't about hiding information — it's about letting you experience the game's narrative the way it happened.

## What's Working Now

| Feature | Status |
|---------|--------|
| Home feed with Earlier/Today/Upcoming sections | ✅ Live |
| Game detail view with collapsible sections | ✅ Live |
| Compact timeline with chapter-style moments | ✅ Live |
| Expanded play-by-play slices per moment | ✅ Live |
| Progressive disclosure UI patterns | ✅ Live |
| Dark mode support | ✅ Live |
| Backend API integration | ✅ Live |
| Push notifications | 📋 Planned |
| User preferences & favorites | 📋 Planned |

## Data Sources

The app supports two environments, toggled via `AppConfig.environment`:

- **Mock Mode**: Uses realistic local JSON data for offline development and UI testing.
- **Live Mode**: Connects to the backend API for real-time data.

Models are strictly aligned with the [scroll-down-api-spec](https://github.com/scroll-down-sports/scroll-down-api-spec) contract. Local development defaults to **Live Mode** pointing at `https://sports-data-admin.dock108.ai`.

## Relationship to Web UI

This iOS app complements the [scroll-down-sports-ui](https://github.com/scroll-down-sports/scroll-down-sports-ui) web experience:

| Aspect | Web UI | iOS App |
|--------|--------|---------|
| Platform | Browser-based | Native iOS (SwiftUI) |
| Navigation | Traditional web patterns | Mobile-native gestures |
| Offline | Limited | Planned offline support |
| Notifications | None | Push notifications (planned) |

Both share the same core philosophy and will consume the same backend APIs, but each is optimized for its platform's strengths.

## Local Development

**Requirements:** Xcode 15+, iOS 16+

```bash
# Open in Xcode
open ScrollDown.xcodeproj

# Or build from command line
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild test -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Documentation

Deeper documentation lives in [`/docs`](docs/README.md):

- [Architecture](docs/architecture.md) — MVVM structure and data flow
- [Development](docs/development.md) — Mock mode, testing, QA checklist
- [Changelog](docs/CHANGELOG.md) — Feature history and updates
- [Beta Time Override](docs/BETA_TIME_OVERRIDE.md) — Time-travel mode for testing historical data

Agent notes for AI coding assistants are in [`AGENTS.md`](AGENTS.md).
