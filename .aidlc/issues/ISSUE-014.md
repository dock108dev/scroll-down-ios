# ISSUE-014: Replace stat pill walls with impact summaries and compact tables

**Priority**: medium
**Labels**: feature, stats, visual
**Dependencies**: ISSUE-001, ISSUE-002, ISSUE-003, ISSUE-016
**Status**: implemented

## Description

Redesign stats so they support the stream instead of overwhelming it. Discovery says `PlayerStatsSection`, `MLBPlayerStats`, `NHLStats`, and `GenericPlayerStats` render repeated stat cards/pills and expansion state is local only. Use `.aidlc/research/stats-impact-table-shape.md`, `.aidlc/research/sport-renderer-boundaries.md`, and ISSUE-001 typography/surface tokens to create an impact-first visual hierarchy: a small standout layer, compact tables, quiet full-stat expansion, and sport-specific columns that do not fragment the shared detail page.

## Acceptance Criteria

- [ ] Stats sit below the main stream and before or near the scoreboard according to the detail composition.
- [ ] Impact players are shown first using a small ranked summary based on existing structured stats.
- [ ] Impact-player summaries use highlight treatment only for standout stats, not pill walls for every value.
- [ ] Full player stats render as compact sport-specific tables rather than one large pill card per player.
- [ ] Table typography, row spacing, numeric alignment, and headers follow shared stat-table tokens from the design system.
- [ ] Team stats use compact rows/tables and highlight only the most important summary values.
- [ ] MLB, NHL, and generic stat column choices live in renderer/adapters rather than neutral screen branching.
- [ ] Dense full-stat sections are visually quieter than the stream and impact summary so they do not compete with key moments.
- [ ] Expanded/collapsed full-stat section state persists per game through the local progress store.

## Implementation Notes


Attempt 1: Replaced player/team stat card walls with renderer-owned impact highlights and compact stat tables, added shared table/highlight presentation views, and covered MLB, NHL, generic, team, and innings parsing behavior in SportsThemeTests.