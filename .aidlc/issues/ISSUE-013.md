# ISSUE-013: Redesign bottom scoreboard card and reached-scoreboard state

**Priority**: medium
**Labels**: feature, scoreboard, progress
**Dependencies**: ISSUE-001, ISSUE-003, ISSUE-002, ISSUE-016, ISSUE-017
**Status**: implemented

## Description

Turn the bottom score area into the payoff while preserving the no-top-score invariant and the BRAINDUMP's layout-based spoiler model. Discovery says `BoxScoreSection` is bottom-positioned but plain, uses transient reveal state, lacks sport-specific grids, and does not persist reached-scoreboard. Use `.aidlc/research/scoreboard-grid-data-availability.md`, `.aidlc/research/scoreboard-reached-detection.md`, `.aidlc/research/backend-presentation-contract.md`, `.aidlc/research/sport-renderer-boundaries.md`, and ISSUE-001 tokens to deliver the explicitly requested sport-specific Scoreboard Card.

## Acceptance Criteria

- [ ] Scoreboard remains structurally near the bottom after the stream and supporting stats, never in the top header by default.
- [ ] The bottom scoreboard/result is the default payoff when the user intentionally reaches the bottom; the current confirmation-dialog reveal gate is removed or reduced so it does not block the core scroll-down result experience.
- [ ] The scoreboard card supports backend-provided layout variants such as simple totals, period table, segment table, soccer score/goals summary, and leaderboard-style results when those contracts are present.
- [ ] MLB uses an inning/line-score grid when structured segment data exists and falls back to a compact totals/R-H-E-style or total-score view only when segment data is unavailable.
- [ ] Football, basketball, NHL, and similar team sports can render quarter/period segment tables when backend scoreboard segments are present.
- [ ] Golf can render a leaderboard-style result instead of forcing a two-team scoreboard when backend layout indicates it.
- [ ] The scoreboard card uses a stronger final/current state visual treatment than ordinary stream cards.
- [ ] Score rows, totals, segment labels, and status text have a compact scoreboard/table hierarchy rather than two generic large score rows only.
- [ ] Team colors are used as restrained row accents or abbreviation chips, not oversized backgrounds.
- [ ] Backend `scoreboard` presentation is used when present, including segments/totals/layout; current score fields are fallback only.
- [ ] If structured line-score data is absent, the UI uses a clear fallback rather than inventing inning/quarter grids from unreliable fields.
- [ ] Viewport-based detection persists `reachedScoreboard` only after a meaningful visible threshold, not from `LazyVStack` preloading or a one-pixel `onAppear` event.
- [ ] The reached-scoreboard flag is monotonic for a game once set and is not cleared by scrolling away, refresh, app restart, or score payload corrections.
- [ ] Future home cards may use `reachedScoreboard` for viewed/open-recap state, while top headers still avoid score exposure by default unless the product explicitly allows viewed-game score display.
- [ ] Sport-specific scoreboard layout decisions are delegated through renderer/adapters.

## Implementation Notes


Attempt 1: Redesigned bottom scoreboard presentation with renderer-owned simple, segment, soccer, MLB line-score, and golf leaderboard layouts; removed blocking reveal dialog; tightened reached-scoreboard viewport persistence and monotonic store behavior; added coverage.