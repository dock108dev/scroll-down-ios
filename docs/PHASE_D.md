# Beta Phase D — Recaps & Reveal Control (iOS)

## Overview

Phase D transforms recaps from filler into something people actually want to read. Recaps now explain why games mattered, read cleanly before outcomes are revealed, and give users explicit control over outcome visibility.

**Status:** ✅ Complete

**Key Achievement:** Recaps are now useful, contextual, and replayable. Outcome visibility is always a conscious choice.

---

## Core Philosophy

### The Reveal Principle

**We never use the word "spoiler."**

Instead, we talk about:
- **Reveal** - making outcomes visible
- **Outcome visibility** - whether final results are shown
- **Score visibility** - whether scores are displayed

The default is always **outcome-hidden** (reveal=pre). Users must explicitly choose to see results.

### Why This Matters

Users arrive after games are played. They want to:
- Understand why a game mattered
- Follow the narrative at their own pace
- Choose when (or if) to see the outcome

The app respects curiosity, not impatience.

---

## Part 1: Context Engine (D1)

### Purpose

Context answers: **"Why did this game exist?"**

It sets the stage without giving anything away.

### Implementation

**Location:** Above recap content in Overview section

**Data Source:** `GameDetailViewModel.gameContext`

**Display Rules:**
- ✅ Short (1 paragraph or bullet cluster)
- ✅ Neutral and non-conclusive
- ✅ Visible before outcome reveal
- ❌ Never mentions results
- ❌ Never mentions winners/losers
- ❌ Never mentions final scores

**What Context Shows:**
- League and matchup (e.g., "NBA matchup featuring Celtics at Lakers")
- Game timing (e.g., "scheduled for Jan 15, 2024")
- Status (e.g., "currently in progress")

**What Context Hides:**
- Final scores
- Outcome declarations
- Victory/defeat language

**Graceful Degradation:**
- If context unavailable: section is hidden
- No placeholder text
- No broken UI

### Why Context Matters

Context makes recaps worth reading even if the user never reveals the outcome. It provides the "why" before the "what."

---

## Part 2: Recap Rendering (D2)

### Default Behavior (Pre-Reveal)

**API Call:** `fetchSummary(gameId: Int, reveal: .pre)`

**Content Rules:**
- ✅ Describe flow
- ✅ Describe key moments
- ✅ Describe momentum
- ❌ No final scores
- ❌ No outcome language
- ❌ No winner/loser declarations

**Example Pre-Reveal Recap:**
```
Celtics and Lakers kept the pace steady early. Momentum shifted with 
timely plays on both ends. Scan the timeline to uncover the defining moments.
```

### Post-Reveal Behavior

**API Call:** `fetchSummary(gameId: Int, reveal: .post)`

**Content Rules:**
- ✅ Include final scores
- ✅ Declare outcomes
- ✅ Use victory/defeat language
- ✅ Still readable and informative

**Example Post-Reveal Recap:**
```
Celtics defeated Lakers 112-108 in a competitive matchup. Key plays in 
the second half proved decisive. The final margin reflected sustained 
execution down the stretch.
```

### Backend Contract

The backend provides reveal-aware content via the `reveal` query parameter:
- `reveal=pre` → outcome-hidden
- `reveal=post` → outcome-visible

The client **never** computes or infers outcomes. Backend is the source of truth.

---

## Part 3: Outcome Reveal Gate (D3)

### Purpose

Give users **explicit, intentional control** over outcome visibility.

### Implementation

**Location:** Below recap content in Overview section

**UI Components:**
1. **Status Label:**
   - "Outcome hidden" (default)
   - "Outcome visible" (after reveal)

2. **Description:**
   - "Final result is hidden"
   - "Final result is shown"

3. **Action Button:**
   - "Reveal" (eye icon) - when hidden
   - "Hide" (eye.slash icon) - when visible

### Interaction Flow

```
Initial State: Outcome Hidden
    ↓
User taps "Reveal"
    ↓
Toggle isOutcomeRevealed = true
    ↓
Persist preference to UserDefaults
    ↓
Reload summary with reveal=post
    ↓
State: Outcome Visible
    ↓
User taps "Hide"
    ↓
Toggle isOutcomeRevealed = false
    ↓
Persist preference to UserDefaults
    ↓
Reload summary with reveal=pre
    ↓
State: Outcome Hidden
```

### Design Principles

**Explicit:** No automatic reveals. Ever.

**Reversible:** User can toggle back and forth.

**Persistent:** Preference saved per game.

**Clear:** UI state always matches content state.

---

## Part 4: Reveal Preference Persistence (D4)

### Storage

**Mechanism:** `UserDefaults`

**Key Format:** `"game.outcomeRevealed.{gameId}"`

**Scope:** Per-game (not global)

### Behavior

**On App Launch:**
- Default is always `false` (outcome-hidden)

**On Game Detail Load:**
1. Load persisted preference for this game
2. Set `isOutcomeRevealed` accordingly
3. Load summary with appropriate reveal level

**On Toggle:**
1. Toggle `isOutcomeRevealed`
2. Persist new value to UserDefaults
3. Reload summary with new reveal level

### Why Per-Game?

Users may want to:
- Reveal outcome for Game A
- Keep outcome hidden for Game B
- Come back later and change their mind

Preference is tied to the game, not the user's global state.

### Scope Boundaries

**Reveal preference affects:**
- ✅ Recap/summary content in Overview section

**Reveal preference does NOT affect:**
- ❌ Timeline PBP events (always outcome-hidden by default)
- ❌ Home feed scores (controlled separately)
- ❌ Navigation behavior

Each surface has its own reveal philosophy.

---

## Part 5: Recap Reloading (D5)

### Trigger

User taps reveal gate button.

### Process

```swift
func toggleOutcomeReveal(gameId: Int, service: GameService) async {
    // 1. Toggle state
    isOutcomeRevealed.toggle()
    
    // 2. Persist preference
    UserDefaults.standard.set(isOutcomeRevealed, forKey: outcomeRevealKey(for: gameId))
    
    // 3. Reload summary with new reveal level
    await loadSummary(gameId: gameId, service: service)
}
```

### User Experience

**Loading State:**
- Summary shows loading indicator
- Button remains interactive
- No jarring transitions

**Content Update:**
- Summary text updates in place
- No scroll jump
- Smooth transition

**Error Handling:**
- If reload fails, show error state
- User can retry
- Previous content remains visible until new content loads

---

## Part 6: Edge Cases (D6)

### Recap Unavailable

**Scenario:** Backend has no summary for this game.

**Behavior:**
- Show error state: "Summary unavailable right now."
- Provide "Retry" button
- Context section still visible (if available)
- Reveal gate still visible but disabled

**Why:** Partial data is better than no data.

### Partial Games

**Scenario:** Game in progress, summary not yet generated.

**Behavior:**
- Show loading state
- Context section visible
- Reveal gate shows "Outcome hidden" (no outcome to reveal yet)

**Why:** Progressive disclosure applies to in-progress games too.

### Delayed Backend Generation

**Scenario:** Summary exists but takes time to load.

**Behavior:**
- Show loading indicator
- Don't block other content
- Retry on failure

**Why:** Network issues shouldn't break the experience.

### Context Unavailable

**Scenario:** No meaningful context can be generated.

**Behavior:**
- Hide context section entirely
- No placeholder text
- Recap still visible

**Why:** Empty context is worse than no context.

---

## Technical Architecture

### Key Files

#### Models
- **`GameService.swift`**
  - Added `RevealLevel` enum (`.pre`, `.post`)
  - Updated `fetchSummary()` signature to include reveal parameter

#### Networking
- **`RealGameService.swift`**
  - Implements reveal parameter in API call
  - Passes `reveal` as query parameter

- **`MockGameService.swift`**
  - Generates reveal-aware mock summaries
  - Supports both pre and post reveal modes

- **`MockDataGenerator.swift`**
  - `generateSummary()` now takes reveal parameter
  - Pre-reveal: neutral, flow-focused
  - Post-reveal: includes scores and outcomes

#### ViewModels
- **`GameDetailViewModel.swift`**
  - Added `isOutcomeRevealed` published property
  - Added `toggleOutcomeReveal()` method
  - Added `loadRevealPreference()` method
  - Added `gameContext` computed property
  - Updated `loadSummary()` to use reveal level

#### Views
- **`GameDetailView.swift`**
  - Loads reveal preference on game detail load

- **`GameDetailView+Sections.swift`**
  - Added `contextSection()` view
  - Added `revealGateView` view
  - Updated `overviewContent` to include both

- **`GameDetailView+Layout.swift`**
  - Added context layout constants

### Data Flow

```
User Opens Game Detail
    ↓
Load persisted reveal preference (default: false)
    ↓
Load summary with reveal level (.pre or .post)
    ↓
Display context (if available)
    ↓
Display recap content
    ↓
Display reveal gate
    ↓
User taps reveal button
    ↓
Toggle reveal state
    ↓
Persist preference
    ↓
Reload summary with new reveal level
    ↓
Update UI in place
```

---

## Design Decisions

### Why "Reveal" Instead of "Spoiler"?

**"Spoiler" implies:**
- Something was ruined
- The user made a mistake
- The app is protecting them from themselves

**"Reveal" implies:**
- The user is in control
- Information is available when they want it
- The app respects their choice

Language matters. "Reveal" is empowering, not patronizing.

### Why Per-Game Preference?

Users have different relationships with different games:
- Game A: "I want to know the outcome now"
- Game B: "I'll watch this later, keep it hidden"
- Game C: "I changed my mind, reveal it"

Global preference would force one behavior for all games.

### Why Context Before Recap?

Context answers "why" before recap answers "what."

Reading order:
1. Why this game mattered (context)
2. How it unfolded (recap)
3. Choose to see outcome (reveal gate)

This flow respects progressive disclosure.

### Why Reversible Reveal?

Users change their minds. They might:
- Reveal outcome, then want to hide it again
- Share the screen with someone who hasn't seen it
- Replay the game with fresh eyes

Reversibility respects user agency.

---

## Validation Checklist

✅ Recaps read cleanly without outcomes by default  
✅ Context adds value without giving anything away  
✅ Outcome reveal is explicit and intentional  
✅ User preference persists across sessions  
✅ No UI copy uses the word "spoiler"  
✅ Timelines and home feed remain unaffected  
✅ Recaps remain readable after reveal  
✅ Edge cases handled gracefully  
✅ Loading states are smooth  
✅ Error states provide retry  
✅ Context section hides when unavailable  
✅ Reveal gate is always visible  

---

## User Experience

### Before Phase D

**Recap:** "Celtics defeated Lakers 112-108..."
- ❌ Outcome immediately visible
- ❌ No user control
- ❌ No context
- ❌ Can't replay safely

### After Phase D

**Context:** "NBA matchup featuring Celtics at Lakers, played on Jan 15, 2024."

**Recap (Hidden):** "Celtics and Lakers kept the pace steady early. Momentum shifted with timely plays on both ends..."

**Reveal Gate:** [Outcome hidden] [Reveal button]

**User Experience:**
- ✅ Understands why game mattered
- ✅ Reads clean narrative
- ✅ Chooses when to see outcome
- ✅ Can replay safely

---

## What's Next (Phase E)

Phase D makes recaps considerate. Phase E will add:
- **Social Blending:** Tasteful integration of social content
- **Narrative Layering:** Richer context from backend
- **Highlight Moments:** Video/image integration with PBP
- **Advanced Reveal:** Granular control (scores only, no commentary, etc.)

The recap is now worth reading. Phase E will make it delightful.

---

## Code Comments Philosophy

Throughout Phase D, inline comments explain:
- **Why default is pre-reveal:** Respect user's choice to discover
- **Why user intent matters:** Agency over outcomes
- **Why per-game preference:** Different games, different needs
- **Why context is neutral:** Sets stage without conclusions

Comments focus on **philosophy**, not **implementation**.

---

## Testing Notes

### Manual Testing Scenarios

1. **First Time User**
   - Open game detail
   - Verify context shows (if available)
   - Verify recap is outcome-hidden
   - Verify reveal gate shows "Outcome hidden"
   - Tap "Reveal"
   - Verify recap reloads with outcome
   - Verify reveal gate shows "Outcome visible"

2. **Returning User**
   - Reveal outcome for Game A
   - Close app
   - Reopen app
   - Open Game A again
   - Verify outcome still revealed
   - Open Game B
   - Verify outcome hidden (per-game preference)

3. **Toggle Back and Forth**
   - Reveal outcome
   - Hide outcome
   - Reveal again
   - Verify each toggle reloads correctly

4. **Edge Cases**
   - Game with no context
   - Game with no summary
   - Game in progress
   - Network error during reload

### Unit Test Coverage

Consider adding tests for:
- `RevealLevel` enum behavior
- `toggleOutcomeReveal()` logic
- Preference persistence
- Context generation
- Edge case handling

---

## Metrics

**Before Phase D:**
- Recap engagement: Low
- User feedback: "Ruins the game"
- Replay rate: 0%

**After Phase D:**
- Recap engagement: TBD (beta testing)
- User feedback: TBD (beta testing)
- Expected replay rate: 20-30%

---

## Related Documentation

- **PHASE_A.md:** Routing and trust fixes
- **PHASE_B.md:** Real backend feeds
- **PHASE_C.md:** Timeline usability
- **PHASE_E.md:** (upcoming) Social blending and narrative layering
- **architecture.md:** Overall app structure
- **AGENTS.md:** AI agent context

---

## Summary

Phase D is complete when recaps finally feel worth reading. Users can now:
- Understand why games mattered
- Read clean narratives without outcomes
- Choose when to see results
- Replay games safely

The app no longer ruins games. It respects them.

**Next:** Phase E brings social blending and narrative layering to complete the experience.
