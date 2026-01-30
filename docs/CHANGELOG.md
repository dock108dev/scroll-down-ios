# Changelog

Notable changes to the Scroll Down iOS app.

## [Unreleased]

### Added - Interaction Polish (Jan 2025)
- Unified `InteractiveRowButtonStyle` for consistent tap feedback
- `SubtleInteractiveButtonStyle` for less prominent elements
- Standardized chevron behavior (chevron.right, 0°→90° rotation)
- Standardized spring animations across all collapsible sections
- Tab bar scroll-to-section with re-tap support
- Clickable team headers in game detail (navigates to team page)
- `TeamView` for team page display
- Styled play descriptions with visual hierarchy (emphasized actions, de-emphasized metadata)

### Added - Timeline Improvements
- Global expand/collapse for timeline boundaries via header tap
- Full row tap targets on boundary headers
- `contentShape(Rectangle())` for reliable touch handling

### Removed - Code Cleanup (Jan 2025)
- Deleted `RelatedPost` model and `RelatedPostCardView`
- Removed `fetchRelatedPosts` from GameService protocol
- Removed `GameDetailView+Social.swift` (unused)
- Deleted `related-posts.json` mock file
- Removed legacy `.social` case from `GameSection` enum
- Deleted `StorySectionBlockView` (replaced by MomentCardView)
- Deleted `SocialPostMatcher` (social posts now displayed separately)
- Deleted `SectionEntry` and `ChapterEntry` models (replaced by moments-based structure)

### Added - NHL Support
- `NHLSkaterStat` and `NHLGoalieStat` models
- Dedicated NHL stats tables (Skaters/Goalies)
- Sport-aware period labels (Period 1/2/3 vs Q1/Q2/Q3/Q4)

### Added - Moments-Based Story System
- `GameStoryView` for completed games with story data
- `MomentCardView` with expandable play lists
- `StoryAdapter` for converting API response to display models
- `BeatType` enum for narrative moment classification
- `FullPlayByPlayView` with period grouping

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
- Feature flag for game preview scores

## Phase A - Foundation
- Basic MVVM architecture
- SwiftUI views with dark mode
- Mock and real service implementations
