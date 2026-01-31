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
| Home feed (Earlier/Yesterday/Today/Upcoming) | Live |
| Game detail with collapsible sections | Live |
| Story-based timeline with narrative moments | Live |
| Play-by-play grouped by quarter/period | Live |
| NHL skater/goalie stats | Live |
| Team page navigation | Live |
| Dark mode | Live |
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
| `.live` | Production API at `sports-data-admin.dock108.ai` |
| `.localhost` | Local server at `localhost:8000` |
| `.mock` | Generated local data for offline development |

Default is live mode. Set via `AppConfig.shared.environment`.

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/architecture.md) | MVVM structure and data flow |
| [Development](docs/development.md) | Local dev, testing, debugging |
| [Snapshot Mode](docs/BETA_TIME_OVERRIDE.md) | Time override for historical testing |
| [Changelog](docs/CHANGELOG.md) | Feature history |

For AI agent context, see [AGENTS.md](docs/AGENTS.md).
