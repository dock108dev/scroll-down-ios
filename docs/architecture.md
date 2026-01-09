# Architecture

This document describes the iOS app's structure, data flow, and design principles.

## Directory Layout

```
ScrollDown/Sources/
├── Models/           # Codable data models (aligned with API spec)
├── ViewModels/       # Business logic and state management (MVVM)
├── Screens/          # Full-screen SwiftUI views
│   ├── Home/         # Game list and feed views
│   └── Game/         # Game detail, timeline, and moment views
├── Components/       # Reusable UI components
├── Networking/       # GameService protocol + mock/real implementations
└── Mock/             # Structured mock data for development
```

## MVVM Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         SwiftUI View                            │
│   (HomeView, GameDetailView, CompactTimelineView, etc.)         │
└─────────────────────────┬───────────────────────────────────────┘
                          │ observes
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                       ViewModel                                 │
│   (GameDetailViewModel, CompactMomentPbpViewModel)              │
│   • Holds @Published state                                      │
│   • Handles user actions                                        │
│   • Orchestrates service calls                                  │
└─────────────────────────┬───────────────────────────────────────┘
                          │ calls
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GameService                                │
│   protocol GameService { ... }                                  │
│   • MockGameService — returns structured local data             │
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

## Key Mechanisms

### Outcome Reveal Gate
Implemented in the `Overview` section of `GameDetailView`.
- **Persistence:** Saved per-game in `UserDefaults` using the key `game.outcomeRevealed.{gameId}`.
- **Reversibility:** Users can toggle back to "Hidden" at any time.
- **Backend Sync:** Switching reveal state triggers a reload of the AI summary with the appropriate `reveal` parameter (`pre` or `post`).

### Timeline Narrative
Timeline moments are grouped by period/quarter with collapsible sections.
- **Moment Summaries:** Narrative bridges between play clusters.
- **Score Separators:** Scores appear at natural breakpoints (halftime, period end) rather than inline with individual plays to maintain tension.
- **Pagination:** Long play sequences are chunked (20 events per cluster) to avoid overwhelming the user.

### Reveal-Aware Social
Social posts that may contain outcomes are blurred by default. Tapping the post reveals the content, matching the overall reveal philosophy.

## Configuration

The app uses `AppConfig` to manage runtime behavior:

```swift
AppConfig.shared.environment   // .mock or .live
AppConfig.shared.gameService // Returns appropriate service implementation
```

A dev clock (`AppDate.now()`) provides consistent timestamps in mock mode, fixed to November 12, 2024.
