# Architecture

iOS app structure, data flow, and design principles.

## Directory Layout

```
ScrollDown/Sources/
├── Models/           # Codable data models (API-aligned)
├── ViewModels/       # Business logic and state management
├── Screens/
│   ├── Home/         # Game list and feed
│   └── Game/         # Game detail (split into extensions)
├── Components/       # Reusable UI components
├── Networking/       # GameService protocol + implementations
├── Services/         # TimeService, SocialPostMatcher
├── Logging/          # Structured logging utilities
└── Mock/games/       # Static mock JSON for development
```

## MVVM Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         SwiftUI View                            │
│   (HomeView, GameDetailView, StorySectionCardView, etc.)        │
└─────────────────────────┬───────────────────────────────────────┘
                          │ observes
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                       ViewModel                                 │
│   GameDetailViewModel                                           │
│   • Holds @Published state                                      │
│   • Handles user actions                                        │
│   • Orchestrates service calls                                  │
│   • Computes derived timeline/stats data                        │
└─────────────────────────┬───────────────────────────────────────┘
                          │ calls
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
| `GameStoryResponse` | Story with chapters, sections, and compact narrative |
| `SectionEntry` | Narrative segment (beat type, score range, header) |
| `ChapterEntry` | Grouping of plays within a section |
| `UnifiedTimelineEvent` | Single timeline entry (PBP play or tweet) |
| `PlayEntry` | Individual play-by-play event |

### NHL-Specific Models

| Model | Description |
|-------|-------------|
| `NHLSkaterStat` | Skater stats (TOI, G, A, PTS, +/-, SOG, HIT, BLK, PIM) |
| `NHLGoalieStat` | Goalie stats (TOI, SA, SV, GA, SV%) |

## Timeline Rendering

The timeline uses a two-tier system:

### 1. Story-Based (Primary)
When `GameStoryResponse` is available from `/games/{id}/story`:
- Sections grouped by period with narrative headers
- Each section has a beat type (FAST_START, RUN, BACK_AND_FORTH, etc.)
- Expanding a section reveals its play-by-play events
- Social posts matched to relevant sections via `SocialPostMatcher`

### 2. PBP-Based (Fallback)
When story data isn't available:
- `UnifiedTimelineEvent` entries grouped by quarter/period
- Chronological play-by-play with interleaved tweets
- Collapsible period sections

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
| `GameDetailView.swift` | Main view, navigation, state |
| `GameDetailView+Overview.swift` | Pregame section |
| `GameDetailView+Timeline.swift` | Timeline/story section |
| `GameDetailView+Stats.swift` | Player and team stats |
| `GameDetailView+Helpers.swift` | Utility functions |
| `GameDetailView+Layout.swift` | Layout constants |
