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
├── Services/            # TimeService (snapshot mode), ReadStateStore, ReadingPositionStore
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

## Game Status & Lifecycle

`GameStatus` is a `RawRepresentable` enum with forward-compatible `unknown(String)` fallback. Key cases: `scheduled`, `pregame`, `inProgress`, `live`, `completed`, `final`, `archived`, `postponed`, `canceled`.

**Computed properties (SSOT):**

| Property | True for | Purpose |
|----------|----------|---------|
| `isLive` | `.live`, `.inProgress` | Show live PBP, start polling |
| `isFinal` | `.final`, `.completed`, `.archived` | Enable mark-as-read, show wrap-up |
| `isPregame` | `.pregame`, `.scheduled` | Show pregame content only |

There is no `isCompleted` property — `isFinal` is the single source of truth for "game is over."

**Read state gating:** `ReadStateStore.markRead(gameId:status:)` requires a `GameStatus` and silently ignores non-final games. There is no nil default.

**Score reveal:** User preference via `ScoreRevealMode` (`.onMarkRead` spoiler-free default, `.always` shows all scores). Hold-to-reveal (long press) lets users check scores on demand without changing their preference. Live games support hold-to-update for fresh scores.

**Live polling:** `GameDetailViewModel.startLivePolling()` polls every ~45s for live games. Auto-stops on dismiss or when game transitions to final. The view re-renders based on the updated status — if flow data was already loaded it displays, otherwise PBP remains as fallback. A "PBP" button in the section nav bar provides access to the full play-by-play sheet whenever Game Flow is the primary view.

**Reading position:** `ReadingPositionStore` (UserDefaults-backed, local-only) tracks where the user stopped reading a game's PBP. Also saves scores at the reading position. Shows "Stopped at Q3 4:32" resume text in game header and home card, with score context ("@ Q2 · 2m ago") when scores are saved.

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
| `OddsEntry` | Per-book odds with `marketType`, `marketCategory`, `playerName`, `description` |
| `MarketCategory` | Category enum for grouping odds: mainline, playerProp, teamProp, alternate, period, gameProp |
| `MarketType` | Market type enum with `displayName` for human-readable stat labels (Points, Rebounds, etc.) and `isPlayerProp` helper |
| `ReadingPosition` | Codable model for user's reading position within a game's PBP timeline (playIndex, period, gameClock, labels, savedAt, awayScore, homeScore) |
| `ScoreRevealMode` | User preference enum: `.always`, `.onMarkRead` — controls when scores are shown |
| `TeamSummary` | Team name + color hex values from `/teams` endpoint |

### FairBet Data Models

| Model | Purpose |
|-------|---------|
| `APIBet` | Individual bet with server-side EV annotations (`trueProb`, `referencePrice`, `evConfidenceTier`, `evDisabledReason`) |
| `BookPrice` | Sportsbook price with optional server-side `evPercent`, `trueProb`, `isSharp`, `evConfidenceTier` |
| `BookEVResult` | Client-side EV calculation result per book |
| `BetsResponse` | API wrapper with `bets`, `booksAvailable`, `gamesAvailable`, `marketCategoriesAvailable`, `evDiagnostics` |
| `GameDropdown` | Game option for filter UI (gameId, matchup, gameDate) |
| `EVDiagnostics` | Server-side EV computation stats (pairs, unpaired, eligible counts) |
| `MarketFilter` | Filter enum: `.single(MarketKey)`, `.playerProps`, `.teamProps` |
| `FairOddsConfidence` | Confidence tier: `.high`, `.medium`, `.low`, `.none` |

## What the Server Provides

The backend pre-computes all derived data. The app does not compute these client-side:

| Data | Source | Used By |
|------|--------|---------|
| Period labels (`Q1`, `P2`, `H1`, `OT`) | `period_label` on each play | `UnifiedTimelineEvent.periodLabel` |
| Time labels (`Q4 2:35`) | `time_label` on each play | `UnifiedTimelineEvent.timeLabel` |
| Play tiers (1, 2, 3) | `tier` on each play | `PlayTier`, `TieredPlayGrouper` |
| Odds labels (`BOS -5.5`, `O/U 221.5`) | `derivedMetrics` on game detail | `DerivedMetrics` → `pregameOddsLines` |
| Odds outcomes (covered, went over, etc.) | `derivedMetrics` on game detail | `DerivedMetrics` → `wrapUpOddsLines` |
| Team colors (light/dark hex) | `GET /teams` + per-game API fields → `TeamColorCache` + inline hex on `GameSummary` | `DesignSystem.TeamColors`, `GameRowView` direct resolution |
| Team abbreviations | Per-game API fields → `TeamAbbreviations` | `TeamAbbreviations.abbreviation(for:)` |
| Merged timeline (PBP + tweets + odds) | `GET /games/{id}/timeline` → `TimelineArtifactResponse` | `unifiedTimelineEvents` |

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

## Game Detail Odds Section

The game detail view includes a cross-book odds comparison section (`GameDetailView+Odds.swift`):

- **Collapsed by default** — Uses `CollapsibleSectionCard` (Tier 3)
- **Category tabs** — Horizontal scroll of capsule buttons; only categories with data are shown (`MarketCategory`)
- **Player search** — TextField shown only on Player Props tab
- **Cross-book table** — Frozen market label column (120pt) + horizontally scrollable book columns
- Book columns use `BookNameHelper` abbreviations (DK, FD, MGM, CZR, etc.)
- Missing prices show `--`
- Data comes from `OddsEntry` fields on `GameDetailResponse`

**Category-specific rendering:**
- **Mainline** — Markets grouped into collapsible Moneyline / Spread / Total sections. Spreads sorted by absolute line; totals by line with over before under.
- **Team Props** — Markets grouped by team name (from `description`), each group collapsible.
- **Player Props** — Grouped by player name with bold name header, then by stat type sub-headers. Uses `MarketType.displayName` for stat labels (Points, Rebounds, etc.)
- **Alternates / Other** — Flat sorted table (by market type, line, side).

Groups are collapsible via `collapsedOddsGroups: Set<String>` state. Each group header shows market count and a chevron indicator.

ViewModel properties: `hasOddsData`, `availableOddsCategories`, `oddsBooks`, `oddsMarkets(for:)`, `oddsPrice(for:book:)`, `groupedPlayerPropMarkets(filtered:)`

## Team Stats

Team stats use a `KnownStat` definition list in `GameDetailViewModel`. Each stat defines:
- `keys` — All possible API key names (NBA snake_case, NCAAB camelCase)
- `label` — Display name
- `group` — Grouping: Overview, Shooting, or Extra
- `isPercentage` — Format as percentage if true

The app iterates definitions, checks if any key exists in the API response, and displays whatever is found. No client-side computation of derived stats. Groups only appear if they contain at least one stat with data.

Player stats use direct key lookup against `PlayerStat.rawStats`.

## FairBet Module

Betting odds comparison system that surfaces fair odds and expected value (EV) across sportsbooks.

**How it works:**
1. `FairBetAPIClient` fetches odds from `/api/fairbet/odds` (paginated, 500 per page, default `has_fair=true`)
2. Server provides EV annotations per bet: `trueProb`, `referencePrice`, `evConfidenceTier`, `evDisabledReason`
3. Server provides EV annotations per book: `evPercent`, `trueProb`, `isSharp`
4. `OddsComparisonViewModel` prefers server-side EV. Falls back to client-side computation (`BetPairing` + `EVCalculator`) when server annotations are absent.
5. `BetCard` renders each bet with EV, fair odds, confidence indicators, and book chips

**Server-side EV (preferred path):**
- The server computes `trueProb` via Pinnacle devig and provides confidence tiers (`high`, `medium`, `low`)
- `referencePrice` shows the Pinnacle reference line when available
- `evDisabledReason` explains why EV is unavailable (e.g., "Reference line unavailable")
- The client checks `evConfidenceTier` + `trueProb` + per-book `evPercent` before using server values

**Client-side EV (fallback path):**
- `BetPairing` pairs opposite sides of each market for fair odds via sharp book vig-removal
- `EVCalculator` computes EV per book using fair probabilities and book-specific fee models
- Confidence levels: high (2+ sharp books), medium (1 sharp book), low (no sharp books)

**Card layout (BetCard) — action-first design:**
- Row 1: Selection name (market-aware: player props show "Name Stat O/U Line") + league badge + market type
- Row 2: Context line (props/alts show "Away @ Home", mainlines show "vs Opponent") + date/time
- Divider
- **iPhone (compact):** Vertical decision stack:
  1. Primary book row — user's preferred sportsbook (or best available) with "Best" badge, EV%, tappable `BookAbbreviationButton`
  2. "Best available" callout — only shown when user's preferred book isn't the best
  3. Fair estimate — tappable card with outline border: "Est. fair +125" + info icon. Opens `FairExplainerSheet`
  4. Collapsible "Other books" — expandable list of remaining `MiniBookChip`s
- **iPad (regular):** Horizontal scroll of `MiniBookChip`s sorted by EV + Parlay button, then fair estimate card below
- FAIR is always **informational, never bettable** — visually distinct from sportsbook prices (outline border, secondary text color)
- Tapping FAIR opens `FairExplainerSheet` with: fair value header, "What is this?" explanation, devig math (method, true probabilities, opposite side, vig removed %, best EV), per-book implied probability breakdown, confidence tier with description, data sources list, disclaimer
- `BookAbbreviationButton` — tap to toggle between abbreviated and full sportsbook name
- Sharp book indicator (star icon) shown in `FairExplainerSheet` implied probability breakdown

`BookNameHelper` provides consistent sportsbook abbreviations (DraftKings→DK, FanDuel→FD, etc.) shared across primary book row, MiniBookChip, and odds table.

## Home View

The home screen has three modes via a segmented control (`HomeViewMode`):

| Tab | Content |
|-----|---------|
| Games | Game feed with Earlier/Yesterday/Today/Tomorrow sections, league filter, search bar |
| FairBet | Odds comparison with league/market filters. One-line explainer above filters. Only shows bets with server-side fair estimates (`has_fair=true`). Progressive loading — first 500 bets shown immediately, rest loaded in background. |
| Settings | Theme selection, odds format, score display preference |

The Games tab includes a search bar that filters by team name and a league filter (All, NBA, NCAAB, NHL). Both the Games and FairBet tabs have a refresh button overlaid on the league filter row.

**Spoiler-free actions (`.onMarkRead` mode only):**
- **Catch up to live** — Bulk-reveals all scores: marks final games as read + saves current live scores
- **Reset** — Undoes catch-up: marks all games as unread + clears saved reading positions/scores
- **iPad:** Icon buttons in the filter bar (eye / eye.slash icons alongside refresh)
- **iPhone:** Labeled pill buttons in a dedicated action row above the game list, with refresh moved to that row

## View Architecture

**GameDetailView** is split into focused extensions:

| File | Responsibility |
|------|---------------|
| `GameDetailView.swift` | Main container, navigation, state |
| `GameDetailView+Overview.swift` | Pregame section |
| `GameDetailView+Timeline.swift` | Flow/PBP timeline (PBP for live games, Flow for final) |
| `GameDetailView+Stats.swift` | Player and team stats |
| `GameDetailView+NHLStats.swift` | NHL-specific skater/goalie tables |
| `GameDetailView+WrapUp.swift` | Post-game wrap-up |
| `GameDetailView+Odds.swift` | Cross-book odds comparison table |
| `GameDetailView+Helpers.swift` | Utility functions, reading position tracking, section navigation |
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
| `GET /api/admin/sports/games/{id}` | Game detail (stats, plays, odds, derivedMetrics, groupedPlays) |
| `GET /api/admin/sports/games/{id}/flow` | Game flow (blocks + plays) |
| `GET /api/admin/sports/games/{id}/timeline` | Timeline artifact (summary, timeline JSON, game analysis) |
| `GET /api/admin/sports/pbp/game/{id}` | Play-by-play events |
| `GET /api/admin/sports/teams` | Team colors (name, light hex, dark hex) |
| `GET /api/social/posts/game/{id}` | Social posts |
| `GET /api/fairbet/odds` | Betting odds with server-side EV annotations (paginated, filterable) |

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
