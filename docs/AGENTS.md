# AGENTS.md — Scroll Down iOS

> Context for AI agents (Claude, Cursor, Copilot) working on this codebase.

## Quick Context

**What is this?** Native iOS client for Scroll Down Sports — catch up on games without immediate score reveals.

**Tech Stack:** Swift 5.9+, SwiftUI, MVVM, iOS 17+

**No external dependencies.** Uses only Foundation and SwiftUI.

## Directory Layout

```
ScrollDown/Sources/
├── Models/           # Codable data models (API-aligned)
├── ViewModels/       # State management, business logic
├── Screens/
│   ├── Home/         # Game list feed
│   ├── Game/         # Game detail view (split into extensions)
│   └── Team/         # Team page
├── Components/       # Reusable UI (CollapsibleCards, LoadingSkeletonView)
├── Networking/       # GameService protocol + implementations, StoryAdapter
├── Services/         # TimeService (snapshot mode)
├── Logging/          # Structured logging (GameRoutingLogger)
└── Mock/games/       # Static mock JSON for development
```

## Core Principles

1. **Progressive disclosure** — Context before scores; users arrive after games end
2. **User-controlled pacing** — They decide when to reveal results
3. **Mobile-first** — Touch navigation, vertical scrolling, collapsible sections

## Key Data Models

| Model | Purpose |
|-------|---------|
| `GameSummary` | List view representation (home feed) |
| `GameDetailResponse` | Full game detail with plays, stats, odds |
| `GameStoryResponse` | Story with blocks and plays |
| `StoryBlock` | Narrative segment with role, mini box, period range |
| `StoryPlay` | Individual play within a story |
| `BlockDisplayModel` | UI-ready block for rendering |
| `BlockMiniBox` | Per-block player stats with `blockStars` |
| `UnifiedTimelineEvent` | Single timeline entry (PBP or tweet) |
| `PlayEntry` | Individual play-by-play event |

## Story Architecture

The app renders completed games using a **blocks-based** story system:

1. **Blocks** — Primary narrative units (4-7 per game)
   - Each block has: narrative text, mini box score, period range, scores
   - `blockStars` array highlights top performers in that segment
   - Server provides `role` (SETUP, MOMENTUM_SHIFT, etc.) — not displayed
   - `keyPlayIds` marks explicitly narrated plays
   - `embeddedTweet` structure ready (no live data yet)

2. **StoryAdapter** — Converts `GameStoryResponse` to `[BlockDisplayModel]`
   - Simple mapping, server provides all semantic info

3. **Views:**
   - `StoryContainerView` — Block list with visual spine
   - `StoryBlockCardView` — Single block with mini box at bottom
   - `MiniBoxScoreView` — Compact player stats per block

## View Architecture

**GameDetailView** is split into focused extensions:

| File | Responsibility |
|------|---------------|
| `GameDetailView.swift` | Main container, navigation, state |
| `GameDetailView+Overview.swift` | Pregame section |
| `GameDetailView+Timeline.swift` | Story/PBP timeline |
| `GameDetailView+Stats.swift` | Player and team stats |
| `GameDetailView+NHLStats.swift` | NHL-specific skater/goalie tables |
| `GameDetailView+WrapUp.swift` | Post-game wrap-up |
| `GameDetailView+Helpers.swift` | Utility functions |
| `GameDetailView+Layout.swift` | Layout constants, preference keys |

## Environments

**Default: `.live`** — The app always uses the live production API.

| Mode | Base URL | Use Case |
|------|----------|----------|
| `.live` | `sports-data-admin.dock108.ai` | Production (default) |
| `.localhost` | `localhost:8000` | Local backend development |

**Testing:** All testing should use the live API with non-proprietary sports data. The production database is active and ready.

## API Endpoints

App uses authenticated endpoints (X-API-Key header):

| Endpoint | Purpose |
|----------|---------|
| `GET /api/admin/sports/games` | List games (with startDate, endDate, league filters) |
| `GET /api/admin/sports/games/{id}` | Game detail (full stats, plays) |
| `GET /api/admin/sports/pbp/game/{id}` | Play-by-play |
| `GET /api/social/posts/game/{id}` | Social posts |
| `GET /api/admin/sports/games/{id}/story` | Story with blocks |

## Testing

```bash
# Build
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run tests
xcodebuild test -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Do NOT

- Auto-commit changes
- Run commands requiring interactive input
- Run long commands (>5s) without periodic output
- Break progressive disclosure defaults
- Add dependencies without justification
- Use `print()` in production (use `Logger`)
- Call `Date()` directly for time logic (use `AppDate.now()`)
