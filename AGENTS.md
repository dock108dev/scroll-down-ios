# AGENTS.md — Scroll Down iOS

> Context for AI agents (Claude, Cursor, Copilot) working on this codebase.

## Quick Context

**What is this?** Native iOS client for Scroll Down Sports — catch up on games without immediate score reveals.

**Tech Stack:** Swift 5.9+, SwiftUI, MVVM, iOS 17+

## Directory Layout

```
ScrollDown/Sources/
├── Models/           # Codable data models (API-aligned)
├── ViewModels/       # State management, business logic
├── Screens/
│   ├── Home/         # Game list feed
│   └── Game/         # Game detail view (split into extensions)
├── Components/       # Reusable UI
├── Networking/       # GameService protocol + implementations
├── Services/         # TimeService (snapshot mode)
├── Logging/          # Structured logging
└── Mock/games/       # Static mock JSON for development
```

## Core Principles

1. **Progressive disclosure** — Context before scores; users arrive after games end
2. **User-controlled pacing** — They decide when to reveal results
3. **Mobile-first** — Touch navigation, vertical scrolling

## Key Data Models

| Model | Purpose |
|-------|---------|
| `GameSummary` | List view representation |
| `GameDetailResponse` | Full game detail with plays, stats |
| `GameStoryResponse` | Story with moments and plays |
| `StoryMoment` | Narrative segment with play IDs, scores, narrative text |
| `StoryPlay` | Individual play within a story |
| `MomentDisplayModel` | UI-ready moment with derived beat type |
| `UnifiedTimelineEvent` | Single timeline entry (PBP or tweet) |
| `PlayEntry` | Individual play-by-play event |

## Story Architecture

The app renders completed games using a **moments-based** story system:

1. **Moments** — Primary narrative units grouping related plays
   - Each moment has: narrative text, play IDs, score range, period/clock
   - `explicitlyNarratedPlayIds` marks key scoring plays
   - Beat types (run, closing sequence, etc.) derived from score deltas

2. **StoryAdapter** — Converts `GameStoryResponse` to `[MomentDisplayModel]`
   - Derives beat types from scoring patterns
   - Maps plays to moments for UI display

3. **Fallback** — When no story data available:
   - `UnifiedTimelineEvent` entries grouped by quarter/period
   - Chronological play-by-play with interleaved tweets

## Environments

| Mode | Base URL | Use Case |
|------|----------|----------|
| `.live` | `sports-data-admin.dock108.ai` | Production |
| `.localhost` | `localhost:8000` | Local backend |
| `.mock` | N/A | Offline development |

Toggle via `AppConfig.shared.environment`.

## Data Contract

Models align with `scroll-down-api-spec`. When API changes:
1. Spec updates first
2. Then update Swift models

## Testing

```bash
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Do NOT

- Auto-commit changes
- Run commands requiring interactive input
- Run long commands (>5s) without periodic output
- Break progressive disclosure defaults
- Add dependencies without justification
- Use `print()` in production (use Logger)
