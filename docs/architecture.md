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
│   (HomeView, GameDetailView, MomentCardView, etc.)              │
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
│   • MockGameService — generates local data                      │
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
| `GameStoryResponse` | Story with moments and plays from `/games/{id}/story` |
| `StoryMoment` | Narrative segment with play IDs, scores, period/clock |
| `StoryPlay` | Individual play within a story |
| `MomentDisplayModel` | UI-ready moment with derived beat type |
| `UnifiedTimelineEvent` | Single timeline entry (PBP play or tweet) |
| `PlayEntry` | Individual play-by-play event |
| `BeatType` | Narrative moment classification |

### NHL-Specific Models

| Model | Description |
|-------|-------------|
| `NHLSkaterStat` | Skater stats (TOI, G, A, PTS, +/-, SOG, HIT, BLK, PIM) |
| `NHLGoalieStat` | Goalie stats (TOI, SA, SV, GA, SV%) |

## Timeline Rendering

The timeline uses a two-tier system:

### 1. Story-Based (Primary)
When `GameStoryResponse` is available from `/games/{id}/story`:
- Moments grouped with narrative text
- Each moment has a beat type (FAST_START, RUN, BACK_AND_FORTH, etc.)
- Beat types derived via `StoryAdapter` from scoring patterns
- Expanding a moment reveals its play-by-play events
- `MomentCardView` renders individual moments

### 2. PBP-Based (Fallback)
When story data isn't available:
- `UnifiedTimelineEvent` entries grouped by quarter/period
- Chronological play-by-play with interleaved tweets
- Collapsible period sections via `CollapsibleQuarterCard`

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
| `.mock` | N/A | Offline UI development |

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
| `GameDetailView+Timeline.swift` | Timeline/story section with moment grouping |
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
