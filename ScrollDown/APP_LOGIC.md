# APP_LOGIC.md — Client-Side Logic Documentation

This document catalogs all logic that **intentionally** remains client-side in the iOS app.
Everything else should come from the API (Single Source of Truth).

---

## 1. Score Reveal/Hide
**Location:** `ReadStateStore`, `GameRowView`, `GameHeaderView`
**Why client-side:** UserDefaults preference for spoiler-free mode. Pure UI state.

## 2. Read State Management
**Location:** `ReadStateStore`
**Why client-side:** Local `Set<gameId>` in UserDefaults tracks which game wrap-ups the user has read. Personal preference, not shared state.

## 3. Reading Position Tracking
**Location:** `ReadingPositionStore`
**Why client-side:** Per-game scroll position and last-viewed scores. Purely local UI state.

## 4. Section Expansion State
**Location:** `GameDetailView` (`collapsedQuarters`)
**Why client-side:** Which timeline sections are collapsed/expanded. Ephemeral UI state.

## 5. Client-Side Search Filtering
**Location:** `OddsComparisonViewModel.searchText`, `HomeView` search
**Why client-side:** Instant team/player name filtering over already-fetched data. Latency-sensitive.

## 6. Live Polling
**Location:** `GameDetailView` (45s game detail), `HomeView` (15min home page)
**Why client-side:** Poll intervals are client decisions. Server provides data on demand.

## 7. Theme Management
**Location:** `AppStorage("appearance")`
**Why client-side:** System/light/dark appearance. Pure device preference.

## 8. Odds Format Preference
**Location:** `OddsComparisonViewModel.oddsFormat`
**Why client-side:** American/decimal/fractional display preference. Stored in UserDefaults.

## 9. Date/Time Formatting
**Location:** `DateFormatting`, `BetCard.formattedTime`
**Why client-side:** Locale-aware display formatting. Depends on device locale/timezone.

## 10. FairBet Client-Side Filtering
**Location:** `OddsComparisonViewModel.applyFilters()`
**Why client-side:** League, market, book, +EV, thin, started filters over pre-fetched data. Instant UX.

## 11. FairBet Client-Side Sorting
**Location:** `OddsComparisonViewModel.SortOption`
**Why client-side:** By EV, game time, league. Operates on local data for instant response.

## 12. FairBet Pagination
**Location:** `OddsComparisonViewModel.loadAllData()`
**Why client-side:** Incremental page loading with concurrent fetches. Client orchestration of API pages.

## 13. Parlay Selection State
**Location:** `OddsComparisonViewModel.parlayBetIDs`
**Why client-side:** UI state tracking which bets are in the parlay. Evaluation calls API with client-side fallback.

## 14. EV Color Mapping
**Location:** `FairBetCopy.colorSemantic()`
**Why client-side:** Maps EV percentages to color semantics (bestRelativeValue/neutral/worseRelativeValue). Theming concern.

## 15. FairExplainerSheet Math Walkthrough
**Location:** `FairExplainerSheet` (mathWalkthroughSection, pairedDevigSteps, medianSteps, etc.)
**Why client-side:** Visual step-by-step math breakdown showing how fair odds are calculated. Rich iOS-specific experience. **Pending:** Will migrate to API `explanation_steps` field when available.

## 16. Period Label Fallback
**Location:** `GameDetailView+Helpers` (quarterTitle, periodLabel, quarterOrdinal)
**Why client-side:** Sport-based switch for period labels when API `currentPeriodLabel` or `play.periodLabel` is missing. Backward compatibility fallback.

## 17. Odds Table Best Price Fallback
**Location:** `BetCard` (`book.price == bestBook?.price`)
**Why client-side:** Local max-price comparison when API `isBest` flag is not available on BookPrice. Fallback only.

## 18. OddsCalculator
**Location:** `OddsCalculator`
**Why client-side:** Pure math conversions (american ↔ decimal ↔ probability). Used as fallback when API doesn't provide pre-computed values (e.g., `fairAmericanOdds`).
