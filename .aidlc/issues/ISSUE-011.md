# ISSUE-011: Render headline-first event cards with raw-feed expansion

**Priority**: medium
**Labels**: feature, stream, visual
**Dependencies**: ISSUE-001, ISSUE-002, ISSUE-008, ISSUE-016, ISSUE-017
**Status**: implemented

## Description

Rebuild play rows into sport-story event cards. Discovery says `PlayRow` uses raw `description` as the main body, small priority badges, a thin generic rail, and no headline/detail/raw hierarchy. Use `.aidlc/research/event-headline-normalization.md`, `.aidlc/research/event-importance-model.md`, `.aidlc/research/raw-feed-expansion-state.md`, `.aidlc/research/backend-presentation-contract.md`, `.aidlc/research/sport-renderer-boundaries.md`, and ISSUE-001 tokens to create a visually paced stream where importance, team ownership, scoring, and raw-feed detail have consistent visual roles.

## Acceptance Criteria

- [ ] Events render as cards or compact rows based on importance: low, medium, high, critical.
- [ ] Each event has period/clock/team context, headline, supporting detail, and optional score delta when available.
- [ ] Moment headlines are visually stronger than detail copy; raw provider prose is smaller, muted, and secondary.
- [ ] Backend `plays[].presentation` and `plays[].importance` are the primary source when present; local formatter and `tier`/`scoreChanged` are compatibility fallbacks only.
- [ ] Raw provider prose is secondary and expandable per event, not the default visual headline.
- [ ] Raw-feed expansion state is keyed by stable event identity and persists through refresh/reopen according to the local progress/store model.
- [ ] Scoring and critical events stand out through semantic color, weight, marker scale, or surface emphasis without making every event equally loud.
- [ ] Low-importance events stay readable but visually quieter and more compact than key moments.
- [ ] Team ownership appears through restrained markers or chips that align with the card and period grouping system.
- [ ] Sport-specific event labels/context come from renderer/adapters rather than hardcoded generic screen logic.
- [ ] The event stream uses consistent spacing and rail/marker rhythm so it reads as one vertical sports tape rather than isolated feed rows.

## Implementation Notes


Attempt 1: Rebuilt event stream rendering in CatchUpSections with headline-first importance cards, renderer-owned labels, score/team context, and persisted raw-feed disclosure keyed by game/event/raw text.