# ISSUE-007: Add detail header card and stream control bar

**Priority**: high
**Labels**: feature, detail, pinning
**Dependencies**: ISSUE-001, ISSUE-003
**Status**: implemented

## Description

Recompose the game detail top area into game setup plus controls, without top score exposure. Discovery says `GameHeaderView` lacks score-at-bottom text, pin state, catch-up metadata, resume state, and selected stream mode; the current toolbar pin is a transient pin-to-bottom behavior. Use BRAINDUMP section 10 plus `.aidlc/research/pin-to-bottom-conflict.md` to separate persistent game pinning from live-edge following. This issue delivers the explicitly requested Stream Control Bar surface.

## Acceptance Criteria

- [ ] Detail top header shows league/sport, teams, date/status, catch-up metadata, play count when available, pin state, and `Score at bottom` without rendering scores by default.
- [ ] A stream control bar exists near the top and supports the explicitly requested controls: pin/unpin, selected Key/Flow/Full mode, follow live on/off when live, resume, jump latest, and new-play count.
- [ ] The stream control bar can represent both catch-up mode and stream mode without adding a second competing control surface.
- [ ] The persistent game pin control is labeled/accessibility-labeled as `Pin game` or `Unpin game`, not as a scroll behavior.
- [ ] Follow-live/latest controls are labeled separately from game pinning, such as `Follow live`, `Stop following`, or `Jump to latest`.
- [ ] Controls that are not applicable to the current state are hidden or disabled with understandable copy, such as no follow-live toggle for a completed non-updating game.
- [ ] The old `Pinned` bottom overlay and forced page-bottom semantics are removed or renamed into live/latest behavior only.
- [ ] Toolbar/nav controls remain accessible and do not duplicate the stream control bar state incoherently.
- [ ] The user can return to the home list with normal back navigation without losing pin/progress state or being forced to the scoreboard.

## Implementation Notes


Attempt 1: Added detail header metadata, top stream control bar, Key/Flow/Full mode filtering, separate pin vs follow-live state, latest/resume controls, and view-model tests.