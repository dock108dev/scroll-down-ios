# Scroll Down Sports

Multi-platform client for **Scroll Down Sports** — catch up on games without immediate score reveals.

## The Concept

Sports fans don't always watch games live. Most apps immediately show final scores — robbing you of the experience of following how the game unfolded.

**Scroll Down** takes a different approach:
- **Pace yourself.** Move through key moments in order
- **Context first.** See matchups and game flow before outcomes
- **Reveal on your terms.** You decide when to uncover scores

## Platforms

| Platform | Directory | Tech Stack | Status |
|----------|-----------|------------|--------|
| iOS | `ScrollDown/` | Swift 5.9+, SwiftUI, MVVM | Live |
| Web | `web/` | Next.js 16, React 19, Zustand, Tailwind | Live |

Both clients consume the same backend API (`sports-data-admin.dock108.ai`). No backend code lives in this repository — it is purely a client layer.

`webapp/` contains a legacy vanilla HTML/JS/CSS prototype, superseded by the Next.js web app.

## Quick Start

### iOS

**Requirements:** Xcode 16+, iOS 17+

```bash
open ScrollDown.xcodeproj
# Build and run in Xcode, or:
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

### Web

**Requirements:** Node 22+

```bash
cd web
cp .env.local.example .env.local   # Add your API key
npm install
npm run dev                         # http://localhost:3000
```

## Features

| Feature | iOS | Web |
|---------|-----|-----|
| Home feed (Earlier/Yesterday/Today/Tomorrow) | Yes | Yes |
| Game search by team name | Yes | Yes |
| Game detail with collapsible sections | Yes | Yes |
| Flow-based narrative timeline | Yes | Yes |
| Tiered play-by-play | Yes | Yes |
| Cross-book odds table | Yes | Yes |
| FairBet odds comparison with EV | Yes | Yes |
| Score reveal preference (spoiler-free) | Yes | Yes |
| Reading position tracking with resume | Yes | Yes |
| Theme selection (system/light/dark) | Yes | Yes |
| Live game auto-polling | Yes | Yes |
| NHL skater/goalie stats | Yes | Yes |
| iPad adaptive layout | Yes | — |
| Snapshot mode (beta time override) | Yes | — |

## Architecture

Both apps follow the same principle: the app is a **thin display layer**. The backend computes all derived data — period labels, play tiers, odds outcomes, team colors, merged timelines. Clients read pre-computed values and render them.

## Documentation

| Document | Description |
|----------|-------------|
| [AGENTS.md](AGENTS.md) | AI agent context (both platforms) |
| [Architecture](docs/architecture.md) | System architecture and data flow |
| [Development](docs/development.md) | Local dev, testing, debugging |
| [CI/CD](docs/ci-cd.md) | GitHub Actions, Docker, deployment |
| [Snapshot Mode](docs/beta-time-override.md) | iOS time override for historical testing |
| [Changelog](docs/CHANGELOG.md) | iOS feature history |

Client-side logic catalogs:
- [iOS APP_LOGIC.md](ScrollDown/APP_LOGIC.md) — What intentionally stays on-device
- [Web APP_LOGIC.md](web/APP_LOGIC.md) — What intentionally stays in-browser
