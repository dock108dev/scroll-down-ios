# ISSUE-002: Separate API DTOs from sport-neutral domain models

**Priority**: high
**Labels**: infra, architecture, all-sports
**Dependencies**: none
**Status**: implemented

## Description

Introduce a domain layer so core UI can speak in games/events/moments/progress instead of raw SDA DTOs. Discovery says `GameSummary`, `Game`, and `PlayEntry` currently act as both wire contracts and UI models, with MLB/NHL fields leaking into shared code. Follow `.aidlc/research/core-model-neutralization.md` and preserve endpoint paths, JSON fields, and existing decoding tests while adding the explicit BRAINDUMP domain features: sport-neutral `Game`, `GameEvent`, `GameProgress`, `ScoreState`, `ScoreDelta`, participants, status, mode eligibility, and mapper types.

## Acceptance Criteria

- [ ] Existing SDA response contracts remain backward compatible and decoding tests still pass.
- [ ] Wire DTO names and domain model names are separated clearly enough that views can migrate off raw DTOs.
- [ ] A sport-neutral `Sport` representation supports at least `mlb`, `nfl`, `nba`, `nhl`, `soccer`, `golf`, `tennis`, and `other` or equivalent unknown-safe cases.
- [ ] Domain models use sport-neutral language: game, event, moment, period, clock, score state, timeline, stream, stats, scoreboard, pin, progress.
- [ ] Domain `Game` supports participants rather than assuming only home/away teams, while still mapping current two-team payloads correctly.
- [ ] Domain `GameEvent` supports sequence, period label, clock label, team ownership, event type, importance, mode eligibility, headline/detail/raw text, score before/after, score delta, and opaque sport metadata.
- [ ] Domain `GameProgress` supports selected mode, last read event identity, scroll fallback, reached scoreboard, timestamps, and locally persisted progress hooks.
- [ ] Baseball-specific fields are not added to generic domain structs except as opaque sport metadata.
- [ ] Mappers cover list games, detail games, and play entries with fallback behavior for current payloads.

## Implementation Notes


Attempt 1: Split SDA wire contracts into DTOs, added sport-neutral domain Game/GameEvent/GameProgress/ScoreState models and mappers, migrated API/view models/views to domain data, and expanded decoding/mapper tests.