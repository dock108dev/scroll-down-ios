# Changelog

Notable changes to the Scroll Down iOS app.

## [Unreleased]

### Changed — Server-Side Migration (Feb 2025)

Moved all derived computation to the backend. The app is now a thin display layer:

**Eliminated client-side computation:**
- Period labels — app reads `periodLabel` from each event (was: `periodLabel(for:sport:)` with NBA/NHL/NCAAB switch logic)
- Play tiers — app reads `tier` from each event (was: `PlayTierClassifier` with ~337 lines of heuristics)
- Odds lines/outcomes — app reads from `DerivedMetrics` (was: `bestOddsEntry()`, `computePregameOddsClientSide()`, `computeOddsResultClientSide()`)
- Timeline merging — app reads unified timeline from server (was: `buildTimelineFromSources()` merging 3 data sources)
- Team colors — app reads from `TeamColorCache` fetched via `/teams` (was: ~450 lines of hardcoded color dictionaries)

**New models:**
- `DerivedMetrics` — type-safe accessor for server-computed odds labels and outcomes
- `ServerTieredPlayGroup` — server-provided play groupings
- `TeamColorCache` — singleton cache for team colors with UserDefaults persistence (7-day TTL)

**New API endpoints consumed:**
- `GET /api/admin/sports/teams` — team colors
- `GET /api/admin/sports/games/{id}/timeline` — unified timeline (merged PBP + tweets + odds)

**New event type:**
- `UnifiedTimelineEvent` now supports `.odds` events (oddsType, oddsMarkets)

### Added - FairBet Odds Comparison
- `OddsComparisonView` with filterable bet list
- `BetCard` always-visible card layout (selection, opponent, EV, fair odds, books grid)
- `FairOddsCalculator` using sharp book vig-removal and median aggregation
- `EVCalculator` with per-book fee models (P2P, exchange, traditional)
- `BetPairing` for matching opposite sides of markets
- `FairBetAPIClient` fetching from `/api/fairbet/odds`

### Changed - Blocks-Based Flow System (Feb 2025)
Migrated to blocks-based flow architecture:

**Models:**
- `FlowBlock` as primary narrative unit
- `BlockDisplayModel` for UI rendering
- `BlockMiniBox` with `blockStars` for top performers
- `BlockPlayerStat` includes delta stats (cumulative + per-block changes)
- Server-provided `BlockRole` (SETUP, MOMENTUM_SHIFT, etc.)

**Views:**
- `FlowContainerView` renders block list with spine
- `FlowBlockCardView` shows narrative + mini box score at bottom
- `MiniBoxScoreView` displays top 2 players per team with blockStar highlighting

### Added - Interaction Polish (Jan 2025)
- Unified `InteractiveRowButtonStyle` for consistent tap feedback
- `SubtleInteractiveButtonStyle` for less prominent elements
- Standardized chevron behavior (chevron.right, 0 to 90 degree rotation)
- Standardized spring animations across all collapsible sections
- Tab bar scroll-to-section with re-tap support
- Clickable team headers in game detail (navigates to team page)
- `TeamView` for team page display
- Styled play descriptions with visual hierarchy

### Added - Timeline Improvements
- Global expand/collapse for timeline boundaries via header tap
- Full row tap targets on boundary headers
- `contentShape(Rectangle())` for reliable touch handling

### Added - NHL Support
- `NHLSkaterStat` and `NHLGoalieStat` models
- Dedicated NHL stats tables (Skaters/Goalies)
- Sport-aware period labels (Period 1/2/3 vs Q1/Q2/Q3/Q4)

---

## Earlier Releases

- Timeline API integration (`/games/{game_id}/timeline`, unified events)
- Loading skeleton placeholders, enhanced empty states, tap-to-retry
- Social feed with tap-to-reveal blur
- Explicit reveal control, per-game reveal persistence
- Period/quarter grouping with collapsible sections, PBP pagination
- Home feed with Earlier/Today/Upcoming sections
- Game detail with collapsible sections, dev-mode clock
- MVVM architecture, SwiftUI views with dark mode
- Mock and real service implementations
