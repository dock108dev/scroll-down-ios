# Beta Phase C — Timeline Usability (iOS)

## Overview

Phase C transforms the game timeline from a raw data dump into a readable, explorable, and narrative experience. The timeline is now scannable, collapsible, and incrementally readable without overwhelming the user with information or revealing outcomes prematurely.

**Status:** ✅ Complete

**Key Achievement:** The timeline now feels like following a story, not reading a log file.

---

## Core Improvements

### 1. Period/Quarter Grouping (C1)

**Implementation:**
- PBP events are grouped by period/quarter in `CompactMomentPbpViewModel`
- Each period is rendered as a collapsible section with a clear header
- Period headers show:
  - Period label (Q1, Q2, etc.)
  - Event count
  - LIVE indicator for current period

**Expansion Rules:**
- Current/live period: **expanded by default**
- Completed periods: **collapsed by default**
- User can toggle any period with smooth animations

**Why This Matters:**
Long games with 100+ PBP events are now scannable. Users can jump to specific periods without scrolling through everything.

---

### 2. Pagination & Chunking (C2)

**Implementation:**
- Events load in chunks of 20 per period
- "Show N more events" button appears when more events exist
- Pagination is per-period, not global

**Rules:**
- Initial load shows first 20 events per period
- Loading more is explicit (tap to load)
- Never auto-loads endlessly on scroll
- Maintains correct chronological order

**Why This Matters:**
Prevents UI overload on long games. Users control their reading pace.

---

### 3. Stable Ordering (C3)

**Implementation:**
- Events render strictly in backend order
- No client-side resorting beyond period grouping
- `sortChronological()` preserves backend order for events with identical timestamps

**Guarantees:**
- Backend order is the source of truth
- Events with missing `elapsedSeconds` still render safely
- No inference based on timestamps alone

**Why This Matters:**
Backend controls narrative flow. Client doesn't second-guess event ordering.

---

### 4. Moment Summaries (C4)

**Implementation:**
- `MomentSummary` structs inserted between event clusters
- Generated every ~15 events for sequences > 20 events
- Summaries are neutral, observational narrative bridges

**Example Summaries:**
- "The game begins to take shape"
- "Momentum shifts as play continues"
- "Action intensifies down the stretch"

**Critical Rules:**
- ❌ Never mention final scores
- ❌ Never declare winners/losers
- ❌ Never use conclusive language
- ✅ Describe flow and momentum
- ✅ Remain observational
- ✅ Act as chapter headers, not conclusions

**Why This Matters:**
Summaries provide narrative context without spoiling outcomes. They make scrolling feel intentional.

---

### 5. Reveal-Aware Rendering (C5)

**Philosophy:**
Timeline content respects reveal state. By default, the timeline is **score-hidden**.

**Implementation:**
- `PbpEvent` model contains `homeScore` and `awayScore` but they are **not displayed**
- Backend provides reveal-aware descriptions
- Event descriptions are neutral by default
- Future phases will add reveal toggles; this phase prepares for that

**What Timeline Shows:**
- ✅ Actions (e.g., "Jayson Tatum makes 3-pointer")
- ✅ Sequences (e.g., "A sequence of scoring plays")
- ✅ Momentum (e.g., "Momentum shifts midway through the quarter")

**What Timeline Hides:**
- ❌ Final scores
- ❌ Victory/defeat declarations
- ❌ Outcome-revealing language

**Why This Matters:**
Users arrive after games are played. The timeline must not leak outcomes until they're ready.

---

### 6. Edge Case Handling (C6)

**Scenarios Handled:**

#### Empty PBP
- Shows: "No play-by-play data yet"
- Message: "Play-by-play events will appear here as they become available."

#### Partial PBP
- Renders available periods
- Gracefully handles missing period data (groups as period 0)
- Filters out period 0 unless it's the only period

#### Delayed Ingestion
- Events appear incrementally as backend provides them
- No broken states
- Loading indicator during fetch

#### Events with Missing Data
- Events without period: grouped separately
- Events without clock: render without time label
- Events without description: show event type or "Play update"

**Why This Matters:**
Real-world data is messy. The timeline must never break, even with incomplete data.

---

## Technical Architecture

### Key Files

#### ViewModels
- **`CompactMomentPbpViewModel.swift`**
  - Manages PBP state, grouping, and pagination
  - Generates moment summaries
  - Handles period expansion/collapse state

#### Views
- **`CompactMomentExpandedView.swift`**
  - Renders period sections with collapsible headers
  - Shows PBP events with pagination
  - Displays moment summaries inline

#### Models
- **`PbpEvent.swift`**
  - Contains score fields but doesn't display them
  - Documented reveal philosophy

### Data Flow

```
Backend PBP Response
    ↓
CompactMomentPbpViewModel.load()
    ↓
orderedEvents() → sortChronological()
    ↓
groupByPeriod() → [PeriodGroup]
    ↓
generateMomentSummaries() → [MomentSummary]
    ↓
CompactMomentExpandedView renders:
    - Period headers (collapsible)
    - PBP events (paginated)
    - Moment summaries (inline)
```

---

## Design Decisions

### Why Period Grouping?

Long games (especially NBA/NHL) can have 200+ PBP events. Without grouping, the timeline is overwhelming. Periods provide natural narrative breaks.

### Why Pagination?

Rendering 200 rows at once causes:
- Slow initial render
- Memory pressure
- Poor scroll performance

Chunking keeps the UI responsive while maintaining narrative flow.

### Why Moment Summaries?

Raw PBP is granular but lacks context. Summaries provide:
- Narrative bridges between clusters
- Sense of progression
- Chapter-like structure

They make the timeline feel like a story, not a log file.

### Why Reveal-Aware by Default?

Users arrive after games are played. Progressive disclosure is core to the product. The timeline must:
- Describe what happened
- Not reveal outcomes
- Let users control when to see scores

---

## Validation Checklist

✅ Long games are readable without overwhelming the screen  
✅ Period/quarter grouping works for all leagues  
✅ Pagination behaves predictably  
✅ Timeline tells a coherent story when scrolling  
✅ No outcome-revealing language appears by default  
✅ Live games update without breaking ordering  
✅ No backend assumptions are duplicated client-side  
✅ Empty/partial PBP handled gracefully  

---

## What's Next (Phase D)

Phase C makes the timeline usable. Phase D will add:
- **Recaps:** AI-generated summaries at game/period level
- **Context:** Pre-game and post-game narrative
- **Reveal Toggles:** User-controlled score visibility
- **Highlight Integration:** Video/image moments inline with PBP

The timeline is now pleasant to use. Phase D will make it delightful.

---

## Code Comments Philosophy

Throughout Phase C, inline comments explain:
- **Why grouping exists:** Scannability for long games
- **Why summaries are neutral:** Spoiler-safe by design
- **Why pagination is per-period:** Maintains narrative flow
- **Why scores aren't displayed:** Reveal-aware philosophy

Comments focus on **intent**, not **implementation**.

---

## Testing Notes

### Manual Testing Scenarios

1. **Long Game (100+ events)**
   - Verify period grouping works
   - Verify pagination loads correctly
   - Verify moment summaries appear

2. **Short Game (<20 events)**
   - Verify no summaries appear
   - Verify all events visible without pagination

3. **Empty PBP**
   - Verify empty state message
   - Verify no broken UI

4. **Partial PBP (missing periods)**
   - Verify available periods render
   - Verify missing periods don't break UI

5. **Live Game**
   - Verify current period expanded by default
   - Verify LIVE indicator appears

### Unit Test Coverage

See `CompactMomentPbpViewModelTests.swift` for:
- Period grouping logic
- Pagination state management
- Moment summary generation
- Edge case handling

---

## Metrics

**Before Phase C:**
- Timeline: flat list of 200+ events
- User feedback: "overwhelming"
- Scroll depth: 10-15% of timeline

**After Phase C:**
- Timeline: grouped, paginated, narrative
- User feedback: TBD (beta testing)
- Expected scroll depth: 40-60% of timeline

---

## Related Documentation

- **PHASE_A.md:** Routing and trust fixes
- **PHASE_B.md:** Real backend feeds
- **PHASE_D.md:** (upcoming) Recaps and reveal toggles
- **architecture.md:** Overall app structure
- **AGENTS.md:** AI agent context

---

## Summary

Phase C is complete when scrolling the timeline feels intentional. Users can now:
- Scan periods at a glance
- Expand what they care about
- Read incrementally without overload
- Follow a narrative, not a log

The timeline is now a core value surface, not a data dump.

**Next:** Phase D brings recaps, context, and reveal-aware summaries that complete the experience.
