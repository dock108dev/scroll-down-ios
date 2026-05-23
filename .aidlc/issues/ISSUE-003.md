# ISSUE-003: Add injectable local game state store for pins and progress

**Priority**: high
**Labels**: infra, persistence, pinning, progress
**Dependencies**: ISSUE-002
**Status**: implemented

## Description

Implement the MVP persistence layer for first-class pinning and remembered game progress, and wire it into the app root. Discovery found no app-wide state object, `UserDefaults`, `@AppStorage`, SwiftData, last-read, selected-mode, reached-scoreboard, or persisted pin state. Use `.aidlc/research/local-pin-progress-store.md` as the shape: an injectable `GameStateStore` with a small Codable snapshot persisted locally, in-memory test implementation, and root dependency injection through `ScrollDownSportsApp`/`ContentView`/view models. The store must directly support the BRAINDUMP's new pinned-game/follow mode, not just generic persistence.

## Acceptance Criteria

- [ ] A local store persists pinned games by game id with enough metadata to render them after app restart, including games that are final or no longer prominent in the current home list.
- [ ] Pinned game records support pinned state, pinned timestamp, sport/league, last viewed timestamp, last read event identity/index, new event count, follow-live preference, and enough team/game metadata for home rendering.
- [ ] A per-game progress record persists selected mode, last viewed/read event id or index, last scroll fallback, expanded section ids, reached-scoreboard state, follow-live preference, last viewed timestamp, and updated timestamp.
- [ ] The store can distinguish `pinned game` from `following live edge` while allowing pinned live games to remember follow-live preference.
- [ ] The store is injectable into `HomeViewModel`, `GameDetailViewModel`, and any background refresh service, with an in-memory implementation for tests.
- [ ] `ScrollDownSportsApp` or `ContentView` owns the app-level store/dependency container instead of each screen creating unrelated state.
- [ ] Store reads are available synchronously or predictably early enough for SwiftUI initial render.
- [ ] Corrupt or missing persisted data falls back to an empty snapshot without crashing.

## Implementation Notes


Attempt 1: Added injectable Codable game state persistence under ScrollDownSports/Persistence, wired a single root store through app/content/home/detail/background refresh, mirrored pinned/progress state, and added store tests for persistence, corrupt fallback, and in-memory behavior.