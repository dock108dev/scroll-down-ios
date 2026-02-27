# Scroll Down Sports

iOS client for **Scroll Down Sports** — catch up on games without immediate score reveals.

## The Concept

Sports fans don't always watch games live. Most apps immediately show final scores — robbing you of the experience of following how the game unfolded.

**Scroll Down** takes a different approach:
- **Pace yourself.** Move through key moments in order
- **Context first.** See matchups and game flow before outcomes
- **Reveal on your terms.** You decide when to uncover scores

## Quick Start

**Requirements:** Xcode 16+, iOS 17+

```bash
open ScrollDown.xcodeproj
# Build and run in Xcode, or:
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Features

- Home feed (Earlier/Yesterday/Today/Tomorrow)
- Game search by team name
- Game detail with collapsible sections
- Flow-based narrative timeline
- Tiered play-by-play
- Cross-book odds table
- FairBet odds comparison with EV
- Score reveal preference (spoiler-free)
- Reading position tracking with resume
- Theme selection (system/light/dark)
- Live game auto-polling
- NHL skater/goalie stats
- iPad adaptive layout
- Snapshot mode (beta time override)

## Architecture

The app is a **thin display layer**. The backend computes all derived data — period labels, play tiers, odds outcomes, team colors, merged timelines. The client reads pre-computed values and renders them.

The app consumes the backend API (`sports-data-admin.dock108.ai`). No backend code lives in this repository.

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/architecture.md) | System architecture and data flow |
| [Development](docs/development.md) | Local dev, testing, debugging |
| [CI/CD](docs/ci-cd.md) | GitHub Actions pipeline |
| [Snapshot Mode](docs/beta-time-override.md) | iOS time override for historical testing |
| [Changelog](docs/CHANGELOG.md) | Feature history |

Client-side logic catalog:
- [APP_LOGIC.md](ScrollDown/APP_LOGIC.md) — What intentionally stays on-device
