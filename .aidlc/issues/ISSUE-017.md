# ISSUE-017: Decode and consume optional backend presentation fields with legacy fallbacks

**Priority**: high
**Labels**: infra, api, presentation, all-sports
**Dependencies**: ISSUE-002
**Status**: implemented

## Description

Add the migration path for SDA-provided mobile presentation data so the iOS app stops inferring copy, eligibility, importance, and scoreboard structure from raw strings whenever the backend provides better fields. Use `.aidlc/research/backend-presentation-contract.md` and BRAINDUMP section 19: add optional `presentation`, `eligibility`, `scoreboard`, `importance`, mode-eligibility, score-state, score-delta, and raw-description DTOs to list/detail games and plays, then switch presentation models to use those fields first with current fields only as fallback.

## Acceptance Criteria

- [ ] Game summary/detail DTOs decode optional presentation, eligibility, and scoreboard envelopes without breaking older payloads.
- [ ] Game presentation supports headline, short headline, matchup label, display state, visual priority, status/action labels, event counts for Key/Flow/Full, and scoreboard placement metadata when supplied.
- [ ] Play/event DTOs decode optional presentation, importance, raw description, mode eligibility, score before/after, score delta, and sport metadata without breaking older payloads.
- [ ] Game card, detail header, mode eligibility, event headline, event importance, raw-feed expansion, score delta, and scoreboard presentation use backend fields first when present.
- [ ] Legacy fallback order is explicit and tested for scheduled, live, final, no-score, scoring event, routine event, and missing-presentation cases.
- [ ] The app no longer needs to parse status strings, concatenate matchup labels, infer importance, infer mode eligibility, or infer catch-up eligibility except as compatibility fallback.
- [ ] The additive DTOs are unknown-safe so new sports/layouts/reason codes do not break decoding.

## Implementation Notes


Attempt 1: Added optional SDA presentation, eligibility, scoreboard, event importance, raw description, mode eligibility, score state/delta DTOs and mapped them into game/event rendering with legacy fallbacks plus decoding coverage.