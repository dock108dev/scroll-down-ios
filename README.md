# Scroll Down Sports — iOS

iOS client for **Scroll Down Sports** — catch up on games without immediate score reveals.

## The Concept

Sports fans don't always watch games live. Most apps immediately show final scores — robbing you of the experience of following how the game unfolded.

**Scroll Down** takes a different approach:
- **Pace yourself.** Move through key moments in order
- **Context first.** See matchups and game flow before outcomes
- **Reveal on your terms.** You decide when to uncover scores

## Platform

| Platform | Directory | Tech Stack | Status |
|----------|-----------|------------|--------|
| iOS | `ScrollDown/` | Swift 5.9+, SwiftUI, MVVM | Live |

The iOS client consumes the same backend API (`sports-data-admin.dock108.ai`). No backend code lives in this repository — it is purely a client layer.

## Quick Start

**Requirements:** Xcode 16+, iOS 17+

```bash
open ScrollDown.xcodeproj
# Build and run in Xcode, or:
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Features

| Feature | iOS |
|---------|-----|
| Home feed (Earlier/Yesterday/Today/Tomorrow) | Yes |
| Game search by team name | Yes |
| Game detail with collapsible sections | Yes |
| Flow-based narrative timeline | Yes |
| Tiered play-by-play | Yes |
| Cross-book odds table | Yes |
| FairBet odds comparison with EV | Yes |
| Score reveal preference (spoiler-free) | Yes |
| Reading position tracking with resume | Yes |
| Theme selection (system/light/dark) | Yes |
| Live game auto-polling | Yes |
| NHL skater/goalie stats | Yes |
| iPad adaptive layout | Yes |
| Snapshot mode (beta time override) | Yes |

## Architecture

The app is a **thin display layer**. The backend computes all derived data — period labels, play tiers, odds outcomes, team colors, merged timelines. The client reads pre-computed values and renders them.

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/architecture.md) | System architecture and data flow |
| [Development](docs/development.md) | Local dev, testing, debugging |
| [CI/CD](docs/ci-cd.md) | GitHub Actions, Docker, deployment |
| [Snapshot Mode](docs/beta-time-override.md) | iOS time override for historical testing |
| [Changelog](docs/CHANGELOG.md) | iOS feature history |

Client-side logic catalog:
- [iOS APP_LOGIC.md](ScrollDown/APP_LOGIC.md) — What intentionally stays on-device
