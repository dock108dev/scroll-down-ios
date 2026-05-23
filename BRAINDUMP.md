# Scroll Down Sports — Full Testing + CI Braindump
## Goal
Build a real testing and CI safety net for Scroll Down Sports so future visual/product passes stop breaking core behavior.
The app is now complex enough that manual screenshot review is not enough. We need automated tests across:
- data normalization
- game timeline ordering
- pinned games
- resume progress
- score-at-bottom behavior
- play-by-play rendering
- stats/scoreboard sections
- UI navigation
- visual regressions
- fake/mock data leakage
- accessibility
- CI quality gates
Target: **80%+ meaningful coverage where line/branch coverage makes sense**, and equivalent scenario/screen/flow coverage where traditional percentage coverage is the wrong metric.
---
# 1. Testing Philosophy
## Core rule
Do not optimize for fake green checkmarks.
Optimize for catching the kinds of bugs we are actually seeing:
- stale resume state
- duplicated innings/quarters
- raw enum labels leaking
- fake pinned games
- wrong home timeline anchor
- TBD placeholder games showing
- score revealing in the wrong place
- score not appearing during scoring plays
- floating `new` pill lingering incorrectly
- inconsistent card sizing
- bad truncation
- broken scroll restore
- duplicated team names after score is known
Coverage is useful, but only if it covers product behavior.
---
# 2. Test Pyramid
## Layer 1 — Unit tests
Fast, deterministic, high coverage.
Test pure logic:
- date grouping
- 72-hour timeline range
- home anchor selection
- placeholder/TBD filtering
- pinned-game filtering
- game progress updates
- unread/new count calculation
- period label formatting
- event type label mapping
- score progression logic
- card display-state logic
- stat formatting
- team abbreviation handling
Target:
```text
Unit test coverage: 85%+ for business/domain logic

This is where normal code coverage is most useful.

⸻

Layer 2 — Component/render tests

Test UI components with deterministic props.

Targets:

* GameCard
* HomeTimelineSection
* GameHeaderCard
* ResumeBar
* StickyProgressBar
* PlayDetailControl
* EventCard
* ScoreboardCard
* PlayerStatsSection
* TeamStatsSection
* EmptyState
* PinnedSection

Target:

Component coverage: 80%+ for rendered branches/states

This should catch bad labels, missing states, duplicate strings, and wrong conditional rendering.

⸻

Layer 3 — Integration tests

Test how state, data, and UI behavior work together.

Targets:

* open game → scroll → progress saves
* resume updates as user scrolls
* new count decreases as events are read
* reaching end clears unread count
* score remains absent from top header
* score appears after scoring events
* final score remains at bottom
* home feed anchors to recent catch-up
* pinned section only shows real pinned games
* no fake/demo games mixed into production feed

Target:

Integration coverage: cover all critical state machines and data flows

Do not worry about a line percentage here. The equivalent is state transition coverage.

⸻

Layer 4 — UI / E2E tests

Run against the app in simulator/emulator/browser depending on stack.

Critical user flows:

1. first launch
2. home feed opens around recent catch-up
3. scroll up to older games
4. scroll down to today/upcoming
5. open final game
6. verify top does not show final score
7. scroll through play stream
8. verify score appears after scoring play
9. verify final score at bottom
10. leave and return
11. resume from correct event
12. jump top/end and back to spot
13. pin/unpin real game
14. verify no fake pinned games
15. filter sport/team
16. verify TBD games hidden

Target:

E2E coverage: 100% of critical paths

For UI/E2E, do not chase 80% line coverage. The equivalent is critical flow coverage.

⸻

Layer 5 — Visual regression tests

Use screenshots to catch layout/theme/card-size regressions.

Target screens:

* home with no pinned games
* home with pinned games
* home anchored at recent catch-up
* home with live games
* home with upcoming games
* game detail top
* game detail stream
* game detail after scoring play
* game detail bottom scoreboard
* expanded player stats
* expanded team stats
* empty PBP state
* dark mode if supported
* small device width
* large accessibility text if supported

Target:

Visual coverage: approved baseline screenshots for every major screen state

This catches “everything technically works but yikes.”

⸻

Layer 6 — Accessibility tests

Minimum automated checks:

* labels exist for buttons/icons
* controls are reachable
* tap targets are large enough
* text contrast passes
* dynamic type does not destroy layout
* screen reader names are not raw enum values
* no duplicate inaccessible buttons

Target:

Accessibility: zero critical violations

⸻

3. Immediate Test Inventory Pass

Before adding new tests, find what exists.

Task

Audit the repo for existing test setup.

Search for:

__tests__/
*.test.*
*.spec.*
jest.config.*
vitest.config.*
playwright.config.*
detox.config.*
maestro/
xcuitest/
*.snap
coverage/
.github/workflows/

Also inspect package scripts:

test
test:unit
test:watch
test:coverage
lint
typecheck
e2e
ui-test
build

Output of audit

Produce a short testing inventory:

## Current Test Inventory
### Existing tools
- Unit:
- Component:
- E2E/UI:
- Visual:
- Coverage:
- CI:
### Existing tests
- Domain logic:
- Components:
- Screens:
- Flows:
### Gaps
- Resume progress:
- Home timeline anchor:
- Score-at-bottom:
- Fake data leakage:
- Period formatting:
- Raw enum mapping:
- Visual regression:

Do not start blindly adding tests until the existing structure is understood.

⸻

4. Domain Logic Tests

These are the most important first tests because they catch product bugs cheaply.

Home timeline tests

Test:

loads last 72 hours only
does not treat 72 hours as 72 days
filters TBD games
filters missing participants
orders timeline correctly
chooses recent catch-up anchor in morning
chooses pinned unread game first
chooses live game when no catch-up exists
keeps older games accessible above anchor
keeps today/upcoming below anchor

Example cases:

describe("home timeline", () => {
  it("filters out TBD placeholder games")
  it("uses 72-hour lookback, not 72 days")
  it("anchors to yesterday catch-up in the morning")
  it("keeps older catch-up above the anchor")
  it("keeps future games below the anchor")
  it("does not render fake pinned games")
})

⸻

Game progress tests

Test:

progress updates as visible event advances
progress is monotonic for final games
progress does not move backward when user scrolls up
resume uses furthestReadEventId
currentVisibleEventId is separate from furthestReadEventId
returnAnchorEventId is set before jump-to-top
returnAnchorEventId is set before jump-to-end
new count decreases as plays are read
new count clears at end of stream

Example:

describe("game progress", () => {
  it("updates furthest read event while scrolling")
  it("does not lock resume to the first event")
  it("does not move furthest read backward")
  it("calculates unread events after furthest read")
  it("clears unread count at stream end")
  it("stores return anchor before jumping to top")
})

⸻

Period formatter tests

Centralize and test.

Inputs:

MLB inning + half
NFL quarter + clock
NBA quarter + clock
NHL period
Soccer minute

Expected:

Top 1st
Bottom 6th
Q2 · 4:13
Q3 · 7:02
2nd period
67'

Explicitly test against:

1st 1st
6th 6th
Q2 Q2

Those should never appear.

⸻

Event label mapping tests

No raw enum leakage.

Test mapping:

HOME_RUN -> Home run
FIELD_OUT -> Out
FORCE_OUT -> Force out
STRIKEOUT -> Strikeout
SINGLE -> Single
DOUBLE -> Double
WALK -> Walk

Also test unknown enum fallback:

SOME_UNKNOWN_EVENT -> Other play

Never render raw SOME_UNKNOWN_EVENT.

⸻

Score progression tests

Test:

top header hides final score before user reaches bottom
scoring event shows scoreAfter
non-scoring event does not need scoreAfter
bottom scoreboard shows final score
read/scored game home card may show score
unread final game home card does not show final score

⸻

5. Component Tests

GameCard

States to cover:

scheduled real teams
live
final unread
final read
resume available
pinned
unpinned
no pinned games
score hidden
score visible after read
placeholder hidden

Assertions:

* no duplicate team names
* no ugly ellipses in core labels
* no fake demo teams
* no TBD
* no Game detail available
* no big Score at bottom banner
* no duplicated score module after read state

⸻

GameDetailHeader

Test:

* displays teams
* displays league/date/status
* does not show final score by default
* shows compact score only if user already reached scoreboard and product allows it
* no huge repeated matchup title
* no duplicate team rows

⸻

ResumeBar

Test:

* hidden when no progress
* shows correct clean period label
* updates when progress changes
* no 1st 1st
* shows Resume from 3rd
* menu contains secondary actions
* no giant duplicated buttons

⸻

StickyProgressBar

Test:

* appears after header scroll threshold
* shows current position
* top action works
* end/latest action works
* back-to-spot appears after jump
* hidden near top if redundant
* does not overlap final score or stats incorrectly

⸻

EventCard

Test:

* maps event type labels
* hides raw enums
* shows score after scoring play
* does not show final score too early
* card size/class variant consistent
* no raw High / Medium unless mapped
* raw provider text is not the only headline if generated headline exists

⸻

Stats

Test:

* impact players max 3–5
* table uses team abbreviations
* no Baltimo...
* no duplicate R/H/E blocks without added value
* columns fit expected widths
* collapsed and expanded states

⸻

6. Integration Tests

Flow 1 — Final game catch-up

Given a final game with 79 plays
When user opens the game
Then header does not show final score
And Important/Standard/All Plays control exists
When user scrolls through scoring play
Then score-after appears
When user reaches bottom
Then final score appears
And reachedScoreboard is saved

Flow 2 — Resume progress

Open final game
Scroll to 3rd inning
Leave game
Reopen game
Verify resume says 3rd
Tap resume
Verify screen returns to 3rd

Flow 3 — New count decreases

Open game with 77 unread plays
Scroll through first 20 plays
Verify unread count decreases
Reach end of stream
Verify unread count clears
Verify floating new pill disappears

Flow 4 — Top/end/back-to-spot

Open game
Scroll to 5th inning
Tap Top
Verify top visible
Verify sticky bar says Back to 5th
Tap Back to 5th
Verify 5th inning visible
Tap End
Verify final score visible
Tap Back to 5th
Verify 5th inning visible

Flow 5 — Home timeline anchor

Given current time is 9 AM
And games exist from last 72 hours
And today upcoming games exist
When home loads
Then initial viewport is recent catch-up/yesterday
When user scrolls up
Then older games appear
When user scrolls down
Then today/live/upcoming games appear

Flow 6 — Fake data prevention

Given no real pinned games
When home loads
Then pinned section is hidden
And no synthetic NFL/NBA games appear

⸻

7. UI / E2E Testing Options

Depends on the stack.

If React Native

Consider:

* Jest + React Native Testing Library for components
* Detox for simulator E2E
* Maestro for lower-friction flow testing
* Percy/Chromatic-style screenshot testing if available
* native screenshot comparison in CI if needed

If SwiftUI/iOS native

Consider:

* XCTest for unit tests
* XCUITest for UI flows
* SnapshotTesting / iOSSnapshotTestCase for visual regression
* xcodebuild test in CI
* coverage via xccov

If Expo

Consider:

* Jest + React Native Testing Library
* Maestro for app flows
* Detox if fully configured
* EAS build/test workflows if appropriate

If web/Next.js wrapper exists

Consider:

* Vitest/Jest for unit/component
* Playwright for E2E
* Playwright screenshots for visual regression
* Istanbul/nyc/c8 coverage

The agent should inspect the repo and choose based on what already exists. Do not force a new framework if the repo already has a viable one.

⸻

8. CI Pipeline

Required CI stages

1. install/cache dependencies
2. lint
3. typecheck
4. unit tests
5. component tests
6. integration tests
7. coverage report
8. build
9. UI/E2E smoke tests
10. visual regression tests
11. artifact upload

Pull request gate

PR should fail on:

* lint failure
* typecheck failure
* unit/component/integration failure
* coverage below threshold
* build failure
* critical UI smoke failure
* fake/demo data appearing in production fixture test
* raw enum labels appearing in rendered UI tests

Nightly gate

Nightly can run heavier tests:

* full E2E suite
* visual regression suite
* multiple device sizes
* accessibility scan
* performance smoke
* slow network/load state tests

⸻

9. Coverage Thresholds

Recommended thresholds

Global unit/component coverage: 80%
Domain logic coverage: 90%
Formatting/mapping utilities: 95%+
Critical state machines: 90%+
UI/E2E: critical path coverage, not line coverage
Visual: baseline scenario coverage, not line coverage
Accessibility: zero critical violations

Do not fake coverage

Exclude from coverage where appropriate:

* generated files
* DTO/type-only files
* static config
* build artifacts
* test fixtures
* mocks
* storybook/demo-only files

But do not exclude real logic just because it is hard to test. Very brave. Very useless.

⸻

10. Test Data / Fixtures

Create deterministic fixtures.

Fixture categories

final_mlb_game_full_pbp.json
final_mlb_game_scoring_progression.json
final_mlb_game_no_pbp.json
live_game_with_new_events.json
scheduled_game_real_teams.json
placeholder_tbd_game.json
pinned_games_real.json
pinned_games_empty.json
home_72h_timeline.json
stats_batting_pitching.json

Fixture rules

* no fake teams in production fixtures unless clearly marked test-only
* fake/demo teams must never appear in real app state
* all fixture files should live under test fixtures
* fixture mode must be isolated from normal app feed

Add a test that explicitly fails if known demo names appear in non-test UI/feed:

Dallas Wolves
Seattle Sound
New York Knights
Bay City Bridges

⸻

11. Visual Regression Coverage

Baseline screenshot matrix

At minimum:

Home

* no pinned games
* with real pinned games
* recent catch-up anchor
* older games above anchor
* today/upcoming below anchor
* sport filter active
* team search active
* no TBD games

Game detail

* top header
* resume bar
* sticky progress bar
* important plays mode
* standard mode
* all plays mode
* scoring play with score progression
* end of stream
* final score
* player stats expanded
* team stats expanded
* empty PBP state

Devices

* small iPhone width
* current target iPhone
* large iPhone
* large text if supported

Visual tests should catch:

* card size explosions
* repeated beige boxes
* text clipping
* ellipses in core labels
* header overlap
* floating pill over scoreboard
* duplicated controls

⸻

12. Accessibility Test Targets

Automated and manual checks:

* every button has accessible label
* pin/unpin says correct state
* refresh button labeled
* segmented control labels are clear
* no raw enum labels are read aloud
* score rows are understandable
* event cards read in logical order
* sticky bar does not trap focus
* dynamic text does not destroy layout
* contrast passes for muted text and badges

⸻

13. Performance Smoke Tests

The play stream can get long. Test it.

Cases

* 80 events
* 150 events
* live append while scrolled up
* jump to event by ID
* restore to event by ID
* stats table expansion
* repeated filter changes on home

Metrics:

* no obvious jank
* no multi-second render stall
* scroll restore works
* memory does not grow endlessly after refresh/live append

⸻

14. CI Artifacts

Every CI run should upload useful artifacts on failure:

* coverage report
* test results
* E2E screenshots
* visual diff screenshots
* simulator logs
* failing fixture name
* rendered accessibility tree if available

A failed UI test without screenshots is basically a fortune cookie with stack traces.

⸻

15. Implementation Order

Phase 1 — Test inventory and CI baseline

Goal:

Know what exists and make CI run it.

Tasks:

* inspect current test setup
* document existing scripts/tools
* add missing CI workflow if absent
* run lint/typecheck/test/build in CI
* upload coverage artifact
* set initial coverage reporting without strict gate if repo is far below target

Exit criteria:

* CI runs on PR
* current tests are visible
* coverage report exists
* failures block merge for basic checks

⸻

Phase 2 — Domain tests for broken product logic

Goal:

Lock down the recurring bugs.

Add tests for:

* 72-hour timeline
* initial home anchor
* TBD filtering
* fake pinned game prevention
* period formatting
* event label mapping
* score progression
* resume progress
* unread count

Exit criteria:

* core logic covered
* duplicated period bug has a test
* raw enum leakage has a test
* fake pinned games have a test
* stale resume has a test

⸻

Phase 3 — Component tests

Goal:

Catch bad rendered states.

Add tests for:

* GameCard
* ResumeBar
* StickyProgressBar
* EventCard
* ScoreboardCard
* Stats tables

Exit criteria:

* rendered output does not include raw enums
* cards render expected states
* read/scored cards are compact
* stats do not truncate core labels

⸻

Phase 4 — Integration tests

Goal:

Cover cross-component behavior.

Add tests for:

* open → scroll → save progress → reopen
* scoring play shows score progression
* final score at bottom
* home anchor behavior
* jump top/end/back-to-spot
* new count decreases

Exit criteria:

* product behavior covered end-to-end at state/UI integration level

⸻

Phase 5 — UI/E2E tests

Goal:

Cover critical user flows in simulator.

Start with 5 smoke tests:

1. home opens around recent catch-up
2. no fake pinned games
3. open final game and no top score
4. scroll to final score at bottom
5. resume from later inning after leaving/reopening

Then expand.

Exit criteria:

* CI can run smoke UI tests
* screenshots are captured on failure
* critical flows are protected

⸻

Phase 6 — Visual regression

Goal:

Stop “technically correct but visually awful” regressions.

Add baselines for:

* home
* game detail top
* stream
* stats
* final score

Exit criteria:

* visual diffs show in CI
* baseline updates are explicit
* major layout regressions fail PR

⸻

Phase 7 — Enforce thresholds

Goal:

Move from visibility to enforcement.

Suggested progression:

Week 1: report only
Week 2: 70% global gate
Week 3: 80% global gate
Immediately: 90%+ gate for new domain utilities

Do not block early if the repo has no tests yet, but do block regressions after baseline is established.

⸻

16. One-Shot Agent Prompt

Goal

Build a full testing and CI safety net for Scroll Down Sports.

The app now has enough product complexity that we need automated validation across unit tests, component tests, integration tests, UI/E2E tests, visual regression, and coverage reporting.

Target 80%+ meaningful coverage where code coverage applies, and equivalent critical-flow/screen-state coverage where line coverage is not the right metric.

First step

Audit the repo before changing anything.

Find:

* existing test framework
* package scripts
* CI workflows
* coverage config
* UI/E2E tooling
* visual/snapshot tooling
* existing tests
* fixture data

Produce a short inventory in the PR summary.

Required CI pipeline

Add or update CI to run:

1. dependency install/cache
2. lint
3. typecheck
4. unit tests
5. component tests
6. integration tests
7. coverage report
8. build
9. UI/E2E smoke tests if tool exists or can be added cleanly
10. upload artifacts on failure

Required test coverage areas

Domain logic

Add tests for:

* 72-hour timeline range
* home initial anchor selection
* TBD/placeholder filtering
* fake pinned game prevention
* pinned games from real data only
* period/quarter/inning formatting
* no duplicate labels like 1st 1st
* event type display mapping
* no raw enum labels like FIELD_OUT
* score progression during scoring plays
* final score at bottom behavior
* resume progress updates while scrolling
* unread/new count calculation
* return anchor for top/end/back-to-spot

Components

Add tests for:

* GameCard
* GameDetailHeader
* ResumeBar
* StickyProgressBar
* PlayDetailControl
* EventCard
* ScoreboardCard
* PlayerStatsSection
* TeamStatsSection

Assertions should check:

* no raw backend enum strings
* no fake demo teams
* no TBD games by default
* no duplicate team-name blocks after score is known
* no ugly team truncation in stat tables
* proper compact/read state
* proper score-hidden/score-visible state

Integration

Add tests for:

* opening final game without top score
* scrolling through scoring event and seeing score-after
* reaching bottom final score
* resume after leaving/reopening
* new count decreasing as plays are read
* jump top/end/back-to-spot
* home anchor around recent catch-up
* older games above anchor and future games below

UI/E2E

Add simulator smoke tests for:

* home loads
* no fake pinned games
* no TBD placeholders
* open final game
* no score at top
* score appears in stream after scoring play
* final score at bottom
* resume updates after scrolling
* sticky top/end/back-to-spot works

Visual regression

Add screenshot baselines for:

* home no pinned
* home with real pinned
* home anchored at recent catch-up
* game detail top
* play stream
* scoring event
* stats expanded
* final score
* small device width

Coverage gates

Use these targets:

* domain logic: 90%+
* utility formatters/mappers: 95%+
* unit/component global: 80%+
* integration: critical state-machine coverage
* UI/E2E: critical path coverage
* visual: major screen-state coverage
* accessibility: zero critical violations

If current coverage is far below target, introduce gates in phases:

1. report only
2. prevent coverage decrease
3. enforce 70%
4. enforce 80%
5. enforce stricter thresholds for new files/domain logic

Fixture rules

Create deterministic fixtures for:

* final MLB full PBP
* final MLB scoring progression
* live game with new events
* scheduled real teams
* placeholder TBD game
* home 72-hour timeline
* pinned real games
* no pinned games
* stats data

Fake/demo teams must never appear in real app state.

Add a test that fails if these names render outside test/demo mode:

* Dallas Wolves
* Seattle Sound
* New York Knights
* Bay City Bridges

Validation checklist

Before completing:

1. CI runs on PR.
2. Coverage report is generated.
3. Domain tests cover 72-hour timeline and resume progress.
4. Component tests catch raw enum labels.
5. Integration tests cover score-at-bottom and score progression.
6. UI smoke tests open the app and navigate a game.
7. Visual baselines exist for major screens.
8. Fake/demo games cannot leak into normal UI.
9. TBD placeholder games are hidden by default.
10. 1st 1st / duplicate period labels are covered by tests.
11. Resume updates as user scrolls.
12. New count decreases as user reads.
13. Final score remains at bottom.
14. Artifacts are uploaded on CI failure.
15. Test commands are documented in README or a testing doc.

Expected outcome

After this work, future agents should not be able to “successfully” ship a pass that:

* adds fake games
* breaks resume
* leaks raw enums
* duplicates innings
* starts home at the wrong anchor
* shows TBD games
* hides score progression
* bloats cards
* breaks final-score placement

without CI catching it.

# Short operational version
Build the safety net in this order:
```text
1. Inventory existing tests/CI
2. Add CI baseline
3. Add domain tests for known bugs
4. Add component tests for rendered states
5. Add integration tests for scroll/progress/score behavior
6. Add UI smoke tests
7. Add visual regression
8. Ratchet coverage to 80%+

The biggest risk is chasing generic coverage while missing the actual product failures. Test the product rules first; coverage follows.