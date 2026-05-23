# ISSUE-012: Group the stream by sport periods and fix duplicated labels

**Priority**: medium
**Labels**: feature, stream, all-sports
**Dependencies**: ISSUE-002, ISSUE-011, ISSUE-016
**Status**: implemented

## Description

Make the vertical sports tape readable by grouping events under sport-specific period labels. Discovery notes `PlayEntry.clockText` joins period and time, causing labels like repeated `1st 1st`, and sorting can fall back to rendered clock text. Use `.aidlc/research/period-grouping-clock-labels.md` and `.aidlc/research/sport-renderer-boundaries.md`: period belongs to the group header, row time belongs inside the group, ordering should be sequence/playIndex-first, and sport-specific fallback labels belong in renderers.

## Acceptance Criteria

- [ ] Stream events are grouped by normalized period labels such as Top 1st, Q1, Period 1, or Game fallback.
- [ ] Rows inside a group show clock/time without duplicating the group period label.
- [ ] Event ordering uses stable sequence/play index rather than rendered clock string.
- [ ] Dedupe identity is revised so it does not rely on raw description alone or ignore `timeLabel`.
- [ ] Renderer/adapters own sport-specific period fallback mapping and terminology.
- [ ] Unknown or incomplete period data degrades to a neutral `Game` grouping without broken duplicated labels.

## Implementation Notes


Attempt 1: Grouped play stream by renderer-owned period labels, stripped duplicated period text from row clocks, revised stream dedupe/sorting to use stable sequence-first identity, and added XCTest coverage for grouping, row labels, ordering, and time-label dedupe.