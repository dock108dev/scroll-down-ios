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
| `GameStoryResponse` | Story with moments and plays |
| `StoryMoment` | Narrative segment with play IDs, scores, period/clock |
| `StoryPlay` | Individual play within a story |
| `MomentDisplayModel` | UI-ready moment with derived beat type |
| `UnifiedTimelineEvent` | Single timeline entry (PBP or tweet) |
| `PlayEntry` | Individual play-by-play event |
| `BeatType` | Narrative moment classification (run, crunch time, etc.) |

## Story Architecture

The app renders completed games using a **moments-based** story system:

1. **Moments** — Primary narrative units grouping related plays
   - Each moment has: narrative text, play IDs, score range, period/clock
   - `explicitlyNarratedPlayIds` marks key scoring plays
   - Beat types derived from score deltas via `StoryAdapter`

2. **StoryAdapter** — Converts `GameStoryResponse` to `[MomentDisplayModel]`
   - Derives beat types from scoring patterns and game position
   - Maps plays to moments for UI display

3. **Fallback** — When no story data available:
   - `UnifiedTimelineEvent` entries grouped by quarter/period
   - Chronological play-by-play with interleaved tweets

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

| Mode | Base URL | Use Case |
|------|----------|----------|
| `.live` | `sports-data-admin.dock108.ai` | Production |
| `.localhost` | `localhost:8000` | Local backend |
| `.mock` | N/A | Offline development |

Toggle via `AppConfig.shared.environment`.

## API Endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /api/admin/sports/games` | List games (with range, league filters) |
| `GET /api/admin/sports/games/{id}` | Game detail |
| `GET /api/admin/sports/games/{id}/pbp` | Play-by-play |
| `GET /api/admin/sports/games/{id}/social` | Social posts |
| `GET /api/admin/sports/games/{id}/story` | Story with moments |
| `GET /api/games/{id}/timeline` | Timeline artifact |

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
