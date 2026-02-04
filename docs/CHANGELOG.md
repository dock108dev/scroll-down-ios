# Changelog

Notable changes to the Scroll Down iOS app.

## [Unreleased]

### Changed - Blocks-Based Story System (Feb 2025)
Migrated from moments-based to blocks-based story architecture:

**Models:**
- `StoryBlock` replaces `StoryMoment` as primary narrative unit
- `BlockDisplayModel` replaces `MomentDisplayModel`
- `BlockMiniBox` with `blockStars` replaces `MomentBoxScore`
- `BlockPlayerStat` includes delta stats (cumulative + per-block changes)
- Server-provided `BlockRole` replaces client-derived `BeatType`

**Views:**
- `StoryContainerView` renders block list with spine
- `StoryBlockCardView` shows narrative + mini box score at bottom
- `MiniBoxScoreView` displays top 2 players per team with blockStar highlighting

**Removed:**
- `StoryMoment`, `MomentDisplayModel`, `BeatType` models
- `MomentCardView`, `NarrativeBlockView`, `NarrativeContainerView` views
- `MockGameService+StoryGeneration.swift` (stories from API only)
- `GameDetailViewModel+StoryDerivation.swift`
- Legacy moments fallback paths

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
- Deleted `StorySectionBlockView` (replaced by blocks-based views)
- Deleted `SocialPostMatcher` (social posts now displayed separately)
- Deleted `SectionEntry` and `ChapterEntry` models (replaced by blocks-based structure)

### Added - NHL Support
- `NHLSkaterStat` and `NHLGoalieStat` models
- Dedicated NHL stats tables (Skaters/Goalies)
- Sport-aware period labels (Period 1/2/3 vs Q1/Q2/Q3/Q4)

### Added - Story System (Superseded by Blocks in Feb 2025)
- `GameStoryView` for completed games with story data
- `StoryAdapter` for converting API response to display models
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
