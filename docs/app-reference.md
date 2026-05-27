# App Reference

## App Shape

`ScrollDownSportsApp` creates a game-state store and passes it into `ContentView`. Debug UI-test runs use `InMemoryGameStateStore`; other runs use `UserDefaultsGameStateStore`. The same store is assigned to `BackgroundDataScheduler`.

`ContentView` hosts `HomeView` in a compact `NavigationStack` or a regular-width `NavigationSplitView` based on `SportsLayoutMetrics`. `HomeView` has a sticky filter header with league selection and team search, a refresh toolbar button, pull-to-refresh, an optional pinned section, and a timeline section. Timeline date sections are built from older catch-up games, yesterday, today, live games, later today, and upcoming games when those groups contain visible games.

`GameDetailView` loads one game by id. When detail data is available, it renders the game header, optional resume banner, stream controls, play-by-play, player stats, team stats, and a box-score section. Play rows can include sport-rendered situation panels and expandable raw-feed details when the mapped event data supports them. The detail screen starts a five-minute foreground refresh loop while visible and stops it on disappear.

## API Contract

`SDAApiClient` reads `SDABaseURL` and `SDAApiKey` from `Info.plist`. Backend setup, signing, and local override mechanics are documented in [Local development](local-development.md).

The client calls:

```text
GET /api/admin/sports/games?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD&limit=200
GET /api/admin/sports/games/{id}
```

The list call can also include `league=<league>` when the home league filter is not `All`. Game phase comes from `presentation.displayState` when present and otherwise from the canonical `status` value.

The current list payload contract does not support removed flat compatibility fields:

- `isLive`
- `isFinal`
- flat `homeScore`
- flat `awayScore`

Scores come from `scoreboard.competitors` or the canonical nested `score` object. Detail event score changes come from explicit `scoreDelta`, not inferred `scoreChanged`.

The detail call rejects responses whose `detailContractVersion` is below 2, whose plays are missing all-mode eligibility, display type, period label, or usable event text, or whose required v2 fields cannot decode.

## Game Window

`GameWindow.home` starts 72 hours before the current instant and runs through the end of tomorrow in the New York calendar. `HomeViewModel` requests that window with a limit of 200 games and applies the selected league filter as an API query parameter when a specific league is selected.

`SDAApiClient.fetchGames` filters decoded games to the requested window after decoding. `HomeViewModel` then filters the home timeline to games with concrete participants and useful timeline, scoreboard, score, or pregame presentation data.

## Local State

`UserDefaultsGameStateStore` persists one `LocalGameStateSnapshot` under `com.dock108.scrolldownsports.localGameState.v1`. Corrupt persisted data is backed up under `com.dock108.scrolldownsports.localGameState.corrupt.v1` and replaced with an empty snapshot.

The snapshot stores pinned game records, per-game progress, the last all-league home snapshot, and the most recent background refresh record. Per-game progress stores selected mode, first and last viewed timestamps, last read event id or index, scroll fallback, expanded section ids, expanded raw-feed keys, scoreboard reach, follow-live preference, known event count, new event count, and an event identity baseline.

Progress for unpinned games is pruned after 30 days. Pinned game records are kept until unpinned.

## Refresh Behavior

`HomeViewModel` refreshes the home list with a limit of 200 games. It saves the all-league home snapshot for the current home window, updates pinned summaries for fetched pinned games, separately fetches up to eight pinned games that are missing from the home response, and starts a five-minute foreground refresh loop while `HomeView` is active.

`GameDetailViewModel` fetches game detail by id, records event-list diffs, updates pinned game detail when applicable, records event refresh state in the local store, and starts a five-minute foreground refresh loop while the detail view is active.

`AppDelegate` registers a background app-refresh task with identifier `com.dock108.scrolldownsports.refresh`. When the scene enters the background, `AppScenePhaseHandler` prunes local state and asks `BackgroundDataScheduler` to schedule a refresh no earlier than five minutes later. The scheduler cancels pending refresh when the scene becomes active. iOS may still reject or skip background scheduling; the app treats that as a nonfatal scheduling outcome.

`BackgroundRefreshService` refreshes the home window, updates pinned game summaries, and fetches detail for up to eight prioritized pinned games. Priority favors live games, today's games, games that started within the last two hours, games starting within 12 hours, and records that have not been refreshed recently.

## Presentation Model

`DetailStreamMode` exposes three stream modes: `Important`, `Standard`, and `All Plays`. The modes map to stored `GameMode` values `timeline`, `flow`, and `stream`.

`SportRendererRegistry` routes MLB to `BaseballRenderer`, NHL to `HockeyRenderer`, NFL to `FootballRenderer`, NBA to `BasketballRenderer`, soccer leagues to `SoccerRenderer`, golf to `GolfRenderer`, tennis to `TennisRenderer`, and other sports to `GenericSportRenderer`.

Detail event mapping keeps score-before, score-after, score-delta, optional `situationBefore` and `situationAfter` snapshots, and merged sport metadata on each `GameEvent`. `PlayByPlaySection` passes the selected stream mode, visible event list, event index, game, and score-spoiler policy into the renderer so situation cards are only built for events visible in the current stream.

Situation cards use `SituationCardPolicy` and `SituationConfidenceGate` before rendering. Baseball can render a typed diamond when explicit pre-event base state is present, while ambiguous or generic context can fall back to a pressure board. Football, basketball, hockey, soccer, golf, tennis, and unknown sports route their supported situation metadata through sport-specific renderers or the generic pressure-board fallback without fabricating richer diagrams when the required state is missing.

Home card state hides score rows behind a `score at bottom` cue when a game has a score, the local record has not reached the scoreboard, and the game is final or catch-up capable. Once the scoreboard enters the detail viewport, `GameDetailView` records `reachedScoreboard`.

## Build Metadata

`project.yml` defines one iOS application target, `ScrollDownSports`, one unit-test target, `ScrollDownSportsTests`, and one UI-test target, `ScrollDownSportsUITests`. The shared `ScrollDownSports` scheme builds the app and UI-test targets, runs both test targets, and gathers coverage for the app target. XcodeGen should be rerun after changes to `project.yml`.

The app target uses `ScrollDownSports/Resources/Info.plist`, `ScrollDownSports/Resources/ScrollDownSports.entitlements`, and `ScrollDownSports/Resources/PrivacyInfo.xcprivacy`. `Info.plist` permits the background refresh task identifier, declares `fetch` in `UIBackgroundModes`, supports portrait and landscape orientations, and does not declare `UIRequiresFullScreen`. The privacy manifest declares no collected data types, no accessed API types, no tracking domains, and tracking disabled.
