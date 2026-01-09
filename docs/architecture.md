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

## Core Design Principles

### Progressive Disclosure
The app reveals information in layers. Users see context, matchups, and game flow before outcomes. This respects how games unfold over time.

### User-Controlled Pacing
Nothing is auto-revealed. The user moves through timeline moments at their own pace, tapping to expand details when they're ready.

### Mobile-First Experience
The UI is designed for touch navigation and vertical scrolling. Key screens:

| Screen | Purpose |
|--------|---------|
| **HomeView** | Game feed grouped by Earlier/Today/Upcoming |
| **GameDetailView** | Collapsible sections for game context |
| **CompactTimelineView** | Chapter-style moments for paced catch-up |
| **CompactMomentExpandedView** | Play-by-play detail for a single moment |

## Key Screens

### Home Feed
Displays games grouped by temporal context:
- **Earlier** — Games from the past 2 days
- **Today** — Today's games (auto-scrolls here on load)
- **Upcoming** — Future scheduled games

### Game Detail
Collapsible card sections that progressively reveal:
1. Overview (teams, time, status)
2. Matchup context
3. Timeline moments
4. Team stats
5. Related content

### Compact Timeline
A chapter-style list of key moments. Each moment expands inline to show its play-by-play slice. Score chips appear at natural break points (halftime, period end) rather than inline with plays.

## Configuration

The app uses `AppConfig` to manage runtime behavior:

```swift
AppConfig.shared.environment   // .mock or .live
AppConfig.shared.gameService // Returns appropriate service implementation
```

A dev clock (`AppDate.now()`) provides consistent timestamps in mock mode, fixed to November 12, 2024.
