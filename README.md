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
| Home feed with Earlier/Yesterday/Today/Upcoming sections | ✅ Live |
| Game detail view with collapsible sections | ✅ Live |
| Moments-based timeline grouped by quarter | ✅ Live |
| Unified timeline with PBP and social posts | ✅ Live |
| Progressive disclosure UI patterns | ✅ Live |
| Dark mode support | ✅ Live |
| Backend API integration | ✅ Live |
| iPad adaptive layout | ✅ Live |
| Beta time override (snapshot mode) | ✅ Live |
| Push notifications | 📋 Planned |
| User preferences & favorites | 📋 Planned |

## Data Sources

The app supports three environments, toggled via `AppConfig.environment`:

| Mode | Description |
|------|-------------|
| `.live` | Connects to production API at `sports-data-admin.dock108.ai` |
| `.localhost` | Connects to local dev server at `localhost:8000` |
| `.mock` | Uses generated local data for offline development |

**Default:** Live mode. Set `FeatureFlags.defaultToLocalhost = true` to auto-use localhost during development.

Models align with the [scroll-down-api-spec](https://github.com/scroll-down-sports/scroll-down-api-spec).

## Local Development

**Requirements:** Xcode 16+, iOS 17+ (iOS 26 supported)

```bash
# Open in Xcode
open ScrollDown.xcodeproj

# Build from command line
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/architecture.md) | MVVM structure, data flow, and design principles |
| [Development](docs/development.md) | Environment modes, testing, QA checklist |
| [Beta Time Override](docs/BETA_TIME_OVERRIDE.md) | Snapshot mode for testing historical data |
| [Changelog](docs/CHANGELOG.md) | Feature history and updates |
| [AGENTS.md](AGENTS.md) | Context for AI coding assistants |
