# ISSUE-020: Apply final sports-native visual identity, motion, and screenshot polish

**Priority**: medium
**Labels**: polish, visual, motion
**Dependencies**: ISSUE-001, ISSUE-006, ISSUE-007, ISSUE-011, ISSUE-013, ISSUE-014, ISSUE-019
**Status**: implemented

## Description

Add the composition-level visual pass the BRAINDUMP asks for after the underlying surfaces exist. ISSUE-001 defines tokens, while this issue applies the full product feel across home and detail: vertical sports tape rhythm, old-school scoreboard payoff, varied card states, restrained team accents, coherent header/nav treatment, subtle motion/haptics for pin/jump/latest/reached states, and screenshot review to ensure the app no longer reads as a generic green iOS list.

## Acceptance Criteria

- [ ] Home and detail screens feel like a cohesive sports stream rather than unrelated white card lists.
- [ ] Green is limited to intentional sport/status use and no longer dominates headings, rails, borders, icons, and stat accents.
- [ ] The stream reads as a vertical sports tape with period dividers, event rhythm, new-play separators, live-edge marker, and end-of-stream/scoreboard cue where applicable.
- [ ] Team colors are used only as restrained accents such as abbreviations, markers, rails, or scoreboard rows, not giant generic backgrounds.
- [ ] Home cards, detail header, stream control bar, event cards, stat summary, and scoreboard share one surface/radius/spacing language.
- [ ] Header/nav treatment, toolbar buttons, stream controls, and card action controls feel like one control family rather than separate ad hoc styles.
- [ ] Typography hierarchy matches content importance: team names and moment headlines lead, metadata/raw feed/table cells stay compact and quiet.
- [ ] Motion and haptics are subtle and limited to state changes such as pin/unpin, jump latest, new plays, score delta, or reaching live edge.
- [ ] Motion reinforces state changes without casino-like effects or distracting loops.
- [ ] Manual screenshot review covers home, pinned state, live game detail, final catch-up detail, stats, scoreboard, empty/filter states, and at least one small-screen viewport.
- [ ] Manual screenshot review confirms text does not overlap, controls do not crowd, raw-feed prose no longer dominates, important events are visually obvious, and the scoreboard feels like the bottom payoff.

## Implementation Notes


Attempt 1: Applied final sports-native polish across shared controls, haptics, home/detail chrome, stream tape markers, scoreboard actions, and navigation. Added invariant coverage for shared controls, green reduction, stream dividers, and bottom payoff cues.