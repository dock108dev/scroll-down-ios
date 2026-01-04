# Changelog

## [Unreleased]

### Added
- Spoiler-safe game list with progressive disclosure and status context
- Home feed with Earlier/Today/Upcoming sections and scroll-to-today behavior
- Game detail view with collapsible sections (Overview, Timeline, Stats, etc.)
- Compact timeline view for chapter-style moments without scores
- Compact moment expanded view with play-by-play slice in compact mode
- Dev-mode clock for consistent mock data generation (fixed to Nov 12, 2024)
- Reusable `CollapsibleCards` component extracted to Components/
- Related posts section with tap-to-reveal blur for score-containing posts
- Game preview networking service for API previews
- Feature flag for game preview scores (defaulted on in debug builds)

### Changed
- Documentation consolidated under `/docs` with a lean root README
- GameDetailView split into focused files to keep views under 500 LOC
- Mock data generator extracted for cleaner networking layout
- Timeline play-by-play now surfaces scores via separators (live, halftime, period end)

### Fixed
- Navigation tap reliability improved (List → ScrollView+LazyVStack)
- Mock service now generates unique game detail for each game ID
- Timeline quarter expansion no longer jumps ahead in the feed
