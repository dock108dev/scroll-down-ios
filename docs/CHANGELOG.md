# Changelog

All notable changes to this project are documented here.

## [Unreleased]

### Added - Phase C (Timeline Usability)
- Period/quarter grouping for PBP events with collapsible sections
- Pagination for long PBP sequences (20 events per chunk, per period)
- Moment summaries inserted between event clusters as narrative bridges
- LIVE indicator for current period in timeline
- Context-aware empty states for partial/delayed PBP
- Reveal-aware rendering philosophy documented in models

### Changed - Phase C
- CompactMomentExpandedView now uses period-grouped timeline instead of flat list
- PBP events render in collapsible period sections with expansion state
- Timeline shows game clock only (period shown in section header)
- Moment summaries use neutral, observational language (no outcome spoilers)
- Empty PBP states provide helpful context about data availability

### Added - Phase B (Real Feeds)
- Home feed with Earlier/Today/Upcoming sections and scroll-to-today behavior
- Game list with progressive disclosure and contextual status display
- Game detail view with collapsible sections (Overview, Timeline, Stats, etc.)
- Compact timeline view for chapter-style game moments
- Compact moment expanded view with play-by-play slice
- Dev-mode clock for consistent mock data generation (fixed to Nov 12, 2024)
- Reusable `CollapsibleCards` component extracted to Components/
- Related posts section with tap-to-reveal blur for posts containing outcomes
- Game preview networking service for API integration
- Feature flag for game preview scores (enabled in debug builds)
- Routing diagnostics via structured logs (tap, navigate, detail load, ID mismatch)
- Home feed snapshot wiring for Earlier/Today/Coming Up ranges with backend-driven ordering
- Data freshness label on the home feed sourced from backend `last_updated_at`

### Changed - Phase B
- Documentation consolidated under `/docs` with a lean root README
- GameDetailView split into focused files to keep views under 500 LOC
- Mock data generator extracted for cleaner networking layout
- Timeline play-by-play now surfaces scores via separators (halftime, period end)
- Environment configuration now uses `AppConfig.environment` to keep mock/live sources in sync

### Fixed - Phase A & B
- Navigation tap reliability improved (List → ScrollView+LazyVStack)
- Mock service now generates unique game detail for each game ID
- Timeline quarter expansion no longer jumps ahead in the feed
- Game detail routing now rejects mismatched backend IDs to prevent wrong-game opens