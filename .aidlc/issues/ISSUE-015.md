# ISSUE-015: Add product invariant test coverage for scroll-down behavior

**Priority**: medium
**Labels**: tests, invariants
**Dependencies**: ISSUE-003, ISSUE-004, ISSUE-006, ISSUE-008, ISSUE-009, ISSUE-010, ISSUE-013, ISSUE-016, ISSUE-017, ISSUE-018
**Status**: implemented

## Description

Add tests for the product rules so the redesign does not regress. Discovery says tests only cover decoding and game window logic. Use `.aidlc/research/product-invariant-test-coverage.md` plus backend/renderer/background refresh research and the BRAINDUMP manual scenarios to add unit/view-model/presentation tests before relying on manual screenshots or UI tests. This functionality facet adds coverage for edge cases that can break the end-to-end product behavior.

## Acceptance Criteria

- [ ] Tests assert home/detail presentation does not expose scores in top/header regions by default.
- [ ] Tests assert bottom scoreboard/result is reachable as the scroll-down payoff and `reachedScoreboard` is persisted only after real viewport visibility.
- [ ] Store tests cover pin persistence, unpin persistence, no duplicate pins, progress persistence, selected-mode persistence, expanded-section persistence, last-viewed timestamps, and reached-scoreboard persistence.
- [ ] View-model or presentation tests cover resume restore by event id, fallback behavior when the saved event is missing, and behavior when the saved event is hidden by selected mode.
- [ ] Live update tests cover appended events while scrolled up, pending new-play counts, follow-live behavior, manual refresh no-jump behavior, refresh failure preservation, reset classification, and no reset to the first play.
- [ ] Home functionality tests cover pinned games outside the fetched window, fetch failure with persisted snapshot, final games without play-by-play, scheduled games with no new-play badge, and home reacting to detail-side pin/progress changes.
- [ ] Presentation-field tests cover backend-first display and legacy fallback for games, events, eligibility, importance, and scoreboard data.
- [ ] Renderer tests cover generic fallback plus MLB/NHL stat or label routing without core screen branching.
- [ ] Background refresh tests cover home snapshot hydration, pinned-detail update, cursor advancement, unseen count clearing, failure preservation, and cursor regression.
- [ ] Existing decoding and game-window tests continue to pass.

## Implementation Notes


Attempt 1: Added product invariant unit coverage for score placement, scoreboard reach persistence, store persistence, restore fallback, live refresh no-jump behavior, home fallbacks, and renderer routing. Regenerated the Xcode project so new tests are included.