# Architecture

iOS app structure, data flow, and design principles.

## Directory Layout

```
ScrollDown/Sources/
├── Models/           # Codable data models (API-aligned)
├── ViewModels/       # Business logic and state management
├── Screens/
│   ├── Home/         # Game list and feed
│   ├── Game/         # Game detail (split into extensions)
│   └── Team/         # Team page
├── Components/       # Reusable UI components
├── Networking/       # GameService protocol + implementations
├── Services/         # TimeService (snapshot mode)
├── Logging/          # Structured logging utilities
└── Mock/games/       # Static mock JSON for development
```

## MVVM Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         SwiftUI View                            │
│   (HomeView, GameDetailView, StoryBlockCardView, etc.)          │
└─────────────────────────┬───────────────────────────────────────┘
                          │ observes @Published
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                       ViewModel                                 │
│   GameDetailViewModel                                           │
│   • Holds @Published state                                      │
│   • Handles user actions                                        │
│   • Orchestrates service calls                                  │
│   • Computes derived timeline/stats data                        │
└─────────────────────────┬───────────────────────────────────────┘
                          │ calls async
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GameService                                │
│   protocol GameService { ... }                                  │
│   • MockGameService — returns errors (stories from real API)    │
│   • RealGameService — calls backend APIs                        │
└─────────────────────────────────────────────────────────────────┘
```

Views never call services directly. ViewModels mediate all data access.

## Core Principles

### 1. Progressive Disclosure
The app reveals information in layers. Users see context, matchups, and game flow before outcomes.

### 2. The Reveal Principle
We talk about **Reveal** (making outcomes visible) and **Outcome Visibility**.
- **Default:** Outcome-hidden
- **User Choice:** Users explicitly choose to uncover scores

### 3. User-Controlled Pacing
Nothing is auto-revealed. Users move through timeline at their own pace.

## Key Data Models

| Model | Description |
|-------|-------------|
| `GameSummary` | List view representation from `/games` endpoint |
| `GameDetailResponse` | Full game detail from `/games/{id}` |
| `GameStoryResponse` | Story with blocks and plays from `/games/{id}/story` |
| `StoryBlock` | Narrative segment with role, mini box score, period range |
| `StoryPlay` | Individual play within a story |
| `BlockDisplayModel` | UI-ready block for rendering |
| `BlockMiniBox` | Per-block player stats with blockStars |
| `UnifiedTimelineEvent` | Single timeline entry (PBP play or tweet) |
| `PlayEntry` | Individual play-by-play event |

### Block Structure

Each `StoryBlock` contains:
- `blockIndex` — Position in the story (0 to N-1)
- `role` — Server-provided semantic role (SETUP, MOMENTUM_SHIFT, etc.) — not displayed
- `narrative` — 1-2 sentence description (~35 words)
- `miniBox` — Player stats for this segment with `blockStars` array
- `periodStart`/`periodEnd` — Period range covered
- `scoreBefore`/`scoreAfter` — Score progression as `[away, home]`
- `keyPlayIds` — Plays explicitly mentioned in narrative
- `embeddedTweet` — Optional social content (structure ready, no live data yet)

### NHL-Specific Models

| Model | Description |
|-------|-------------|
| `NHLSkaterStat` | Skater stats (TOI, G, A, PTS, +/-, SOG, HIT, BLK, PIM) |
| `NHLGoalieStat` | Goalie stats (TOI, SA, SV, GA, SV%) |

## Story Rendering

The story system uses **blocks** as the primary display unit:

1. **Blocks** — Consumer-facing narrative segments
   - Server provides 4-7 blocks per game
   - Each block has narrative text + mini box score at bottom
   - Designed for ~2.5 blocks visible on screen at once
   - `blockStars` highlights top performers per block

2. **StoryAdapter** — Converts `GameStoryResponse` to `[BlockDisplayModel]`
   - Simple mapping, no client-side derivation
   - Server provides all semantic information

3. **Views:**
   - `StoryContainerView` — Renders block list with spine
   - `StoryBlockCardView` — Single block with narrative + mini box
   - `MiniBoxScoreView` — Per-block player stats

## Configuration

The app uses `AppConfig` to manage runtime behavior:

```swift
AppConfig.shared.environment  // .mock, .localhost, or .live
AppConfig.shared.gameService  // Returns appropriate service implementation
```

### Environments

| Environment | Base URL | Use Case |
|-------------|----------|----------|
| `.live` | `sports-data-admin.dock108.ai` | Production |
| `.localhost` | `localhost:8000` | Local backend dev |
| `.mock` | N/A | Offline UI development (no story data) |

### Dev Clock

`AppDate.now()` provides consistent timestamps:
- **Mock mode:** Fixed to November 12, 2024
- **Snapshot mode:** Frozen to user-specified date
- **Live mode:** Real system time

## Game Detail View Structure

`GameDetailView` is split into focused extensions:

| File | Responsibility |
|------|---------------|
| `GameDetailView.swift` | Main view, navigation, state, scroll handling |
| `GameDetailView+Overview.swift` | Pregame section |
| `GameDetailView+Timeline.swift` | Timeline/story section |
| `GameDetailView+Stats.swift` | Player and team stats |
| `GameDetailView+NHLStats.swift` | NHL-specific skater/goalie tables |
| `GameDetailView+WrapUp.swift` | Post-game wrap-up section |
| `GameDetailView+Helpers.swift` | Utility functions, quarter titles |
| `GameDetailView+Layout.swift` | Layout constants, preference keys |

## Interaction Patterns

All interactive elements use consistent patterns:

| Pattern | Implementation |
|---------|----------------|
| Tap feedback | `InteractiveRowButtonStyle` (opacity 0.6 + scale 0.98) |
| Chevron rotation | `chevron.right` with 0°→90° on expand |
| Expand animation | `spring(response: 0.3, dampingFraction: 0.8)` |
| Transitions | Asymmetric (opacity + move from top) |

## Navigation

Routes defined in `ContentView.swift`:

```swift
enum AppRoute: Hashable {
    case game(id: Int, league: String)
    case team(name: String, abbreviation: String, league: String)
    case deepLinkPlaceholder(String)
}
```

Navigation via `NavigationStack` with `navigationDestination(for: AppRoute.self)`.
