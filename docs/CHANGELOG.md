# Changelog

All notable changes to this project are documented here.

## [Unreleased]

### Added
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

### Changed
- Documentation consolidated under `/docs` with a lean root README
- GameDetailView split into focused files to keep views under 500 LOC
- Mock data generator extracted for cleaner networking layout
- Timeline play-by-play now surfaces scores via separators (halftime, period end)

### Fixed
- Navigation tap reliability improved (List → ScrollView+LazyVStack)
- Mock service now generates unique game detail for each game ID
- Timeline quarter expansion no longer jumps ahead in the feed
- Game detail routing now rejects mismatched backend IDs to prevent wrong-game opens
