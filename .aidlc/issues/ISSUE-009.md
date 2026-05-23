# ISSUE-009: Persist and restore reading position by event id

**Priority**: high
**Labels**: feature, progress, detail
**Dependencies**: ISSUE-003, ISSUE-008
**Status**: implemented

## Description

Implement the core Scroll Down behavior: leave a game and return where the reader stopped. Discovery says there is no last-read event tracking, resume banner, scroll restoration, last viewed timestamp, expanded-section persistence, or start-over action. Use `.aidlc/research/game-progress-restore-by-event.md` to track visible event anchors and restore by `PlayEntry.id`/domain event id first, with pixel offset only as fallback. The resume flow should be user-controlled and reversible enough to avoid trapping readers.

## Acceptance Criteria

- [ ] While reading, the app persists the most relevant visible event id/index for the current game.
- [ ] Opening a game with progress and unreached scoreboard shows a resume banner with Resume, Jump to Latest, and Start Over actions when applicable.
- [ ] The resume banner explains the saved position and new-play count in user-facing terms, such as period/segment labels when available.
- [ ] Resume scrolls to the saved event when present and uses deterministic fallback when the event is missing or hidden by mode.
- [ ] Jump to Latest is presented as an explicit choice, not an automatic override of the reader's saved position.
- [ ] Last viewed timestamp updates when a game is opened/left and is available to home cards/new-play calculations.
- [ ] Expanded/collapsed section state needed for restore stability is persisted per game, including stats and raw-feed disclosures owned by other issues.
- [ ] Start Over clears last-read event, scroll fallback, and resume position without unpinning the game; scoreboard-reached state is preserved unless the implementation exposes an explicit reset for it.
- [ ] Start Over is not easy to trigger accidentally and has a clear recovery path through normal scrolling/resume state rebuilding.
- [ ] Progress restoration works after leaving detail and returning within the same app session and after app restart.

## Implementation Notes


Attempt 1: Added event-id reading progress restore in detail: geometry-based visible event persistence, user-controlled resume banner, latest/start-over actions, scoreboard reach tracking, expanded stats persistence, and restore fallback tests.