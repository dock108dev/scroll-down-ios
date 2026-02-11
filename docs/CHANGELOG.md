# Changelog

Notable changes to the Scroll Down iOS app.

## [Unreleased]

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

## Phase G - Timeline API Integration
- Timeline artifact fetch from `/games/{game_id}/timeline`
- Unified timeline events combining PBP and social posts

## Phase F - Quality Polish
- Loading skeleton placeholders
- Enhanced empty states with contextual icons
- Tap-to-retry for error states

## Phase E - Social Blending
- Social feed with tap-to-reveal blur
- Social service in Mock/Real environments

## Phase D - Recaps & Reveal Control
- Explicit reveal control in Game Detail
- Per-game reveal preference persistence
- Context section ("why the game mattered")

## Phase C - Timeline Usability
- Period/quarter grouping with collapsible sections
- Pagination for long PBP sequences
- LIVE indicator for current period

## Phase B - Real Feeds
- Home feed with Earlier/Today/Upcoming sections
- Game detail with collapsible sections
- Dev-mode clock for consistent mock data

## Phase A - Foundation
- Basic MVVM architecture
- SwiftUI views with dark mode
- Mock and real service implementations
