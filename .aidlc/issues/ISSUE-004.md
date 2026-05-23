# ISSUE-004: Implement event identity baselines and new-play diffing

**Priority**: high
**Labels**: infra, live, progress
**Dependencies**: ISSUE-003
**Status**: implemented

## Description

Add the event-diffing foundation used by pinned cards, resume banners, and live update controls. Discovery says `playCount` is decoded but unused and detail refreshes replace the entire response without comparing plays. Follow `.aidlc/research/new-event-diffing.md`: use `eventId` first, `playIndex` second, and summary `playCount` only as a cheap list-level signal. This issue must also handle provider corrections and reset cases without producing false new-play counts.

## Acceptance Criteria

- [ ] A stable diff key exists for events that does not depend on description, clock text, period display labels, or score text.
- [ ] Home/pinned summaries can compute positive new-play deltas from previous and current `playCount` without emitting badges for nil, pregame, disappeared, or decreased counts.
- [ ] Detail refresh can classify unchanged, appended, prepended, inserted, modified, or reset play lists well enough for scroll behavior decisions.
- [ ] Provider corrections that modify text, clock, score, or ordering do not duplicate events or inflate new-play counts when event identity is stable.
- [ ] A reset or incompatible reordering clears/repairs baselines conservatively rather than showing misleading new-play counts.
- [ ] Opening a game clears or advances the relevant unseen baseline for that game without losing pin state.
- [ ] Mode changes do not by themselves change the underlying new-event baseline.
- [ ] Unit tests cover eventId-based identity, playIndex fallback, count increase, count decrease, missing-count cases, provider text correction, and reset classification.

## Implementation Notes


Attempt 1: Added stable GameEvent diff keys/classification, persisted event baselines, pinned play-count delta handling, detail refresh diff recording, and unit coverage in DomainModels, GameStateStore implementations, GameDetailViewModel, and GameStateStoreTests.