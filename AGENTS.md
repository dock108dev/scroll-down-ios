# AGENTS.md — Scroll Down iOS

> Context for AI agents (Claude, Cursor, Copilot) working on this codebase.

## Quick Context

**What is this?** Native iOS client for Scroll Down Sports — catch up on games without immediate score reveals.

**Tech Stack:** Swift 5.9+, SwiftUI, MVVM, iOS 17+

**No external dependencies.** Uses only Foundation and SwiftUI.

**Architecture:** The app is a thin display layer. The backend (`sports-data-admin`) computes all derived data — period labels, play tiers, odds outcomes, team colors, and merged timelines. The iOS client reads pre-computed values from the API and renders them.

## Directory Layout

```
ScrollDown/Sources/
├── Models/              # Codable data models (API-aligned)
├── ViewModels/          # State management, data loading
├── Screens/
│   ├── Home/            # Game list feed
│   ├── Game/            # Game detail view (split into extensions)
│   └── Team/            # Team page
├── Components/          # Reusable UI (CollapsibleCards, LoadingSkeletonView, FlowLayout)
├── Extensions/          # Swift extensions (String+Abbreviation)
├── Networking/          # GameService protocol + implementations, FlowAdapter, TeamColorCache
├── Services/            # TimeService (snapshot mode)
├── Logging/             # Structured logging (GameRoutingLogger, GameStatusLogger)
├── Theme/               # Typography system
├── FairBet/             # Betting odds comparison module
│   ├── Models/          # Bet, EVCalculator, OddsCalculator, BetPairing
│   ├── ViewModels/      # OddsComparisonViewModel
│   ├── Views/           # OddsComparisonView, BetCard, ParlaySheetView, FairBetCopy
│   ├── Services/        # FairBetAPIClient, FairBetMockDataProvider
│   └── Theme/           # FairBetTheme
└── Mock/games/          # Static mock JSON for development
```

## Core Principles

1. **Progressive disclosure** — Context before scores; users arrive after games end
2. **User-controlled pacing** — They decide when to reveal results
3. **Mobile-first** — Touch navigation, vertical scrolling, collapsible sections
4. **Server-driven display** — The backend computes derived data; the app renders it

## Key Data Models

| Model | Purpose |
|-------|---------|
| `GameSummary` | List view representation (home feed) |
| `GameDetailResponse` | Full game detail with plays, stats, odds, derived metrics |
| `DerivedMetrics` | Type-safe accessor for server-computed odds labels and outcomes |
| `GameFlowResponse` | Flow with blocks and plays from `/games/{id}/flow` |
| `FlowBlock` | Narrative segment with role, mini box, period range |
| `FlowPlay` | Individual play within a flow |
| `BlockDisplayModel` | UI-ready block for rendering |
| `BlockMiniBox` | Per-block player stats with `blockStars` |
| `UnifiedTimelineEvent` | Single timeline entry (PBP, tweet, or odds event) |
| `PlayEntry` | Individual play-by-play event with `periodLabel`, `timeLabel`, `tier` |
| `TeamSummary` | Team name + color hex values from `/teams` endpoint |

### FairBet Data Models

| Model | Purpose |
|-------|---------|
| `APIBet` | Individual bet from the FairBet API |
| `BookPrice` | Sportsbook price with book name and observed time |
| `BookEVResult` | EV calculation result per book |

## What the Server Provides

The backend pre-computes all derived data. The app does not compute these client-side:

| Data | Source | Used By |
|------|--------|---------|
| Period labels (`Q1`, `P2`, `H1`, `OT`) | `period_label` on each play | `UnifiedTimelineEvent.periodLabel` |
| Time labels (`Q4 2:35`) | `time_label` on each play | `UnifiedTimelineEvent.timeLabel` |
| Play tiers (1, 2, 3) | `tier` on each play | `PlayTier`, `TieredPlayGrouper` |
| Odds labels (`BOS -5.5`, `O/U 221.5`) | `derivedMetrics` on game detail | `DerivedMetrics` → `pregameOddsLines` |
| Odds outcomes (covered, went over, etc.) | `derivedMetrics` on game detail | `DerivedMetrics` → `wrapUpOddsLines` |
| Team colors (light/dark hex) | `GET /teams` + per-game API fields → `TeamColorCache` | `DesignSystem.TeamColors` |
| Team abbreviations | Per-game API fields → `TeamAbbreviations` | `TeamAbbreviations.abbreviation(for:)` |
| Merged timeline (PBP + tweets + odds) | `GET /games/{id}/timeline` | `unifiedTimelineEvents` |

## Flow Architecture

The app renders completed games using a **blocks-based** flow system:

1. **Blocks** — Primary narrative units (4-7 per game)
   - Each block has: narrative text, mini box score, period range, scores
   - `blockStars` array highlights top performers in that segment
   - Server provides `role` (SETUP, MOMENTUM_SHIFT, etc.) — not displayed
   - `keyPlayIds` marks explicitly narrated plays

2. **FlowAdapter** — Converts `GameFlowResponse` to `[BlockDisplayModel]`
   - Simple mapping, server provides all semantic info

3. **Views:**
   - `FlowContainerView` — Block list with visual spine
   - `FlowBlockCardView` — Single block with mini box at bottom
   - `MiniBoxScoreView` — Compact player stats per block

4. **PBP Timeline** — When flow data isn't available, unified timeline events render chronologically grouped by period, tiered by server-provided `tier` values:
   - **Tier 1** — Scoring plays: accent bar, team badge, bold text, score line
   - **Tier 2** — Notable plays: indented, medium-weight, left accent line
   - **Tier 3** — Routine plays: double-indented, minimal dot indicator

## Team Stats

Team stats use a `KnownStat` definition list in `GameDetailViewModel`. Each stat defines:
- `keys` — All possible API key names (NBA snake_case, NCAAB camelCase)
- `label` — Display name
- `group` — Grouping: Overview, Shooting, or Extra
- `isPercentage` — Format as percentage if true

The app iterates definitions, checks if any key exists in the API response, and displays whatever is found. No client-side computation of derived stats. Groups only appear if they contain at least one stat with data.

Player stats use direct key lookup against `PlayerStat.rawStats`.

## FairBet Module

Betting odds comparison system that computes fair odds and expected value (EV) across sportsbooks.

**How it works:**
1. `FairBetAPIClient` fetches odds from `/api/fairbet/odds`
2. `BetPairing` pairs opposite sides of each market for fair odds computation
3. `EVCalculator` computes expected value per book using fair probabilities and book-specific fee models
4. `OddsComparisonViewModel` orchestrates filtering, sorting, and EV caching
5. `BetCard` renders each bet as an always-visible card with EV, fair odds, and book chips

**Card layout (BetCard):**
- Row 1: Selection name + league badge + market type
- Row 2: Opponent + date/time
- Divider
- **iPhone (compact):** Vertical decision stack — Fair odds chip + Parlay button, anchor book row (preferred sportsbook or best available), optional best-available disclosure, collapsible "Other books" with MiniBookChips
- **iPad (regular):** Horizontal scroll — Fair odds chip, separator, scrollable MiniBookChip row sorted by EV, Parlay button

`BookNameHelper` provides consistent sportsbook abbreviations (DraftKings→DK, FanDuel→FD, etc.) shared across anchor row and MiniBookChip.

## Home View

The home screen has three modes via a segmented control (`HomeViewMode`):

| Tab | Content |
|-----|---------|
| Games | Game feed with Earlier/Yesterday/Today/Tomorrow sections, league filter, search bar |
| Current Odds | FairBet odds comparison with league filter |
| Settings | Theme selection, odds format, completed game tracking |

The Games tab includes a search bar that filters by team name and a league filter (All, NBA, NCAAB, NHL). Both the Games and Current Odds tabs have a refresh button overlaid on the league filter row.

## View Architecture

**GameDetailView** is split into focused extensions:

| File | Responsibility |
|------|---------------|
| `GameDetailView.swift` | Main container, navigation, state |
| `GameDetailView+Overview.swift` | Pregame section |
| `GameDetailView+Timeline.swift` | Flow/PBP timeline |
| `GameDetailView+Stats.swift` | Player and team stats |
| `GameDetailView+NHLStats.swift` | NHL-specific skater/goalie tables |
| `GameDetailView+WrapUp.swift` | Post-game wrap-up |
| `GameDetailView+Helpers.swift` | Utility functions |
| `GameDetailView+Layout.swift` | Layout constants, preference keys |

## Environments

**Default: `.live`** — The app always uses the live production API.

| Mode | Base URL | Use Case |
|------|----------|----------|
| `.live` | `sports-data-admin.dock108.ai` | Production (default) |
| `.localhost` | `localhost:8000` | Local backend development |
| `.mock` | N/A (local data) | Offline development with `MockGameService` |

**Testing:** All testing should use the live API with non-proprietary sports data. The production database is active and ready.

## API Endpoints

App uses authenticated endpoints (X-API-Key header):

| Endpoint | Purpose |
|----------|---------|
| `GET /api/admin/sports/games` | List games (with startDate, endDate, league filters) |
| `GET /api/admin/sports/games/{id}` | Game detail (stats, plays, derivedMetrics, groupedPlays) |
| `GET /api/admin/sports/games/{id}/flow` | Game flow (blocks + plays) |
| `GET /api/admin/sports/games/{id}/timeline` | Unified timeline (merged PBP + tweets + odds) |
| `GET /api/admin/sports/pbp/game/{id}` | Play-by-play events |
| `GET /api/admin/sports/teams` | Team colors (name, light hex, dark hex) |
| `GET /api/social/posts/game/{id}` | Social posts |
| `GET /api/fairbet/odds` | Betting odds across sportsbooks |

## Navigation

Routes defined in `ContentView.swift`:

```swift
enum AppRoute: Hashable {
    case game(id: Int, league: String)
    case team(name: String, abbreviation: String, league: String)
}
```

Navigation via `NavigationStack` with `navigationDestination(for: AppRoute.self)`.

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
- Add client-side computation for data the server already provides
