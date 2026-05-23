# ISSUE-016: Add sport renderer registry and move sport-specific display logic out of core screens

**Priority**: high
**Labels**: infra, architecture, all-sports, rendering
**Dependencies**: ISSUE-001, ISSUE-002
**Status**: implemented

## Description

Create the SwiftUI renderer boundary required by the all-sports foundation. Existing ISSUE-002 separates DTOs from domain models, but the UI also needs a presentation/renderer layer so `HomeView`, `GameDetailView`, and shared catch-up containers do not own MLB/NHL/generic display branches. Use `.aidlc/research/sport-renderer-boundaries.md` and BRAINDUMP section 18: add a registry keyed by league/sport, generic renderer, baseball renderer, hockey renderer, and safe adapters or fallbacks for football, basketball, soccer, golf, tennis, and other future sports where current payloads do not yet support specialized rendering.

## Acceptance Criteria

- [ ] A renderer/adapter layer exists outside `Views`, with registry lookup by league or sport and a safe generic fallback.
- [ ] The renderer protocol or equivalent API covers the explicitly requested surfaces: game card, game header, event, scoreboard, and stats.
- [ ] Core screens remain responsible for navigation, loading, refresh, scrolling, pin/progress state, and layout order only.
- [ ] League colors, sport labels, period fallback labels, stat routing, and sport-specific event/scoreboard presentation are provided through renderer/theme APIs.
- [ ] Baseball renderer owns baseball-specific labels and display concerns such as innings, top/bottom labels, bases/count/outs when available, batting/pitching stats, and inning box score.
- [ ] Football and basketball renderers or fallback adapters reserve ownership for quarters, clock labels, scoring summaries, drives/down-distance, runs, possession, and stat leaders when data exists.
- [ ] Soccer renderer or fallback adapter reserves ownership for minute/stoppage labels, goals/cards/subs, and aggregate/extra-time concepts when data exists.
- [ ] Golf renderer or fallback adapter reserves ownership for tournament/round/hole labels and leaderboard-style results rather than team-score assumptions.
- [ ] Tennis and unknown sports route through generic renderer/fallback without leaking baseball terminology.
- [ ] Duplicated league-color switches in `HomeView.swift` and `GameDetailView.swift` are removed or routed through the renderer/theme layer.
- [ ] MLB and NHL stat/rendering branches no longer live directly in neutral screen containers except as calls into sport renderers.

## Implementation Notes


Attempt 1: Added SportRenderer registry/presentation layer, baseball/hockey/safe fallback renderers, and routed home/detail/header/event/scoreboard/stats UI through renderer APIs with updated tests.