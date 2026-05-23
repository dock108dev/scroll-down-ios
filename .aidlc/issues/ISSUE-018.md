# ISSUE-018: Make background refresh update persisted home and pinned-game state

**Priority**: high
**Labels**: infra, background-refresh, pinning, live
**Dependencies**: ISSUE-003, ISSUE-004
**Status**: implemented

## Description

Convert background refresh from a discarded games fetch into product-state maintenance for pinned games and new-play indicators. Discovery says `BackgroundDataScheduler.handle(task:)` fetches games and ignores the result. Use `.aidlc/research/background-refresh-product-role.md`: persist a home snapshot, refresh pinned game details within a small cap, update play cursors/new-play counts, record failures without wiping prior state, and hydrate foreground view models from persisted state.

## Acceptance Criteria

- [ ] `BackgroundDataScheduler` delegates to a background refresh service instead of directly discarding `fetchGames()` results.
- [ ] Background refresh persists a current home snapshot with a stable game-window key.
- [ ] Pinned game details are refreshed and merged into durable pinned-game state with latest cursor and unseen-play count.
- [ ] Opening or viewing a game clears the relevant unseen count without unpinning the game.
- [ ] Failures, stale cursor regressions, no pinned games, too many pinned games, and unpinned in-flight games are handled without corrupting stored state.
- [ ] Home and detail view models can hydrate from persisted background state before or alongside foreground refresh.

## Implementation Notes


Attempt 1: Background refresh now delegates to a service that persists home snapshots, refreshes capped pinned details, tracks play cursors/unseen counts, records failures, and hydrates home/detail view models from persisted state.