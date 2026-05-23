# ISSUE-006: Create state-aware home game cards

**Priority**: high
**Labels**: feature, home, visual
**Dependencies**: ISSUE-001, ISSUE-005, ISSUE-017
**Status**: implemented

## Description

Replace samey `GameRowView` cards with sport-native cards that answer status, catch-up, resume, new plays, pin, score-at-bottom, and backend presentation questions. Discovery says home cards currently show league/time/live/team/footnote only, with no pin/resume/new-play state and too-similar green-accented cards. Use `.aidlc/research/home-card-state-contract.md`, `.aidlc/research/backend-presentation-contract.md`, and ISSUE-001 tokens to create visually distinct scheduled/live/final/pinned/resume/viewed cards while preserving score-at-bottom hierarchy.

## Acceptance Criteria

- [ ] Scheduled, live, final not-started, final partially-read, pinned live, and viewed/open-recap states have distinct card copy and visual treatment.
- [ ] Each card has one clear primary action label that matches state, such as `Open stream`, `Catch up`, `Resume`, `Open recap`, or a scheduled-state equivalent.
- [ ] Cards use a consistent hierarchy for league/sport metadata, status, team names, progress/new-play context, pin state, and score-at-bottom cue.
- [ ] Final or catch-up cards that have not reached the scoreboard show a clear `Score at bottom` cue and do not reveal final score at the top by default.
- [ ] Live games have stronger live treatment than a tiny badge alone, but do not rely on generic green rails.
- [ ] Pinned cards use a coherent pinned badge/icon treatment shared with the detail header and stream controls.
- [ ] Team color appears as a restrained accent such as a rail, chip, or marker, not a full-card wash.
- [ ] Cards only say `Catch up`, `Resume`, or `Open stream` when eligibility exists through backend eligibility fields or reliable fallback heuristics such as `hasPbp == true` or `playCount > 0`.
- [ ] Final games without play-by-play do not show a misleading catch-up/resume action; they degrade to an appropriate final/box-score state.
- [ ] Scheduled/pregame cards do not show new-play counts or resume states unless persisted progress genuinely exists from prior available content.
- [ ] Every game card state that can be opened can also be pinned or unpinned from home without conflicting with navigation.
- [ ] Pin/unpin on a card does not accidentally open the game, and opening the card does not accidentally toggle pin state.
- [ ] Pinned cards show obvious active pin state, pinned badge treatment, and an unpin affordance.
- [ ] Resume and new-play labels are driven from local progress/diff state and use human-readable context such as period/segment when available.
- [ ] Backend presentation and eligibility fields drive labels/actions when present, with current `GameSummary` fields as fallback.

## Implementation Notes


Attempt 1: Added testable home card state derivation and new SwiftUI card rendering with distinct scheduled/live/final/pinned/resume/recap/box-score treatments, score-at-bottom cueing, gated action labels, and a separate visible pin control.