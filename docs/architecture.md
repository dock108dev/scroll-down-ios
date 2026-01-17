# Architecture

This document describes the iOS app's structure, data flow, and design principles.

## Directory Layout

```
ScrollDown/Sources/
├── Models/           # Codable data models (aligned with API spec)
├── ViewModels/       # Business logic and state management
├── Screens/          # Full-screen SwiftUI views
│   ├── Home/         # Game list and feed views
│   └── Game/         # Game detail, timeline, stats, social views
├── Components/       # Reusable UI components
├── Networking/       # GameService protocol + mock/real implementations
├── Services/         # TimeService (snapshot mode)
├── Logging/          # Structured logging utilities
└── Mock/             # Structured mock data for development
```

## MVVM Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         SwiftUI View                            │
│   (HomeView, GameDetailView, MomentCardView, etc.)              │
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

## Core Product Principles

### 1. Progressive Disclosure
The app reveals information in layers. Users see context, matchups, and game flow before outcomes. This respects how games unfold over time.

### 2. The Reveal Principle
We never use the word "spoiler." Instead, we talk about **Reveal** (making outcomes visible) and **Outcome Visibility**.
- **Default:** Always outcome-hidden (`reveal=pre`).
- **User Choice:** Users must explicitly choose to uncover scores and results.
- **Why:** The app respects curiosity, not impatience.

### 3. User-Controlled Pacing
Nothing is auto-revealed. The user moves through timeline moments at their own pace, tapping to expand details when they're ready.

## Key Data Models

| Model | Description |
|-------|-------------|
| `GameSummary` | List view representation from `/games` endpoint |
| `GameDetailResponse` | Full game detail from `/games/{id}` |
| `Moment` | Server-generated timeline segment (groups plays) |
| `UnifiedTimelineEvent` | Single timeline entry (PBP or tweet) |
| `PlayEntry` | Individual play-by-play event |

## Key Mechanisms

### Timeline Rendering

The timeline uses a two-tier system:

1. **Moments** (primary) — Server-generated segments that partition the game. Each moment groups related plays with narrative context.
2. **UnifiedTimelineEvents** (fallback) — Direct PBP + tweet events when moments aren't available.

Timeline is grouped by quarter with collapsible sections.

### Outcome Reveal Gate
Implemented in the `Overview` section of `GameDetailView`.
- **Persistence:** Saved per-game in `UserDefaults` using the key `game.outcomeRevealed.{gameId}`.
- **Reversibility:** Users can toggle back to "Hidden" at any time.

### Reveal-Aware Social
Social posts that may contain outcomes are blurred by default. Tapping the post reveals the content, matching the overall reveal philosophy.

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
