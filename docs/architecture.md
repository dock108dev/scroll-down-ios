# Architecture

iOS app structure, data flow, and design principles.

For directory layout, data models, API endpoints, and environment reference, see [AGENTS.md](../AGENTS.md).

## MVVM Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         SwiftUI View                            │
│   (HomeView, GameDetailView, FlowBlockCardView, etc.)           │
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
│   • MockGameService — generated local data for offline dev      │
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

## Flow Rendering

The flow system uses **blocks** as the primary display unit:

1. **Blocks** — Consumer-facing narrative segments
   - Server provides 4-7 blocks per game
   - Each block has narrative text + mini box score at bottom
   - Designed for ~2.5 blocks visible on screen at once
   - `blockStars` highlights top performers per block

2. **FlowAdapter** — Converts `GameFlowResponse` to `[BlockDisplayModel]`
   - Simple mapping, no client-side derivation
   - Server provides all semantic information

3. **Views:**
   - `FlowContainerView` — Renders block list with spine
   - `FlowBlockCardView` — Single block with narrative + mini box
   - `MiniBoxScoreView` — Per-block player stats

4. **PBP Timeline** — When flow data isn't available, PBP events render chronologically grouped by period.

### Block Structure

Each `FlowBlock` contains:
- `blockIndex` — Position in the flow (0 to N-1)
- `role` — Server-provided semantic role (SETUP, MOMENTUM_SHIFT, etc.) — not displayed
- `narrative` — 1-2 sentence description (~35 words)
- `miniBox` — Player stats for this segment with `blockStars` array
- `periodStart`/`periodEnd` — Period range covered
- `scoreBefore`/`scoreAfter` — Score progression as `[away, home]`
- `keyPlayIds` — Plays explicitly mentioned in narrative

### NHL-Specific Models

| Model | Description |
|-------|-------------|
| `NHLSkaterStat` | Skater stats (TOI, G, A, PTS, +/-, SOG, HIT, BLK, PIM) |
| `NHLGoalieStat` | Goalie stats (TOI, SA, SV, GA, SV%) |

## FairBet Architecture

The FairBet module computes fair odds and expected value across sportsbooks:

```
FairBetAPIClient → [APIBet] → BetPairing → FairOddsCalculator → EVCalculator
                                                                       │
OddsComparisonViewModel ← caches EV results ← ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
       │
       ▼
OddsComparisonView → BetCardV2 (always-visible card layout)
```

**Fair Odds Computation:**
- Uses sharp book (Pinnacle, Circa, BetCris) vig-removal and median aggregation
- Confidence levels: high (2+ sharp books), medium (1 sharp book), low (no sharp books)

**EV Computation:**
- Per-book EV using fair probability and book-specific fee models
- P2P platforms (Novig, ProphetX) have 2% fee on winnings
- Exchanges (Betfair, Smarkets) have 1% fee on winnings
- Traditional sportsbooks have no explicit fee

## Configuration

The app uses `AppConfig` to manage runtime behavior:

```swift
AppConfig.shared.environment  // .localhost or .live
AppConfig.shared.gameService  // Returns appropriate service implementation
```

### Dev Clock

`AppDate.now()` provides consistent timestamps:
- **Mock mode:** Fixed to November 12, 2024
- **Snapshot mode:** Frozen to user-specified date
- **Live mode:** Real system time

## Game Detail View Structure

`GameDetailView` is split into focused extensions. See [AGENTS.md](../AGENTS.md) for the full file table.

Sections render conditionally based on game status:
- **Pregame (Overview):** Matchup context
- **Timeline:** Flow blocks (primary) or PBP grouped by period
- **Stats:** Player stats + team comparison
- **NHL Stats:** Sport-specific skater/goalie tables
- **Wrap-Up:** Post-game final score, highlights

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
}
```

Navigation via `NavigationStack` with `navigationDestination(for: AppRoute.self)`.
