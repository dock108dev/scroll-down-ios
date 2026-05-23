# Findings

## App shape, navigation, and build surface

The app is a small SwiftUI iOS app. `ScrollDownSports/App/ScrollDownSportsApp.swift` creates the `WindowGroup`, registers background refresh through `AppDelegate`, and hosts `ContentView`. `ScrollDownSports/Views/ContentView.swift` creates one `HomeViewModel`, wraps `HomeView` in a `NavigationStack`, and sets the root title to `Scroll Down`.

Navigation from home to detail is direct: `ScrollDownSports/Views/HomeView.swift` builds `NavigationLink` rows that open `GameDetailView(gameId:summary:)`. There is no tab structure, no persistent pinned-games surface, and no app-wide state object for pins/progress/live-follow state.

The XcodeGen project is defined in `project.yml`. It targets iOS 18, uses Swift 6, includes `ScrollDownSportsTests`, and wires `Config/Secrets.xcconfig` for both Debug and Release. `.aidlc/config.json` has `run_tests_command: null`, so the AIDLC run has no configured canonical test command in repo metadata.

## Backend client and decoding

`ScrollDownSports/Services/SDAApiClient.swift` is the only API client. It calls `GET /api/admin/sports/games` with `startDate`, `endDate`, optional `league`, and `limit`, then filters returned games through `GameWindow.contains`. It calls `GET /api/admin/sports/games/{id}` for detail. The base URL and API key come from `SDABaseURL` and `SDAApiKey` in `ScrollDownSports/Resources/Info.plist`; `README.md` says the default backend is `https://sda.dock108.dev` and warns that upstream returns `401 Missing API key` without credentials.

`ScrollDownSports/Services/Decoding.swift` defines the shared `JSONDecoder.sda` and date formatters. It handles ISO8601 strings with fractional seconds and a fallback `yyyy-MM-dd'T'HH:mm:ssXXXXX` formatter. `ScrollDownSportsTests/DecodingTests.swift` covers decoding a game list shape and a game detail shape, including score, NBA player stats, and one play row.

There is no normalization layer between SDA response models and UI presentation models. Views consume `GameSummary`, `Game`, `PlayEntry`, `PlayerStat`, `TeamStat`, `MLBBatterStat`, `MLBPitcherStat`, and `NHLPlayerStat` directly.

## Current data models and all-sports foundation

`ScrollDownSports/Models/GameModels.swift` defines current API-facing models. `GameSummary` and `Game` are two-team, home/away models with `leagueCode`, `status`, `homeTeam`, `awayTeam`, optional abbreviations, optional period/clock fields, and optional scores. `GameStatusRepresentable` derives `isLiveGame`, `isFinalGame`, and `isPregame` from backend flags or status strings.

The model is partly multi-sport because `leagueCode` is generic and `LeagueFilter` in `ScrollDownSports/ViewModels/HomeViewModel.swift` includes MLB, NBA, NHL, NFL, NCAAB, and NCAAF. It is not yet the sport-neutral model described in BRAINDUMP: there is no `Sport` enum, no `GameParticipant`, no `GameEvent`, no `GameProgress`, no `ScoreState`, no `ScoreDelta`, and no renderer/adaptor interface.

Sports-specific data already leaks into shared model/view files. `GameDetailResponse` includes generic `teamStats` and `playerStats`, plus `mlbBatters`, `mlbPitchers`, `nhlSkaters`, and `nhlGoalies`. `PlayEntry` includes a baseball/basketball-like mix of `quarter`, `periodLabel`, `gameClock`, `timeLabel`, `tier`, and `scoreChanged`. Baseball and NHL stat rendering live in `ScrollDownSports/Views/CatchUpSections.swift`, not in separate sport renderer files.

## Home screen

`ScrollDownSports/ViewModels/HomeViewModel.swift` owns home data. It fetches the current `GameWindow`, applies league and team filters, sorts games by `gameDate` and `id`, and groups them into date sections with titles such as Today, Tomorrow, Yesterday, or weekday names. `GameWindow.current` in `ScrollDownSports/Services/GameWindow.swift` is currently a centered window of 7 past days and 7 future days; `README.md` still describes the app as using 72 hours before now through 48 hours after now, which is stale relative to the code and `ScrollDownSportsTests/GameWindowTests.swift`.

`ScrollDownSports/Views/HomeView.swift` renders the home UI: league segmented picker, team text filter, updated timestamp, date headers, and `GameRowView` cards. Cards show league, start time, optional `LIVE` badge, away/home team lines, and a simple footnote (`In progress`, period/clock, `Scheduled`, or `Catch up`). `GameSummary.playCount` and `hasPbp` are decoded but not displayed.

The home screen does not have a pinned section, pin/unpin controls, resume state, new-play count, score-at-bottom label, viewed/open-recap state, or state-specific final/live/scheduled card structure beyond the live badge and footnote. Scores are present in `GameSummary` but are not rendered in `GameRowView`, so home does not currently reveal final score by default.

## Game detail screen structure

`ScrollDownSports/Views/GameDetailView.swift` owns the detail page. When detail data exists, the page order is `GameHeaderView`, `PlayByPlaySection`, `PlayerStatsSection`, `TeamStatsSection`, and `BoxScoreSection`. That means the score section is structurally at the bottom after stream and stats.

`GameHeaderView` shows league, time, optional `LIVE` badge, away/home team names, and progress text such as period/clock, `Scheduled`, or `Catch up`. It does not render scores at the top. It also does not show score-at-bottom text, catch-up metadata, play counts, resume state, pin state, or selected stream mode.

The screen uses the system navigation bar title `Catch Up` and toolbar buttons. There is no custom opaque sticky header and no deliberate scroll-transition header behavior. The current toolbar pin button is not a game pin: it toggles local `@State private var pinToBottom`, shows a `Pinned` bottom overlay, and scrolls to `detail-bottom-anchor` whenever `pinToBottom` or `updateToken` changes.

## Scoreboard and score visibility

`BoxScoreSection` in `ScrollDownSports/Views/CatchUpSections.swift` is the only score display on the detail page. It is placed after player stats and team stats by `GameDetailView`, so the scoreboard/result is currently bottom-positioned.

The score is hidden by default through local `@State private var scoreRevealed = false`. Before reveal, it shows `Score hidden`, explanatory copy, and a `Reveal box score` button with a confirmation dialog. After reveal, it shows two `ScoreRow` rows with away/home names and large scores, plus status text and a `Hide score` button.

The scoreboard is not a sport-specific grid. There is no inning/quarter/period line score model, no hits/errors display, no stronger bottom payoff treatment, and no persisted `reachedScoreboard` state. The reveal state is transient and resets with view lifecycle.

## Play-by-play stream and modes

`PlayByPlaySection` in `ScrollDownSports/Views/CatchUpSections.swift` is titled `Key Moments`. It takes raw `[PlayEntry]`, deduplicates by `periodLabel|gameClock|description`, sorts by `playIndex` then `clockText`, and filters by internal priority bands.

The current mode controls are `P1`, `P2`, and `P3`, implemented by `PlayPriorityBand`. P1 is always visible and locked. P2/P3 are expandable via local `@State` booleans. Default expansion is recalculated from a signature of play count and band counts: if P1 exists, P2/P3 collapse; if no P1, P2 opens; if no P1/P2, P3 opens. The selected/expanded mode state is not persisted.

Priority is derived locally: `scoreChanged == true` or `tier == 1` maps to P1, `tier == 2` maps to P2, and everything else maps to P3. There is no `low|medium|high|critical` event importance model, no Key/Flow/Full segmented control, no count labels like `Key 9 | Flow 29 | Full 36`, and no cross-sport mode eligibility object.

`PlayRow` renders a thin rail, a priority badge, `clockText`, the raw `description` or `playType`, optional team abbreviation, and a `Scoring` label. It does not render headline/detail/raw-feed hierarchy, raw expansion, score delta, sport-specific context, new-play separators, or period group headers. Because `PlayEntry.clockText` joins `periodLabel` and `timeLabel ?? gameClock`, duplicated labels can occur if backend fields already repeat period text.

## Stats

`PlayerStatsSection` and `TeamStatsSection` live in `ScrollDownSports/Views/CatchUpSections.swift`. Both are `DisclosureGroup` sections with local `@State private var isExpanded = false`, so they are collapsed by default and expansion is not persisted.

Player stats render as repeated `StatCard` rows containing `StatPills`. MLB batters and pitchers have dedicated pill sets; NHL skaters/goalies have dedicated pill sets; other sports use `GenericPlayerStats`, which shows up to 80 player stat cards and chooses common stat keys or selected raw stats. Team stats render each team as a `StatCard` with up to 16 normalized or raw stat pills.

There is no impact-player summary, no compact stat table component, no sport renderer boundary for stats, and no logic to collapse full stats only when long. Dense stats currently remain pill/card based.

## Pinning, progress, resume, and local persistence

There is no local persistence implementation for pins or game progress. Repo-wide search found no `UserDefaults`, `@AppStorage`, `@SceneStorage`, SwiftData, Core Data, SQLite, `lastRead`, `lastScrollOffset`, `reachedScoreboard`, or persisted selected-mode storage.

The only pin-like UI is `pinToBottom` in `GameDetailView`, which is a transient scroll-to-bottom affordance and not a persisted “follow this game” state. The home view has no pinned section and no access to any pin store.

There is no per-game `GameProgress` model, no last-read event tracking, no last viewed timestamp, no new events since last view, no resume banner, no start-over action, and no restore-by-event-id behavior. Expanded/collapsed stats sections and P2/P3 visibility are local SwiftUI state only.

## Live refresh and stream behavior

`HomeViewModel` and `GameDetailViewModel` both implement foreground auto-refresh every 5 minutes. `BackgroundDataScheduler` schedules a BG app refresh and, when invoked, fetches games only; it does not persist results or update pin/new-play state.

`GameDetailViewModel.refresh(silent:)` replaces the entire `detail` with a freshly fetched `GameDetailResponse` and updates `updateToken` on every successful refresh. `GameDetailView` only reacts to `updateToken` by scrolling to bottom when `pinToBottom` is true. If the user is not pinned to bottom, there is no explicit scroll preservation, pending-new-events count, append-vs-replace handling, near-live-edge detection, follow-live toggle, floating new-plays button, or jump-to-latest behavior.

Manual pull-to-refresh on detail calls the same fetch path. There is no separate stream mode for pinned/live games.

## Visual system and current styling

There is no centralized design system file for colors, typography, surfaces, event importance, or card variants. Styling is embedded in views.

The home screen uses a `LinearGradient` background from system background through teal and orange opacity. Cards and sections use `secondarySystemGroupedBackground`, `tertiarySystemGroupedBackground`, `regularMaterial`, `thinMaterial`, rounded rectangles, and repeated system colors. League color mapping is duplicated in `HomeView.swift` and `GameDetailView.swift`; MLB maps to `systemGreen`, NHL to `systemTeal`, NBA to orange, NFL to indigo, NCAAB to purple, NCAAF to brown. `ScrollDownSports/Resources/Assets.xcassets/AccentColor.colorset/Contents.json` also defines a green-ish accent color.

The current UI is card/list oriented and does not yet define the BRAINDUMP surface types as shared components: Game Card, Game Header Card, Event Card, Stream Control Bar, Scoreboard Card, or Stat Summary. Event cards are timeline rows rather than headline-first cards.

## Header behavior

The app currently relies on the default SwiftUI navigation bar and toolbar. `GameDetailView` sets `.navigationTitle("Catch Up")` and `.navigationBarTitleDisplayMode(.inline)`. Detail content is a `ScrollView` with `.padding(.top, 28)` and no pinned headers.

There is no custom glass header implementation in the repo. There is also no explicit opaque sticky header treatment, standardized custom nav button containers, title shrink/change logic, or content-under-header masking. Any header blur/ghosting issue would come from the platform navigation/material behavior rather than a bespoke header component.

## Tests and validation coverage

Current tests are narrow. `ScrollDownSportsTests/DecodingTests.swift` verifies decoding for game lists and detail payloads. `ScrollDownSportsTests/GameWindowTests.swift` verifies the current -7/+7 day window. There are no SwiftUI view tests, no UI automation, and no tests for scoreboard-at-bottom, top-score absence, mode labels, pin persistence, progress restore, new-play counts, live-follow scroll behavior, stats presentation, or sport-specific renderer boundaries.
