# Scroll Down — iOS App

Native iOS client for **Scroll Down Sports** — catch up on games without immediate score reveals.

## The Concept

Sports fans don't always watch games live. Most apps immediately show final scores — robbing you of the experience of following how the game unfolded.

**Scroll Down** takes a different approach:
- **Pace yourself.** Move through key moments in order
- **Context first.** See matchups and game flow before outcomes
- **Reveal on your terms.** You decide when to uncover scores

## Features

| Feature | Status |
|---------|--------|
| Home feed (Earlier/Yesterday/Today/Tomorrow) | Live |
| Game search by team name | Live |
| Game detail with collapsible sections | Live |
| Flow-based timeline with narrative blocks | Live |
| Tiered play-by-play with team badges | Live |
| FairBet odds comparison with EV analysis | Live |
| Game detail cross-book odds table | Live |
| NHL skater/goalie stats | Live |
| Team page navigation | Live |
| Theme selection (system/light/dark) | Live |
| Live game viewing with auto-polling PBP | Live |
| Reading position tracking with resume | Live |
| Score reveal preference (spoiler-free / always show) | Live |
| iPad adaptive layout | Live |
| Snapshot mode (beta time override) | Live |

## Quick Start

**Requirements:** Xcode 16+, iOS 17+

```bash
open ScrollDown.xcodeproj
# Build and run in Xcode, or:
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Environments

| Mode | Description |
|------|-------------|
| `.live` | Production API at `sports-data-admin.dock108.ai` (default) |
| `.localhost` | Local server at `localhost:8000` |
| `.mock` | Offline with generated data via `MockGameService` |

Set via `AppConfig.shared.environment` or Admin Settings (debug builds).

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/architecture.md) | MVVM structure, data flow, design patterns |
| [Development](docs/development.md) | Local dev, testing, debugging |
| [Snapshot Mode](docs/beta-time-override.md) | Time override for historical testing |
| [Changelog](docs/CHANGELOG.md) | Feature history |

For AI agent context, see [AGENTS.md](AGENTS.md).
