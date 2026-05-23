# ISSUE-005: Rebuild home information architecture around Pinned, Today, Earlier

**Priority**: high
**Labels**: feature, home, pinning
**Dependencies**: ISSUE-003, ISSUE-004
**Status**: implemented

## Description

Replace the flat date timeline as the top-level home structure with the BRAINDUMP hierarchy. Discovery says `HomeViewModel.filteredTimelineSections` emits date sections from a -7/+7 window and `HomeView` renders every date equally. Use `.aidlc/research/home-section-information-architecture.md` to keep Eastern-time grouping and filtering but expose semantic sections: Pinned first, Today second, Earlier grouped by date. For usability, the hierarchy should make the next useful action obvious on first open and avoid dead ends for empty, filtered, or stale states.

## Acceptance Criteria

- [ ] Pinned section appears first when there are pinned games and is omitted when empty.
- [ ] Today appears as the primary current-slate section, preserving the existing today empty state.
- [ ] Earlier contains previous games grouped by date where useful, rather than making every date a top-level peer.
- [ ] League and team filters apply consistently across Pinned, Today, and Earlier.
- [ ] Pinned games remain easy to find even when they are outside the current date section ordering.
- [ ] Home observes store changes from detail and background refresh so pin/unpin, resume state, reached-scoreboard state, and new-play counts update when returning to home without app restart.
- [ ] If a pinned game is no longer in the current fetched game window, home renders it from persisted pinned metadata instead of dropping it silently.
- [ ] If foreground fetch fails but a persisted home snapshot or pinned metadata exists, home can still render the last known games with state rather than an empty-only failure path.
- [ ] Empty Today, no pinned games, no filter matches, and fetch failure states each provide an obvious next step such as clear filter, retry, or browse available games.
- [ ] First open does not require the user to understand the date window; the page starts at or returns to the Today/Pinned context instead of a far-past section.

## Implementation Notes


Attempt 1: Rebuilt home around semantic Pinned, Today, and Earlier sections in HomeViewModel/HomeView; added persisted pinned metadata rendering, store-observed row state, detail pin toggle, home-only fetch window, and focused unit tests.