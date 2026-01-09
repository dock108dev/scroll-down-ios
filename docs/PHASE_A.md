# Beta Phase A — Trust & Routing

## Routing Overview

Game navigation now uses a single, deterministic path:

1. **Home list** emits `AppRoute.game(id:league:)` using `GameSummary.id` from the backend.
2. **ContentView** routes `AppRoute.game` directly into `GameDetailView`.
3. **GameDetailViewModel** loads detail data using the same `gameId` and rejects any mismatch.

This ensures the app never derives, guesses, or reuses list indices for routing.

## Game Identity Flow

- **Source of truth:** `GameSummary.id` from the backend.
- **Propagation:** `HomeView` → `AppRoute` → `GameDetailView` → `GameDetailViewModel` → API calls.
- **Validation:** If the backend returns a different game ID than requested, the detail view is marked unavailable and does not render mismatched data.

## Safe Fallback Behavior

If routing cannot be resolved safely (invalid ID or mismatched detail response), the detail screen shows a neutral “Game unavailable” state and navigation is not retried automatically. This prevents opening the wrong game.

## Diagnostic Logging

Routing events are logged via `GameRoutingLogger` (OSLog category: `routing`). Every log line includes:

- tapped game ID
- destination game ID
- league
- timestamp

Events emitted:

- `tap` — user tapped a game
- `navigate` — navigation is initiated
- `detail_load` — detail view begins loading
- `id_mismatch` — backend returned a different ID
- `invalid_navigation` — invalid or missing ID blocked

### How to Debug

1. Open Console.app while running the app on device or simulator.
2. Filter for subsystem `com.scrolldown.app` and category `routing`.
3. Confirm the tap → navigate → detail_load sequence for each game.
4. Investigate any `id_mismatch` or `invalid_navigation` events before triaging user reports.
