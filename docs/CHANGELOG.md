# Changelog

Notable changes to the Scroll Down iOS app.

## [Unreleased]

### Changed — Score UX, Spoiler Actions, FairBet Progressive Loading, Dead Code Cleanup (Feb 21, 2025)

**Score display & reveal improvements:**
- Hold-to-reveal (long press on score area) shows scores without changing user preference
- Hold-to-update for live games fetches fresh scores with haptic feedback
- Score context display ("@ Q2 · 2m ago") in game header and home cards
- Persisted scores now restore correctly on game re-entry (decoupled from play-index validation)
- Home page cards show team-colored scores when "always show" mode is active

**Team colors on home page cards:**
- `GameRowView` now resolves team colors directly from `GameSummary` inline hex fields (light/dark), falling back to `TeamColorCache`
- Reordered `injectTeamMetadataFromSummaries()` to run before `applyHomeSectionResults()` so cache is populated before SwiftUI renders

**Spoiler-free actions (`.onMarkRead` mode):**
- "Catch up to live" button — bulk-reveals all scores (marks finals read + saves live scores)
- "Reset" button — undoes catch-up (marks all unread + clears saved reading positions/scores)
- iPad: icon buttons (eye/eye.slash) in filter bar alongside refresh
- iPhone: labeled pill buttons in dedicated action row above game list, refresh relocated there

**FairBet progressive loading:**
- First 500-bet page shown immediately; remaining pages load incrementally in background
- "Loading more bets…" indicator at bottom of list during background fetch
- New `isLoadingMore` published property on `OddsComparisonViewModel`

**FairExplainerSheet redesigned — "Show the Math":**
- Replaced opaque results display (This side: 50%, Other side: 50%, Vig removed: 4.8%, Best EV) with numbered step-by-step math walkthrough
- Step 1: Convert raw reference odds to implied probabilities (total > 100% shows the vig)
- Step 2: Identify the vig (total implied vs. 100%)
- Step 3: Remove the vig via normalization division to get fair probability and fair odds
- Step 4: Calculate EV at best book price with full dollar math (win/lose scenarios, EV formula)
- Median/consensus bets simplify to 2 steps (median probability + EV)
- Graceful fallbacks: missing opposite reference price, no EV data, minimal data
- Per-book implied probabilities moved into a DisclosureGroup ("All book probabilities")
- Replaced `impliedProbTotal` with clearer `rawImpliedThis`/`rawImpliedOther`/`rawImpliedTotal`/`vigPercent` computed helpers
- Each step uses consistent card styling with numbered circle badge

**Settings cleanup:**
- Removed "Read Status" section (Mark All Read/Unread buttons) — replaced by home page catch-up/reset
- Score Display preference (spoiler-free vs always show) remains

**Dead code removed (SSOT enforcement):**
- `ScoreRevealMode.resumed` enum case (not selectable from Settings, only referenced by deleted switch arm)
- `GameHeaderView.hasReadingPosition` property (only consumer was `.resumed`)
- `GameHeaderView.metadataText` computed property (never referenced in view body)
- `GameRowView.hasFullFlow` property and `Layout` enum (unused)

**Files changed:** `FairExplainerSheet.swift`, `GameRowView.swift`, `GameHeaderView.swift`, `GameDetailView.swift`, `GameDetailView+Helpers.swift`, `GameDetailView+Timeline.swift`, `HomeView.swift`, `HomeView+DataLoading.swift`, `HomeView+Sections.swift`, `SettingsView.swift`, `OddsComparisonViewModel.swift`, `OddsComparisonView.swift`, `GameDetailViewModel.swift`, `ReadingPositionStore.swift`, `Enums.swift`

### Added — Live Data Support, Read State Gating & Reading Position (Feb 2025)

**GameStatus enum alignment:**
- Added `pregame`, `live`, `archived` cases to `GameStatus`
- Added computed properties: `isLive` (`.live`, `.inProgress`), `isFinal` (`.final`, `.completed`, `.archived`), `isPregame` (`.pregame`, `.scheduled`)
- Removed `isCompleted` — `isFinal` is the SSOT for "game is over"
- Backward compat: `"in_progress"` still decodes to `.inProgress`

**Read state gating:**
- `ReadStateStore.markRead(gameId:status:)` now requires `GameStatus` — silently ignores non-final games
- Removed nil default on status parameter

**Score reveal preference:**
- `ScoreRevealMode` enum: `.always`, `.onMarkRead` (default) — `.resumed` later removed as dead code
- Stored in `ReadStateStore.scoreRevealMode` (UserDefaults-backed)
- Live games support hold-to-update for fresh scores

**Live game experience:**
- `GameDetailViewModel` auto-polls every ~45s for live games (`startLivePolling`/`stopLivePolling`)
- Timeline section shows PBP for live games, Game Flow for final
- Auto-detects live-to-final transition: stops polling, switches content
- Header shows pulsing red LIVE badge with live score (via `PulsingDotModifier`)
- `load()` supports refresh (`isRefresh` parameter) for live data updates

**Reading position tracking (local-only):**
- New `ReadingPosition` model: playIndex, period, gameClock, periodLabel, timeLabel, savedAt
- New `ReadingPositionStore` service (UserDefaults-backed, keyed by game ID)
- Resume text ("Stopped at Q3 4:32") in game header and home card
- Resume prompt on re-open with saved position

**New files:**
- `Sources/Models/ReadingPosition.swift`
- `Sources/Services/ReadingPositionStore.swift`

**Legacy code removed (SSOT enforcement):**
- Removed `isCompleted` computed property (replaced by `isFinal`)
- Removed `isOutcomeRevealed` (dead code, hardcoded false)
- Removed legacy raw UserDefaults resume marker (`resumeMarkerKey`)
- Updated all callers: `MockDataGenerator`, `HomeView+Sections`, `HomeViewSupport`, `GameRowView`
- Added 7 new enum tests: `isFinal`, `isLive`, `isPregame`, decoding for live/pregame/archived

**Game.swift:** Added `lastOddsAt: String?` field

### Changed — Odds Presentation & BetCard Redesign (Feb 20, 2025)

**Game detail odds table overhauled** (`GameDetailView+Odds.swift`):
- Mainline markets grouped into collapsible Moneyline / Spread / Total sections
- Team props grouped by team name with collapsible headers
- Player props grouped by player name with stat type sub-headers, using shared `oddsTableRows` renderer
- Spreads sorted by absolute line; totals sorted by line with over before under
- Alternates rendered as a sorted flat table
- Fixed frozen/scrollable column alignment on player prop tables (matching "MARKET" header row)
- Added `collapsedOddsGroups: Set<String>` state for per-group collapse

**BetCard redesigned** — action-first layout (`BetCard.swift`):
- iPhone: vertical decision stack — primary book (prominent) → best-available callout → fair estimate card → expandable other books
- iPad: horizontal book scroll → fair estimate card below
- FAIR displayed as tappable outlined card ("Est. fair +125" + info icon) — visually distinct from sportsbooks
- Removed confidence dots and Pinnacle reference price from main card
- New `FairExplainerSheet` extracted from BetCard (later redesigned into step-by-step math walkthrough — see Unreleased)
- New `BookAbbreviationButton` — tap to toggle abbreviated/full sportsbook name
- Removed "Fair price"/"Good price"/"Great price" value indicator text

**MarketType.displayName** added (`Enums.swift`):
- Human-readable stat type names for all market types (Points, Rebounds, Assists, etc.)
- Used in player prop display labels and grouped rendering

**Period/quarter title handling** (`GameDetailView+Helpers.swift`, `FullPlayByPlayView.swift`):
- Server-provided `periodLabel` expanded for readability (P1→Period 1, H1→1st Half, etc.)
- Sport-aware fallbacks for NBA (Q1–Q4), NCAAB (1st Half/2nd Half), NHL (Period 1–3)
- Shared logic between game detail and full play-by-play views

**Wrap-up timing** (`GameDetailViewModel.swift`, `GameDetailView.swift`):
- `isGameTrulyCompleted` requires status == completed/final AND confirmation signals (derived metric outcomes or 3+ hours elapsed)
- Prevents wrap-up section from appearing on in-progress games marked completed prematurely

### Changed — API Alignment & Legacy Cleanup (Feb 18, 2025)

**FairBet server-side EV integration:**
- `APIBet` now consumes server-side EV annotations: `trueProb`, `referencePrice`, `evConfidenceTier`, `evDisabledReason`
- `BookPrice` now consumes `evPercent`, `trueProb`, `isSharp`, `evMethod`, `evConfidenceTier`
- `BetsResponse` expanded with `gamesAvailable`, `marketCategoriesAvailable`, `evDiagnostics`
- New structs: `GameDropdown`, `EVDiagnostics`
- `OddsComparisonViewModel` prefers server-side EV over client-side computation
- `BetCard` shows confidence dots (green/yellow/orange), Pinnacle reference price, disabled reason text, sharp book indicators
- `BetCard` enriched for player props (shows player name + stat type), team props, and alternates

**Game detail odds section (new):**
- `GameDetailView+Odds.swift` — cross-book odds comparison table with category tabs
- `GameSection.odds` case added between `.teamStats` and `.final`
- `OddsEntry` expanded with `marketCategory`, `playerName`, `description` fields
- `MarketCategory` enum for grouping odds in the game detail view
- `GameDetailViewModel` odds computed properties: `hasOddsData`, `availableOddsCategories`, `oddsMarkets(for:)`, `oddsPrice(for:book:)`

**FairBetAPIClient expanded:**
- `fetchOdds()` now accepts `marketCategory`, `gameId`, `minEV`, `sortBy`, `playerName`, `book`, `hasFair` params

**Home view:**
- FairBet tab renamed from "Current Odds" to "FairBet"
- Added one-line explainer above FairBet filter bar

**Legacy code eliminated:**
- Deleted `fetchUnifiedTimeline` from `GameService` protocol and all implementations (dead code — never called)
- Deleted `RealGameService.requestRaw` (only caller was `fetchUnifiedTimeline`)
- Deleted `MockGameService.findAndCacheGame` (dead private method)
- Deleted `ViewModelConstants.defaultTimelineGameId` (hardcoded ESPN game ID fallback)
- Deleted `GameDetailViewModel.timelineGameId` wrapper method
- `UnifiedTimelineEvent.init` collapsed from ~12 dual-key fallbacks to canonical snake_case keys only
- `PbpEvent` decoder simplified — removed alias CodingKeys (`clock`/`index`/`playType`), removed silent `id = .int(0)` fallback
- `PbpResponse` simplified — removed dual-format parsing (periods vs flat), now expects flat events array only
- `MarketType` aliases removed: `"spreads"`, `"h2h"`, `"totals"` no longer resolve to known cases
- `PlayType` alias removed: `"three_pointer"` no longer resolves (canonical is `"3pt"`)
- 3 alias tests deleted from `EnumsTests`

### Changed — iPhone BetCard Redesign & Market Expansion (Feb 15, 2025)

**BetCard iPhone layout overhauled** — replaced cramped flow grid with a vertical decision stack:
- Row B: Fair odds chip + Parlay button
- Row C: Anchor book row (user's preferred sportsbook, or best available)
- Row D: "Best available" disclosure (hidden when anchor = best)
- Row E: Collapsible "Other books" with MiniBookChip flow layout
- iPad layout unchanged (horizontal scroll)
- Extracted `BookNameHelper` enum for consistent sportsbook abbreviations (DraftKings→DK, etc.)
- Tightened card spacing on iPhone (6pt vs 8pt, 10pt vs 12pt padding)

**Settings:**
- "Best available price" added as first option in Default Book picker
- Default sportsbook changed from DraftKings to best-available for new installs

**MarketKey expanded** (7 new cases):
- NHL: `playerGoals`, `playerShotsOnGoal`, `playerTotalSaves`
- Cross-sport: `playerPRA` (points + rebounds + assists)
- Alternate lines: `alternateSpreads`, `alternateTotals`
- Game-level: `teamTotals`

**MarketType expanded** — converted from plain `String` enum to `RawRepresentable` with `unknown(String)` fallback:
- Added 14 new cases mirroring MarketKey (alternateSpread, alternateTotal, player props, etc.)
- Unknown API values decode as `.unknown(String)` instead of crashing

**FairBetCopy:** Added display labels for all new market types (Blocks, Steals, Player Goals, Shots on Goal, Goalie Saves, PRA, Team Total, Alt Spread, Alt Total)

**GameRowView simplified** — collapsed 4 card states (available/pregame/comingSoon/upcoming) into 2:
- `.active` — has any data (odds, PBP, social, or required data); tappable
- `.noData` — truly empty; greyed, non-tappable

**OddsComparisonViewModel:** EV computation hardened — now requires a real `trueProb` from server; no longer falls back to a meaningless 0.5 probability

**FairBetAPIClient:** Now sends `has_fair=true` query parameter to filter for bets with fair odds server-side

**MiniBoxScoreView:** Delta stats hidden on first flow block (no prior block to delta against)

**Tests:** Added 7 MarketKey tests to EnumsTests (init, decoding, unknown fallback, round-trip)

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
