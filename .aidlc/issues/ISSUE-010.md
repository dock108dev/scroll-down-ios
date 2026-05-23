# ISSUE-010: Implement non-hijacking live refresh and jump-to-latest behavior

**Priority**: high
**Labels**: feature, live, scroll
**Dependencies**: ISSUE-004, ISSUE-007, ISSUE-009
**Status**: implemented

## Description

Replace full-replacement refresh side effects with an explicit live stream scroll contract. Discovery says `GameDetailViewModel.refresh` replaces `detail` every five minutes, always changes `updateToken`, and the view only scrolls when the old `pinToBottom` flag is enabled. Use `.aidlc/research/live-refresh-scroll-contract.md` and `.aidlc/research/follow-live-edge-state.md` for near-live-edge detection, pending counts, manual refresh behavior, visible-anchor preservation, and refresh failure/reset behavior. The live flow should let users read without surprise while making new content easy to find.

## Acceptance Criteria

- [ ] Silent auto-refresh preserves the reader's visible anchor when the user is reading older plays.
- [ ] Manual pull-to-refresh and toolbar refresh use the same no-jump contract and do not reset the stream.
- [ ] When follow live is enabled and the user is near the live edge, newly appended events keep the reader attached to the latest event.
- [ ] When the user scrolls away from live edge, new events increment a floating new-plays affordance instead of moving the screen.
- [ ] The new-plays affordance uses clear action copy such as `8 new plays` and `Jump to latest`, not internal refresh terminology.
- [ ] The floating new-plays affordance appears above the bottom area and does not cover important event text, controls, or scoreboard content.
- [ ] Jump to Latest scrolls to the newest event, clears pending count, and re-enables live-edge tracking.
- [ ] Users can stop following live/latest without unpinning the game.
- [ ] Refresh failures preserve the current detail payload, current scroll anchor, pending-new count, and progress state while surfacing an error non-destructively with an obvious retry path.
- [ ] Refresh classifications of inserted, prepended, modified, and reset from ISSUE-004 are handled without surprise teleporting; reset cases preserve the best available anchor or fall back deliberately.
- [ ] Refresh does not scroll to the page bottom below stats/scoreboard as a substitute for latest-play behavior.

## Implementation Notes


Attempt 1: Implemented live-edge scroll handling in GameDetailView, latest-play jump/clear behavior in GameDetailViewModel, floating new-plays affordance, non-destructive refresh error retry UI, and refresh preservation tests.