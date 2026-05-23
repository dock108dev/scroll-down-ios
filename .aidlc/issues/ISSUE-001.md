# ISSUE-001: Add shared sports design tokens and surface components

**Priority**: high
**Labels**: infra, design-system, visual
**Dependencies**: none
**Status**: implemented

## Description

Create the design-system foundation before screen-level redesign. Discovery notes styling is embedded across `HomeView.swift`, `GameDetailView.swift`, and `CatchUpSections.swift`, with duplicated league colors, repeated material/card treatments, and heavy green/teal use. Use `.aidlc/research/visual-token-system.md` to add `ScrollDownSports/DesignSystem/SportsTheme.swift` or equivalent tokens for warm base palette, semantic event colors, typography roles, card surfaces, live/final/pinned states, league accents, scoreboard tone, and reusable badge/surface primitives. The goal is a coherent sports-native system, not another set of generic iOS grouped-list colors.

## Acceptance Criteria

- [ ] Shared color, typography, radius, stroke, spacing, and surface tokens exist outside feature views.
- [ ] The base page/background palette shifts away from the current teal/orange/green system-gradient feel toward warm paper/light neutral surfaces with near-black or dark-navy primary text.
- [ ] Duplicated league color mapping in home and detail is replaced by a single token/helper path.
- [ ] Live, final, pinned, scoring, critical, defensive/pitching, neutral, new-play, and scoreboard tones are semantically named and do not default everything to green.
- [ ] Typography roles exist for app title, section title, team names, metadata, moment headline, moment detail, raw feed text, stat table, and status pills.
- [ ] Shared surface primitives exist for Game Card, Game Header Card, Event Card, Stream Control Bar, Scoreboard Card, Stat Summary, badges, rails, and compact table rows.
- [ ] Team colors are tokenized as restrained accents for rails, abbreviations, markers, and scoreboard rows rather than full-card backgrounds by default.
- [ ] Home, detail, and catch-up sections use shared card/badge/surface primitives for new work.
- [ ] Existing app builds after token extraction.

## Implementation Notes


Attempt 1: Added shared SportsTheme/SportsSurfaces design-system tokens and primitives, rewired home/detail/catch-up views to use shared league, tone, typography, surface, badge, rail, scoreboard, and stat row styling, and added token coverage tests.