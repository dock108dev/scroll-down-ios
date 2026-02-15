# Changelog

Notable changes to the Scroll Down iOS app.

## [Unreleased]

### Changed — Documentation & Import Cleanup (Feb 2025)

- Deduplicated `architecture.md` — replaced duplicated sections with cross-references to `AGENTS.md`
- Removed unnecessary `import AVKit` from `SocialMediaPreview.swift` and `SocialPostRow.swift`
- Added clarifying "why" comments at 3 non-obvious code sites

### Changed — Codebase Cleanup (Feb 2025)

**Legacy file deletion (11 files):**
- Deleted dead design-system docs: `ContentHierarchy.swift`, `VisualRhythm.swift`, `CardDiscipline.swift`, `UIPolishChecklist.swift`
- Deleted unused container types: `ThemedSection.swift`, `CollapsibleSection.swift`, `ExpansionCard.swift` (consolidated into `CollapsibleSectionCard`)
- Deleted stale models: `BetGroup.swift`, `SelectionEVResult.swift`
- Deleted unused utilities: `OddsDataService.swift`, `ScrollDownTests.swift`

**FairBet module streamlined:**
- Removed `BetGroup` and `SelectionEVResult` types
- `FairOddsCalculator` reduced to `FairOddsConfidence` enum (computation moved to `BetPairing`)
- Server-side EV annotations added to `APIBet` and `BookPrice`

**Other changes:**
- BetCard parlay button repositioned (right-aligned)
- Games API limit reduced from 500 to 200 for faster loading
- Container types consolidated to `CollapsibleSectionCard`

### Changed — Display & Data Cleanup (Feb 14, 2025)

**Team Stats overhaul:**
- Replaced fixed key list + alias system with unified `KnownStat` definitions
- Stats grouped into Overview, Shooting, and Extra — each group only shown if it has data
- Displays whatever the API returns; no client-side derived stats
- Removed `statKeyAliases` bridge and `OddsResult` fallback path

**Legacy code elimination:**
- Deleted `OddsResult` struct and fallback odds display (replaced by `wrapUpOddsLines`)
- Deleted `FeatureFlags` enum (`defaultToLocalhost`, `showCardPlayCounts` — never referenced)
- Deleted duplicate `teamAbbreviation` dictionary (30 NBA teams hardcoded — now uses `TeamAbbreviations`)
- Deleted duplicate `abbreviatedPlayerName` function
- Simplified `resolveRawStat` to direct key lookup

**PBP tier visual hierarchy:**
- Tier 1: team badge (colored capsule), accent bar, score line, bold text
- Tier 2: indented once, medium-weight font, left accent line
- Tier 3: indented twice, minimal dot indicator, lightest text

**Other changes:**
- Wrap-up odds now show 6 rows (open + close for spread, O/U, moneyline)
- Simplified outcome labels — stripped verbose "by X.X" and "won (xxx)" suffixes
- Widened team label column (40 → 48) for 4-character abbreviations
- Enhanced tweet text sanitization — strip URLs, clean leftover punctuation, collapse blank lines
- Added refresh button to both Games and Current Odds league filter rows
- Team colors and abbreviations injected from per-game API fields (in addition to bulk `/teams` fetch)

### Added — Home View Features (Feb 12-13, 2025)

- Search bar for filtering games by team name
- Theme selection in Settings (system, light, dark)
- `HomeViewMode` segmented control: Games / Current Odds / Settings
- Yesterday and Tomorrow sections (was: Earlier/Today/Upcoming)
- Cache validation: same-calendar-day check and 15-minute freshness TTL
- Auto-refresh timer (every 15 minutes) for game data
- Foreground resume: reload if day changed or cache stale

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
- `BetPairing` for matching opposite sides and computing fair odds via sharp book vig-removal
- `EVCalculator` with per-book fee models (P2P, exchange, traditional)
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
- Home feed with game sections
- Game detail with collapsible sections, dev-mode clock
- MVVM architecture, SwiftUI views with dark mode
- Mock and real service implementations
