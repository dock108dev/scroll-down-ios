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
xcodebuild -project ScrollDown.xcodeproj -scheme ScrollDown -destination 'generic/platform=iOS Simulator' -configuration Debug build
```

## Features

### Core Experience
- Home feed (Earlier/Yesterday/Today/Tomorrow)
- Game search by team name
- Game detail with collapsible sections and pinned headers
- Flow-based narrative timeline
- Tiered play-by-play
- Score reveal preference (spoiler-free with hold-to-reveal)
- Reading position tracking with resume
- Theme selection (system/light/dark)
- Live game auto-polling
- iPad adaptive layout

### FairBet Odds Comparison
- Cross-book odds table with EV analysis
- Pre-game and live in-game odds (30s polling)
- Standalone parlay calculator (odds input, EV, payout)
- Parlay builder with correlation detection
- MLB, NBA, NHL, NCAAB league support

### MLB Monte Carlo Simulator
- 10,000-iteration game simulation
- Custom lineup builder (9-slot batting order + starter pitcher)
- Animated game playback on baseball diamond with silhouettes
- Win probability bars, expected scores, PA breakdown donut charts
- Pitcher radar/spider charts, most likely score cards

### Account & Auth
- Email/password login and signup
- JWT token storage (Keychain)
- Role-based access (guest/user/admin)
- Password reset, email change, account deletion

### Sport-Specific
- NHL skater/goalie stats
- MLB batter/pitcher stats and advanced Statcast metrics
- Snapshot mode (beta time override for testing)

## Architecture

The app is a **thin display layer**. The backend computes all derived data — period labels, play tiers, odds outcomes, team colors, merged timelines. The client reads pre-computed values and renders them.

The app consumes the backend API (`sports-data-admin.dock108.ai`). No backend code lives in this repository.

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/architecture.md) | System architecture, data flow, API endpoints |
| [Development](docs/development.md) | Local dev, testing, debugging |
| [CI/CD](docs/ci-cd.md) | GitHub Actions pipeline |
| [Snapshot Mode](docs/beta-time-override.md) | iOS time override for historical testing |
| [Changelog](docs/CHANGELOG.md) | Feature history |
