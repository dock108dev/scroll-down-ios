# Changelog

Notable changes to the Scroll Down iOS app.

## [Unreleased]

### Removed - Code Cleanup (Jan 2025)
- Deleted `RelatedPost` model and `RelatedPostCardView`
- Removed `fetchRelatedPosts` from GameService protocol
- Removed `GameDetailView+Social.swift` (unused view)
- Deleted `related-posts.json` mock file
- Removed legacy `.social` case from `GameSection` enum
- Cleaned up legacy comments and fallback documentation

### Added - NHL Support
- `NHLSkaterStat` and `NHLGoalieStat` models
- Dedicated NHL stats tables (Skaters/Goalies)
- Sport-aware period labels (Period 1/2/3 vs Q1/Q2/Q3/Q4)

### Added - Game Story View
- `GameStoryView` for completed games with story data
- `StorySectionBlockView` with matched social posts
- `SocialPostMatcher` for section-aware tweet placement
- `FullPlayByPlayView` with period grouping

### Removed - Legacy Code Cleanup (Jan 2025)
- Deleted `CompactMoment` model
- Removed `legacyTimelineView` fallback
- Timeline now uses `SectionEntry` + `UnifiedTimelineEvent`

## Phase G - Timeline API Integration
- Timeline artifact fetch from `/games/{game_id}/timeline`

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
- Feature flag for game preview scores

## Phase A - Foundation
- Basic MVVM architecture
- SwiftUI views with dark mode
- Mock and real service implementations
