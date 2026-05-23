# ISSUE-008: Replace P1/P2/P3 with persistent Key, Flow, Full modes

**Priority**: high
**Labels**: feature, stream, progress
**Dependencies**: ISSUE-003
**Status**: implemented

## Description

Convert the internal priority toggles into user-facing stream modes. Discovery says `PlayByPlaySection` exposes `P1`, `P2`, `P3`, recalculates expansion from play signatures, and does not persist selected state. Follow `.aidlc/research/priority-mode-redesign.md`: Key maps to highest-signal available band, Flow maps to P1+P2 with fallback, Full maps to all deduped plays. For usability, the mode control should communicate what each option does without exposing debug-tier language.

## Acceptance Criteria

- [ ] The UI shows Key, Flow, Full labels and never exposes P1/P2/P3 as primary product language.
- [ ] Mode counts reflect the actual visible event count for each mode, including fallback behavior when only lower bands exist.
- [ ] Key is the default first-open mode unless restored progress selects another mode.
- [ ] The selected mode persists per game and restores on reopen.
- [ ] Incoming refreshes do not reset the selected mode just because play counts or bands changed.
- [ ] Mode switching keeps the user oriented by preserving/restoring a nearby event anchor when possible instead of unexpectedly jumping to the top.
- [ ] Empty states explain the selected mode in user-facing language and avoid implying the game has no events when another mode has them.
- [ ] The mode control makes Full Play-by-Play discoverable for users who want every event while keeping Key/Flow understandable for first-time users.

## Implementation Notes


Attempt 1: Implemented persistent Key/Flow/Full stream behavior with shared fallback-aware counts, deduped visible events, user-facing row/empty copy, Full discoverability, and anchor-preserving mode switches.