# App Reference

## App Shape

`ScrollDownSportsApp` creates a `UserDefaultsGameStateStore`, gives it to `ContentView`, and wires the same store into `BackgroundDataScheduler`.

`ContentView` hosts `HomeView` in a `NavigationStack`. `HomeView` shows league and team filters, a refresh button, pull-to-refresh, pinned games, today's games, and earlier games. The home fetch window is `GameWindow.home`, which starts 72 hours before the current instant and runs through the end of tomorrow in the New York calendar.

`GameDetailView` loads one game by id, shows a game header, optional resume banner, stream controls, play-by-play, player stats, team stats, and then the box score section. The detail screen starts a foreground refresh loop every five minutes while visible and stops it on disappear.

## API And Configuration

`SDAApiClient` reads `SDABaseURL` and `SDAApiKey` from `Info.plist`. Those plist values are backed by the Xcode build settings `SDA_API_BASE_URL` and `SDA_API_KEY` from `Config/Secrets.xcconfig`, with optional local overrides from ignored `Config/Local.xcconfig`.

If `SDABaseURL` is absent or invalid, `SDAApiClient` falls back to `https://sda.dock108.dev`. If `SDAApiKey` is empty or still an unresolved build-setting placeholder, requests are sent without `X-API-Key`.

The client calls:

```text
GET /api/admin/sports/games?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD&limit=200
GET /api/admin/sports/games/{id}
```

The list call can also include `league=<league>` when the home league filter is not `All`.

## Local State

`UserDefaultsGameStateStore` persists one `LocalGameStateSnapshot` under `com.dock108.scrolldownsports.localGameState.v1`. The snapshot stores pinned game records, per-game progress, the last all-league home snapshot, and the most recent background refresh record.

Per-game progress stores selected mode, first and last viewed timestamps, last read event id or index, scroll fallback, expanded section ids, expanded raw-feed keys, scoreboard reach, follow-live preference, known event count, new event count, and an event identity baseline.

Progress for unpinned games is pruned after 30 days. Pinned game records are kept until unpinned.

## Refresh Behavior

`HomeViewModel` refreshes the home list with a limit of 200 games and saves the all-league home snapshot for the current home window. It starts a five-minute foreground refresh loop while `HomeView` is active.

`GameDetailViewModel` fetches game detail by id, records event-list diffs, updates pinned game detail when applicable, and records event refresh state in the local store. It also starts a five-minute foreground refresh loop while the detail view is active.

`AppDelegate` registers a background app-refresh task with identifier `com.dock108.scrolldownsports.refresh`. When the scene enters the background, `ScrollDownSportsApp` prunes local state and asks `BackgroundDataScheduler` to schedule a refresh no earlier than five minutes later. The scheduler cancels pending refresh when the scene becomes active.

`BackgroundRefreshService` refreshes the home window, updates pinned game summaries, and fetches detail for up to eight prioritized pinned games. Priority favors live games, today's games, games recently started or completing, games starting within 12 hours, and records that have not been refreshed recently.

## Presentation Model

`DetailStreamMode` exposes three user-facing stream modes: `Key`, `Flow`, and `Full`. The modes map to stored `GameMode` values `timeline`, `flow`, and `stream`.

`SportRendererRegistry` routes MLB to `BaseballRenderer`, NHL to `HockeyRenderer`, NFL to `FootballRenderer`, NBA to `BasketballRenderer`, soccer leagues to `SoccerRenderer`, golf to `GolfRenderer`, and tennis or unknown sports to `GenericSportRenderer`.

The home card state hides score rows behind a `Score at bottom` cue when a game has a score, is final or catch-up capable, and the local record has not reached the scoreboard yet. Once the scoreboard has entered the detail viewport, `GameDetailView` records `reachedScoreboard`.

## Build Metadata

`project.yml` defines one iOS application target, `ScrollDownSports`, and one unit-test target, `ScrollDownSportsTests`. The deployment target is iOS 18.0, Swift version is 6.0, marketing version is 0.1.0, and current project version is 1.

The app target uses `ScrollDownSports/Resources/Info.plist`, `ScrollDownSports/Resources/ScrollDownSports.entitlements`, and `ScrollDownSports/Resources/PrivacyInfo.xcprivacy`. The privacy manifest currently declares no collected data types, no accessed API types, no tracking domains, and tracking disabled.

The shared `ScrollDownSports` scheme gathers coverage for the app target during XCTest. Local and CI runs write `.build/TestResults/ScrollDownSports.xcresult`, emit `.build/coverage/xccov-report.json` and `.build/coverage/xccov-files.json`, and enforce the filtered threshold policy in `Config/coverage-thresholds.json`.
