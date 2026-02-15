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
│   • Reads pre-computed data from API responses                  │
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

The app is a **thin display layer**. The backend computes all derived data (period labels, play tiers, odds outcomes, team colors, merged timelines). The ViewModel reads these pre-computed values and exposes them to views.

## Core Principles

See [AGENTS.md — Core Principles](../AGENTS.md) for Progressive Disclosure, the Reveal Principle, and User-Controlled Pacing.

## Server-Driven Data

See [AGENTS.md — Server-Driven Data](../AGENTS.md) for the full list of server-provided values.

### Team Color System

Team colors come from two sources:
1. **Bulk fetch** — `TeamColorCache.loadCachedOrFetch()` on app launch, cached in UserDefaults (7-day TTL)
2. **Per-game injection** — API responses include `homeTeamColorLight`/`homeTeamColorDark` fields, injected into `TeamColorCache` on load

```
App Launch → TeamColorCache.loadCachedOrFetch()
                    │
                    ├─ Disk cache valid? → Use cached colors
                    └─ Expired/empty?    → GET /api/admin/sports/teams → cache

Game Detail / Flow / Home Feed → inject(teamName:lightHex:darkHex:)
                                     │
DesignSystem.TeamColors.color(for:) → TeamColorCache.color(for:)
                                         │
                                         ├─ Exact match? → (light, dark) UIColor pair
                                         ├─ Prefix match? → (light, dark) UIColor pair
                                         └─ Unknown? → .systemIndigo
```

Color clash detection prevents two similar team colors in matchup views.

## Flow Rendering

See [AGENTS.md — Flow Architecture](../AGENTS.md) for the blocks/FlowAdapter/views overview.

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

## Team Stats

See [AGENTS.md — Team Stats](../AGENTS.md) for the KnownStat pattern overview.

```
API Response (JSONB stats dict)
     │
     ▼
KnownStat definitions (ordered list)
     │ For each: try keys[0], keys[1], ... against stats dict
     ▼
TeamComparisonStat (name, homeValue, awayValue, formatted display)
     │
     ▼
TeamStatsContainer → grouped by Overview / Shooting / Extra
```

Each `KnownStat` lists all possible API key variants for a stat, a display label, a group, and whether it's a percentage. Stats only appear if the API returned data for at least one key variant. No client-side derived stats.

Player stats use direct key lookup against `PlayerStat.rawStats`.

## FairBet Architecture

See [AGENTS.md — FairBet](../AGENTS.md) for the pipeline overview.

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
AppConfig.shared.environment  // .live (default), .localhost, or .mock
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
