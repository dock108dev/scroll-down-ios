# Scroll Down Sports — Complete Product + Visual Braindump
## Context
The current app is functionally headed in the right direction, but the visuals and product model need a major upgrade.
The app should not feel like a generic sports data list. It should feel like a **persistent sports stream** where users can pin games, follow live play-by-play, catch up from where they left off, and scroll down through the game story until they reach the scoreboard/result at the bottom.
This is not just an MLB app. MLB is the first proof point, but the foundation needs to work across sports.
The current visuals are too flat, too generic, too much like raw data/debug UI, and not enough like a polished sports product.
---
# 1. Product North Star
## What the app is
**Scroll Down Sports is a sports catch-up and live-follow app where the user scrolls through the game story.**
The scoreboard/result belongs at the bottom.
The interaction itself creates the suspense:
> If the user wants the result, they scroll down to it.  
> If they want the story, they consume the play-by-play on the way.
No artificial spoiler-gating is required as long as the UI respects this layout.
## Core experience
A user should be able to:
1. Open the app.
2. See today’s games.
3. Pin a game they care about.
4. Open a game and scroll through the PBP/story.
5. Leave the game.
6. Come back later and resume exactly where they stopped.
7. See how many new plays happened since they left.
8. Stream live PBP without the app hijacking their scroll.
9. Reach the bottom to see the scoreboard/result/stats.
---
# 2. Core Product Invariants
These should be treated as design and engineering rules.
## Invariant 1 — Scoreboard at the bottom
The top of a game page should not reveal the final score by default.
The scoreboard/result lives at the bottom of the scroll.
Valid top states:
```text
ATL vs MIA
Final · Catch up available
36 plays
Score at bottom

Invalid top state:

ATL 9
MIA 3

Exception:

If the user has already reached the scoreboard before, we can optionally allow future opens to show the score. But the default product behavior should preserve the scroll-down experience.

⸻

Invariant 2 — Remember the user’s place

Every game should remember:

* last read event
* last scroll position
* selected view mode
* whether the scoreboard was reached
* expanded/collapsed sections
* whether the game is pinned
* last viewed timestamp
* new events since last view

This is not a bonus feature. This is core to the app.

⸻

Invariant 3 — Pinning is first-class

Pinning a game should mean:

* game appears in a pinned section
* user can resume quickly
* new play count is tracked
* live games can stream updates
* pinned games remain easy to find after leaving the screen

A pin is not just a saved icon state. It is a lightweight “follow this game” mode.

⸻

Invariant 4 — Live streams must not hijack the user

If the user is reading older plays and new PBP arrives, the screen should not jump.

Behavior:

If user is near live edge and Follow Live is ON:
  append new plays and keep user at live edge.
If user has scrolled up:
  append new plays silently.
  show "8 new plays" floating button.
  only jump when user taps it.

No surprise teleporting.

⸻

Invariant 5 — All-sports foundation

MLB can ship first, but the model cannot be baseball-only.

Core app language should use generic sports terms:

* game
* event
* moment
* period
* clock
* score state
* timeline
* stream
* stats
* scoreboard
* pin
* progress

Baseball-specific concepts like innings, outs, count, bases, and pitchers should live in baseball renderers/adapters.

⸻

3. Current Visual Problems

Problem A — Too generic

The screenshots currently feel like:

iOS list + white cards + green accent + sports data

That is clean, but it is not memorable.

It could be a health app, calendar app, CRM, or habit tracker.

The app needs a sports-native identity.

⸻

Problem B — Too much green

Green is being used for:

* MLB label
* section titles
* game card rail
* icons
* borders
* stats headings
* timeline accents

This makes the whole product feel like a generic “green app” instead of a sports app.

Green should be used intentionally, not everywhere.

Suggested use:

* league/sport accent
* success/live state where appropriate
* small metadata
* not every heading/card/border

⸻

Problem C — Raw feed prose dominates

The PBP currently reads like raw MLB API text dumped into a mobile list.

Example:

Michael Harris II homers (10) on a fly ball to center field. Ronald Acuña Jr. scores.

That is accurate, but not good product copy.

Better:

2-run homer
Michael Harris II sends one to center.
Acuña scores.
ATL · Top 1st

Raw feed text can exist, but it should be secondary/detail text.

⸻

Problem D — P1/P2/P3 is internal language

The current P1, P2, P3 mode chips feel like debug tiers.

Replace with user-facing modes:

Key Moments
Game Flow
Full Play-by-Play

or shorter:

Key
Flow
Full

These modes work across sports.

⸻

Problem E — Player stats are too bulky

The player stat screen is a wall of identical stat pills.

That makes every player look equally important.

Instead:

1. Show impact players first.
2. Then show compact stat tables.
3. Let full stats be expandable.

Pills are useful for highlights. They are bad for dense data.

⸻

Problem F — Header blur looks broken

The glass header currently allows background text to ghost behind the nav/title area. It makes screenshots look accidentally broken.

Fix:

* use an opaque or mostly opaque sticky header
* reduce blur
* ensure content cannot visibly pass behind title/buttons
* standardize nav button size/spacing
* handle scroll transitions deliberately

⸻

4. Updated Visual Direction

Desired feel

The app should feel like:

modern sports reader
+ live game stream
+ scoreboard tape
+ collectible game card
+ old-school sports-page hierarchy

Not:

generic iOS list with sports data

Good references conceptually

Do not copy directly, but borrow principles from:

* Apple Sports: clean, restrained hierarchy
* The Athletic: strong editorial hierarchy
* MLB/NBA/NFL gamecast: event structure
* old stadium scoreboards: bottom scoreboard treatment
* baseball cards / program sheets: team/player presentation
* live blogs: persistent stream + new update behavior

Visual metaphor

The app should feel like a vertical sports tape.

The user scrolls through:

Game setup
↓
Early action
↓
Middle-game context
↓
Turning points
↓
Late-game finish
↓
Scoreboard/result

The verticality is the product.

⸻

5. Design System Reset

Before tweaking individual screens, define the shared design language.

Colors

Base palette

Use a warmer, more deliberate base:

Background: off-white / warm paper / very light gray
Primary text: near-black or dark navy
Secondary text: muted gray
Card background: white or slightly elevated warm white
Borders: subtle neutral

Event colors

Use event colors based on meaning:

Scoring: gold/orange
Live/new: red or bright accent
Pitching/defense: teal/blue
Critical/late drama: crimson
Neutral event: gray/navy
Final: dark scoreboard tone

Team colors

Team colors should be used carefully:

* small accent rail
* team abbreviation chip
* moment ownership indicator
* scoreboard row
* not giant full-card backgrounds by default

Sport colors

Each sport may have a subtle identity color, but the app should not be hardcoded as “green MLB app.”

⸻

Typography

Current type is too large and too uniform.

Suggested hierarchy:

Element	Treatment
App title	bold, restrained
Section title	22–28, bold
Team names	22–30, bold
Game metadata	12–14, muted
Moment headline	18–22, semibold/bold
Moment detail	15–17, regular
Raw feed text	13–15, muted
Stats table	13–15, compact
Status pill	11–13, uppercase or semibold

The PBP should not feel like reading giant paragraphs.

⸻

Surfaces

Define these shared surface types:

1. Game Card

Used on home screen and pinned games.

Must support:

* scheduled
* live
* final
* pinned
* resume available
* new plays
* catch-up available
* score hidden by default
* sport-neutral metadata

2. Game Header Card

Used at top of game detail screen.

Must support:

* teams
* sport/league
* date/time
* status
* catch-up metadata
* pinned state
* score-at-bottom note
* no final score by default

3. Event Card

Used in the PBP stream.

Must support:

* sport-specific metadata
* event type
* importance
* headline
* detail
* team ownership
* score delta if appropriate
* raw feed expansion
* timestamp/period

4. Stream Control Bar

Used near top of detail screen.

Must support:

* pin/unpin
* follow live on/off
* resume
* jump to latest
* new play count
* selected mode

5. Scoreboard Card

Always near bottom.

Must support:

* sport-specific scoreboard
* final/current score
* box score/grid where applicable
* stats summary
* reached-scoreboard progress update

6. Stat Summary

Used after stream but before scoreboard or near bottom.

Must support:

* impact players
* team stat summary
* full expandable tables

⸻

6. Home Screen Redesign

Current issue

The current home screen shows games, but it does not give the user enough reason to care or understand what to do next.

Cards look too identical.

Desired structure

Scroll Down
Pinned
[game]
[game]
Today
[game]
[game]
[game]
Earlier
[game]
[game]

If there are no pinned games, omit the pinned section.

Home game card requirements

Each card should answer:

* What sport/league is this?
* Who is playing?
* Is it scheduled/live/final?
* Can I catch up?
* Did I already start this game?
* Are there new plays?
* Is this pinned?
* Is the score hidden until bottom?

Example card states

Scheduled

MLB · 6:40 PM
STL    St. Louis Cardinals
CIN    Cincinnati Reds
Catch up available at first pitch

Live, unpinned

LIVE · 6th
CLE    Cleveland Guardians
PHI    Philadelphia Phillies
Open stream

Live, pinned

PINNED · LIVE · 6th
CLE    Cleveland Guardians
PHI    Philadelphia Phillies
12 new plays · Resume from 4th

Final, not started

FINAL
ATL    Atlanta Braves
MIA    Miami Marlins
Catch up · 36 plays · Score at bottom

Final, partially read

FINAL
ATL    Atlanta Braves
MIA    Miami Marlins
Resume from 7th · Score at bottom

Final, scoreboard already reached

FINAL
ATL    Atlanta Braves
MIA    Miami Marlins
Viewed · Open recap

Score can be shown only if we choose to allow score visibility after the user has already reached the bottom.

⸻

7. Pinned Games

Pin behavior

Pinning should persist locally for MVP.

When a game is pinned:

* appears in pinned section
* tracks last-read event
* tracks new event count
* can be unpinned
* can stream live updates
* remains available after final
* can still be resumed after final

Pin icon

The current pin icon is okay as a starting affordance, but active/inactive state needs to be obvious.

Possible active treatment:

* filled pin icon
* pinned badge on card
* pinned section
* subtle card emphasis

Pinned game object

type PinnedGame = {
  gameId: string
  sport: Sport
  pinned: boolean
  pinnedAt: string
  lastViewedAt?: string
  lastReadEventId?: string
  lastReadEventIndex?: number
  lastScrollOffset?: number
  newEventCount: number
  followLiveEnabled: boolean
}

⸻

8. Remembering Game Progress

Why this matters

This is one of the most important product behaviors.

The app is called Scroll Down. If the user scrolls through a game, leaves, and comes back to the top every time, the whole thing feels broken.

Store per-game progress

type GameProgress = {
  gameId: string
  sport: Sport
  lastReadEventId?: string
  lastReadEventIndex?: number
  lastScrollOffset?: number
  selectedMode: "key" | "flow" | "full"
  expandedSectionIds: string[]
  reachedScoreboard: boolean
  scoreboardReachedAt?: string
  lastViewedAt: string
  updatedAt: string
}

Resume rules

When opening a game:

1. If no progress exists, start at the top.
2. If progress exists and scoreboard was not reached, show resume banner.
3. If new events exist, show new count.
4. If the game is live and pinned, offer resume or jump latest.
5. If scoreboard was reached, open normally or optionally show viewed state.

Resume banner

Resume from Top 5th
11 new plays since you left.
[Resume] [Jump to Latest] [Start Over]

Important restore behavior

Prefer restoring by eventId over raw pixel offset where possible.

Pixel offsets can become stale if:

* new events arrive
* text wraps differently
* device size changes
* mode changes
* stats load later

Better approach:

Scroll to lastReadEventId.
Then apply small offset adjustment if needed.

⸻

9. Live PBP Streaming

Two modes

Catch-up mode

Used for final or in-progress games where the user is reading history.

Stream mode

Used for pinned/live games where events continue arriving.

Follow Live behavior

type FollowLiveMode = {
  enabled: boolean
  userNearLiveEdge: boolean
  pendingNewEvents: number
}

Rules:

If Follow Live is ON and user is near live edge:
  append new events and keep user attached to latest.
If user scrolls away from live edge:
  pause auto-follow.
  show new plays button.
If user taps Jump to Latest:
  scroll to latest event.
  clear pending count.
  re-enable live edge tracking.

Floating new events button

8 new plays
Jump to latest

This should appear above the bottom area, not over important text.

Refresh behavior

Manual refresh should:

* fetch new events
* preserve scroll position
* update new count
* not reset the stream

⸻

10. Game Detail Screen Redesign

Current issue

The current catch-up screen is too much like:

header card
key moments list
stats
box score

It needs to become:

game header
stream controls
sports story stream
supporting stats
scoreboard at bottom

Proposed structure

Sticky Header
- Back
- Title
- Pin
- Refresh
Game Header Card
- league/sport
- teams
- date/status
- catch-up/live metadata
- no top score by default
Stream Control Bar
- Key / Flow / Full
- Follow Live toggle if live
- Resume / Jump Latest if relevant
Game Stream
- grouped by period/inning/quarter
- event cards
- importance styling
- new play separators
Stats Summary
- impact players
- team stat highlights
- expandable full stats
Scoreboard / Box Score
- final/current score
- sport-specific scoreboard

⸻

11. Timeline / Stream Modes

Replace current mode chips.

Recommended labels

Key
Flow
Full

Expanded descriptions:

Key

Major events only.

Examples:

* scoring plays
* lead changes
* late-game swing
* major turnover
* red card
* goal
* home run
* game-ending play

Flow

Enough events to understand the game.

Examples:

* scoring plays
* threats
* key outs/stops
* possession changes
* important drives
* momentum swings

Full

Every play/event.

This is the live PBP stream mode.

UI treatment

Current chips should become cleaner segmented controls.

Example:

Key 9 | Flow 29 | Full 36

No P1/P2/P3.

⸻

12. Event Card Design

Current issue

Events are mostly raw text rows with small chips.

Need headline-first sports cards.

Generic event card anatomy

[Period / Clock] [Team] [Event Type]
Headline
Description / supporting detail
Optional:
- score delta
- possession/base/field context
- raw feed expand

Baseball scoring example

Top 1st · ATL
2-run homer
Michael Harris II sends one to center.
Acuña scores.
ATL +2

Baseball non-scoring example

Bottom 4th · MIA
Double play ends the threat
Otto Lopez grounds into two.
Edwards out at second, Lopez out at first.

Football example

Q4 · 2:14 · DAL 42
3rd & 7 conversion
Prescott finds Lamb across the middle.
Drive stays alive.

Basketball example

Q3 · 4:22
12–2 run
Boston flips the quarter with three straight stops.

Soccer example

67'
Goal
Liverpool finally break through after sustained pressure.

Hockey example

P2 · 08:13
Power-play goal
Toronto cashes in before the penalty expires.

⸻

13. Event Importance

Every event should have importance.

type EventImportance = "low" | "medium" | "high" | "critical"

Visual impact:

Importance	Treatment
low	compact row
medium	normal event card
high	emphasized headline/card
critical	larger card, stronger color, possible animation/haptic

This prevents every strikeout, single, timeout, and substitution from looking equally important.

⸻

14. Period Grouping

The stream should be grouped by sport-specific periods.

Examples:

MLB: Top 1st, Bottom 1st, Top 2nd...
NFL: Q1, Q2, Halftime, Q3...
NBA: Q1, Q2, Q3, Q4...
NHL: Period 1, Period 2...
Soccer: First Half, Second Half, Stoppage...
Golf: Round 1, Hole 7...
Tennis: Set 1, Game 4...

Use a generic period model:

type GamePeriod = {
  id: string
  label: string
  sortOrder: number
  sportMetadata?: Record<string, unknown>
}

⸻

15. Stats Redesign

Current issue

Player stats are too large and repetitive.

New hierarchy

Stats should come after the stream, near the bottom.

Order:

Impact Players
Team Stats
Full Player Stats
Scoreboard

Or:

Impact Players
Scoreboard
Full Stats

Depending on sport.

Impact Players

Show only the players who mattered.

Example:

Impact Players
Kyle Stowers
2 HR · 2 RBI · 2 R
Michael Harris II
2 HR · 3 RBI
Ronald Acuña Jr.
2 R · 1 RBI

Full stats

Use compact tables.

Baseball example:

Player              AB  H  R  RBI  HR  BB  K
Kyle Stowers         4  2  2   2   2   0  2
Christopher Morel    3  1  0   0   0   1  2

Football example:

Passing             C/ATT  YDS  TD  INT
Jalen Hurts          21/29  244   2   0

Basketball example:

Player              PTS  REB  AST  STL  BLK
Tatum                31    8    5    1    1

Dense stats belong in tables, not large pill grids.

⸻

16. Scoreboard at Bottom

The bottom scoreboard should feel intentional

This is the payoff.

It should be visually stronger than the current plain score card.

MLB scoreboard

Preferred if inning data is available:

        1  2  3  4  5  6  7  8  9   R  H  E
ATL     2  1  0  0  2  0  1  0  3   9 12  0
MIA     0  0  1  1  0  0  0  1  0   3  7  1

Fallback:

        R  H  E
ATL     9 12  0
MIA     3  7  1

Other sports

Football:

        Q1 Q2 Q3 Q4  F
DAL      7  3  7  0 17
PHI      3 14  0  7 24

Basketball:

        Q1 Q2 Q3 Q4  F
BOS     28 24 31 26 109
MIA     24 29 20 22  95

Soccer:

LIV 2
ARS 1
Goals:
23' Salah
61' Saka
84' Núñez

Golf needs a leaderboard-style result instead of a two-team scoreboard.

⸻

17. All-Sports Architecture

Core types

Use sport-neutral core types.

type Sport =
  | "mlb"
  | "nfl"
  | "nba"
  | "nhl"
  | "soccer"
  | "golf"
  | "tennis"
  | "other";
type Game = {
  id: string
  sport: Sport
  league: string
  status: "scheduled" | "live" | "final" | "postponed" | "cancelled"
  startTime: string
  participants: GameParticipant[]
  eventCount?: number
  keyEventCount?: number
  flowEventCount?: number
  hasCatchUp: boolean
  isPinned?: boolean
  userProgress?: GameProgress
}
type GameParticipant = {
  id: string
  name: string
  abbreviation: string
  role?: "home" | "away" | "player" | "team"
  colors?: {
    primary?: string
    secondary?: string
  }
}
type GameEvent = {
  id: string
  gameId: string
  sport: Sport
  sequence: number
  periodId: string
  periodLabel: string
  clockLabel?: string
  teamId?: string
  teamAbbr?: string
  eventType: string
  importance: "low" | "medium" | "high" | "critical"
  modeEligibility: {
    key: boolean
    flow: boolean
    full: boolean
  }
  headline: string
  description?: string
  rawDescription?: string
  scoreBefore?: ScoreState
  scoreAfter?: ScoreState
  scoreDelta?: ScoreDelta
  metadata?: Record<string, unknown>
}
type ScoreState = {
  participants: {
    participantId: string
    score: number
  }[]
}
type ScoreDelta = {
  participantId: string
  points: number
  label?: string
}

⸻

18. Sport Renderers

Each sport should own its own display logic.

type SportRenderer = {
  renderGameCard(game: Game): ReactNode
  renderGameHeader(game: Game): ReactNode
  renderEvent(event: GameEvent): ReactNode
  renderScoreboard(game: Game): ReactNode
  renderStats(game: Game): ReactNode
}

Initial implementation can use shared components with sport-specific helpers.

Baseball renderer owns

* innings
* top/bottom labels
* bases
* count
* outs
* batting/pitching stats
* inning box score

Football renderer owns

* quarters
* drives
* down/distance
* yard line
* possession
* scoring summary

Basketball renderer owns

* quarters
* clock
* runs
* possession if available
* player/team stat leaders

Soccer renderer owns

* minute
* stoppage
* goals/cards/subs
* aggregate/extra time where relevant

Golf renderer owns

* tournament/round/hole
* leaderboard
* player score to par
* shot-level or hole-level events

This prevents baseball assumptions from leaking everywhere.

⸻

19. Backend/Data Enrichment Needed

The frontend should not have to infer everything from raw play strings.

Add presentation-friendly fields server-side or in a normalization layer.

For each event

type PresentedEvent = {
  id: string
  gameId: string
  sport: Sport
  sequence: number
  periodLabel: string
  clockLabel?: string
  teamAbbr?: string
  teamName?: string
  eventType: string
  importance: "low" | "medium" | "high" | "critical"
  headline: string
  description: string
  rawDescription: string
  belongsToModes: {
    key: boolean
    flow: boolean
    full: boolean
  }
  scoreBefore?: ScoreState
  scoreAfter?: ScoreState
  scoreDelta?: ScoreDelta
  metadata?: Record<string, unknown>
}

For each game

type GamePresentation = {
  gameId: string
  sport: Sport
  league: string
  status: "scheduled" | "live" | "final"
  participants: GameParticipant[]
  startTime: string
  catchUpAvailable: boolean
  eventCounts: {
    key: number
    flow: number
    full: number
  }
  displayLabels: {
    status: string
    primaryAction: string
    secondaryContext?: string
  }
  scoreboardPlacement: "bottom"
}

For game progress

This can start locally.

type LocalGameProgress = {
  gameId: string
  sport: Sport
  selectedMode: "key" | "flow" | "full"
  lastReadEventId?: string
  lastReadEventSequence?: number
  lastScrollOffset?: number
  reachedScoreboard: boolean
  updatedAt: string
}

⸻

20. Specific Fixes from Current Screenshots

Home screen

Current:

* cards are too samey
* all cards have similar green rail
* live games do not feel alive
* catch-up text is passive
* no pin/resume/new-play state
* no visual reason to choose one game over another

Fix:

* introduce pinned section
* stronger live badges
* sport/league label
* resume/new play labels
* score-at-bottom indicator
* varied state-specific card styling

⸻

Catch-up timeline

Current:

* P1/P2/P3 is unclear
* 1st 1st duplication looks broken
* long raw play text dominates
* scoring moments are not special enough
* timeline rail is thin/generic
* game story lacks pacing

Fix:

* rename modes to Key / Flow / Full
* fix period labels
* convert raw descriptions to headline + detail
* use event importance styling
* group by period
* scoring/critical moments get stronger treatment
* raw feed text hidden behind details/expand

⸻

Player stats

Current:

* giant repeated pill wall
* too much vertical space
* no impact hierarchy
* every player looks equally important

Fix:

* show impact players first
* compact full stat table
* use pills only for standout stats
* collapse full stats by default if long

⸻

Box score

Current:

* visually too plain
* score at bottom is correct direction but needs more payoff

Fix:

* scoreboard grid
* sport-specific table
* stronger final/current state
* team color rows
* stats summary nearby

⸻

Header

Current:

* ghosted text behind nav/title looks broken
* nav buttons float but not in a polished way

Fix:

* opaque or mostly opaque sticky header
* consistent nav icon containers
* avoid blurred text behind controls
* title can shrink/change on scroll

⸻

21. Interaction Details

Opening a game

From home:

* tap card
* open game detail
* if progress exists, restore/resume
* if no progress, start at top
* if pinned/live, enable stream behavior

Pinning

* user taps pin
* game enters pinned section
* local pinned state saved
* pinned card shows resume/new plays

Refreshing

Manual refresh:

* fetch latest game/events
* preserve scroll
* update new play count
* do not jump

New event streaming

When new PBP arrives:

* append to data source
* if user at live edge, follow
* otherwise show floating new count

Reaching scoreboard

When scoreboard enters viewport:

* set reachedScoreboard = true
* optionally mark game as “viewed”
* future home card may show viewed/open recap state

Start over

User can reset progress:

* clears last read event
* clears scroll position
* does not unpin
* does not clear scoreboard reached unless explicitly intended

⸻

22. Visual Polish Ideas

Sports tape timeline

The stream should feel like a continuous sports tape.

Ideas:

* subtle vertical rail
* period dividers
* event cards attached to rail
* thicker rail for high-importance stretches
* team-color dots/markers
* “new plays” separator

New plays separator

— 8 new plays since you left —

Live edge marker

Live Edge

Bottom payoff marker

Before scoreboard:

End of stream
Scoreboard below

Then show scoreboard.

Haptics

Small haptics only for:

* pin/unpin
* jump to latest
* scoring event reveal if animated
* reaching live edge

Do not overdo this.

Motion

Motion should reinforce state changes:

* card expands into game detail
* new plays slide in
* jump-to-latest scrolls smoothly
* score delta pulses lightly
* pin icon snaps/fills

No casino nonsense.

⸻

23. MVP Implementation Plan

Phase 1 — Product behavior reset

Goal:

Make the app behave like Scroll Down Sports, not generic sports recap.

Tasks:

* move final/current scoreboard to bottom only
* remove top-score assumptions
* rename modes from P1/P2/P3 to Key/Flow/Full
* add local game progress persistence
* restore last-read event on open
* add reachedScoreboard tracking
* preserve scroll on refresh
* add basic pin/unpin persistence

Exit criteria:

* user can open a game, scroll halfway, leave, return, and resume
* scoreboard is not shown at top by default
* mode labels are user-facing
* pinned games persist locally

⸻

Phase 2 — Home screen rebuild

Goal:

Make the entry point feel like a real sports app.

Tasks:

* add pinned section
* add state-specific game cards
* show resume state
* show new play count
* show live/final/scheduled states clearly
* show score-at-bottom label for final games
* reduce generic green styling

Exit criteria:

* pinned games appear first
* live games are visually distinct
* final catch-up games say score is at bottom
* user can tell where they left off

⸻

Phase 3 — Game detail stream rebuild

Goal:

Make the game page feel like a sports story stream.

Tasks:

* build stream control bar
* implement Key/Flow/Full segmented control
* group events by period
* convert event rows to event cards
* add headline/detail/raw-feed hierarchy
* add importance styling
* add new plays button
* add live edge behavior
* add scoreboard bottom section

Exit criteria:

* timeline no longer feels like raw database rows
* scoring/key events stand out
* live updates do not hijack scroll
* user can jump to latest

⸻

Phase 4 — Stats and scoreboard polish

Goal:

Make stats useful without overwhelming the stream.

Tasks:

* replace player stat pill wall
* add impact players section
* add compact full stats table
* add sport-specific scoreboard card
* add MLB inning grid where data exists
* move stats near bottom

Exit criteria:

* Kyle Stowers-type performances pop
* full stats are readable and compact
* scoreboard feels like payoff, not an afterthought

⸻

Phase 5 — All-sports renderer abstraction

Goal:

Avoid MLB-only architecture.

Tasks:

* define sport-neutral Game, GameEvent, GameProgress
* add sport renderer interface
* move baseball-specific display logic into baseball renderer
* ensure home cards work for all sports
* ensure timeline modes are sport-neutral
* ensure scoreboard is sport-specific

Exit criteria:

* adding NFL/NBA/etc. does not require rewriting core screens
* baseball metadata does not leak into generic components
* all sports can use pin/progress/live stream behavior

⸻

Phase 6 — Visual identity pass

Goal:

Make the app look exponentially better.

Tasks:

* define color tokens
* define typography scale
* define card surfaces
* define event importance styles
* define pinned/live/final states
* polish sticky header
* add subtle motion
* reduce overuse of green
* add sport-native scoreboard styling

Exit criteria:

* screenshots no longer look like a generic iOS list
* app has a recognizable sports product identity
* important events are visually obvious
* the stream feels intentional and polished

⸻

24. Acceptance Criteria

Product behavior

* Any game can be pinned.
* Pinned games persist.
* Pinned games show at top of home.
* User progress is saved per game.
* User can resume where they left off.
* App tracks new plays since last view.
* Live PBP can stream down the page.
* New plays do not hijack scroll.
* User can jump to latest.
* Scoreboard/result is at bottom.
* Final score is not shown at top by default.

Visuals

* App feels sports-native.
* Home cards are state-aware and visually distinct.
* Catch-up page feels like a game stream, not a raw log.
* Event hierarchy is clear.
* Key moments stand out.
* Full PBP remains readable.
* Stats are compact.
* Scoreboard feels like a payoff.
* Header no longer has ghosted content behind it.
* Green is no longer overused.

Architecture

* Core UI is sport-neutral.
* Sport-specific rendering is isolated.
* MLB works first.
* Other sports can be added through adapters/renderers.
* Progress/pin/live behavior works across all sports.

⸻

25. Testing Plan

Manual scenarios

Scenario 1 — First open, final game

1. Open app.
2. Tap final game.
3. Confirm top does not show final score.
4. Scroll through game.
5. Confirm scoreboard appears at bottom.
6. Leave game.
7. Reopen game.
8. Confirm resume behavior.

Scenario 2 — Partial read

1. Open final game.
2. Scroll halfway.
3. Leave.
4. Reopen.
5. Confirm resume banner appears.
6. Tap resume.
7. Confirm position restores.

Scenario 3 — Pin live game

1. Open live game.
2. Tap pin.
3. Return home.
4. Confirm game appears in pinned section.
5. Simulate new events.
6. Confirm new event count appears.

Scenario 4 — Live stream while reading

1. Open pinned live game.
2. Scroll up away from latest.
3. Simulate new events.
4. Confirm screen does not jump.
5. Confirm “new plays” button appears.
6. Tap jump latest.
7. Confirm latest event visible.

Scenario 5 — Refresh

1. Open game.
2. Scroll to middle.
3. Tap refresh.
4. Confirm scroll does not reset.
5. Confirm new plays are appended or counted.

Scenario 6 — Mode switching

1. Open game.
2. Switch Key/Flow/Full.
3. Confirm mode persists.
4. Leave and return.
5. Confirm selected mode restores.

Scenario 7 — Scoreboard reached

1. Open final game.
2. Scroll to scoreboard.
3. Confirm reachedScoreboard is set.
4. Return home.
5. Confirm card can show viewed/open recap state.

⸻

26. Engineering Notes

Use local persistence first

MVP does not need account sync.

Use local storage / SQLite / app storage depending on stack.

Need to persist:

pinned games
game progress
selected modes
last read event
scoreboard reached
follow live preference

Prefer event ID over scroll offset

Scroll offset alone is fragile.

Primary restore key:

lastReadEventId

Secondary:

lastScrollOffset

Do not couple scoreboard visibility to spoiler logic

The rule is layout-based:

Scoreboard goes at bottom.

Not:

Hide score using reveal gate.

Do not hardcode baseball into core UI

Avoid generic core names like:

inning
outs
bases
batter
pitcher
boxScore

Use these only inside baseball-specific renderer/components.

⸻

27. One-Shot Agent Prompt

Goal

Rework Scroll Down Sports from a generic MLB catch-up list into a polished all-sports game stream experience.

The app should support pinned games, remembered game progress, live play-by-play streaming, user-facing timeline modes, and a bottom-positioned scoreboard/result.

Scope

Implement the next major product/visual pass.

Focus on:

1. Product behavior correctness.
2. Home screen state model.
3. Game detail stream model.
4. Pin/progress persistence.
5. All-sports-friendly abstractions.
6. Visual hierarchy improvements.

Do not treat this as a small styling tweak pass.

Non-negotiable rules

* The scoreboard/result belongs at the bottom of the game detail page.
* Do not show final score at the top by default.
* Replace P1/P2/P3 with user-facing modes.
* User progress must be remembered per game.
* Pinned games must persist.
* Live PBP updates must not hijack scroll.
* Core UI should be sport-neutral.
* MLB-specific logic belongs in MLB-specific rendering/helpers.
* Avoid overusing the current green accent.
* Raw PBP text should not be the primary UX headline.

Required features

Home

* Add pinned games section.
* Add state-aware game cards.
* Support scheduled/live/final states.
* Show resume state when applicable.
* Show new play count when applicable.
* Show “score at bottom” for final games where user has not reached scoreboard.
* Pin/unpin games.

Game detail

* Add game header card without top score by default.
* Add stream controls.
* Rename timeline modes to Key / Flow / Full.
* Remember selected mode.
* Restore last read position.
* Support new play count.
* Add jump-to-latest behavior.
* Keep scoreboard at bottom.
* Mark scoreboard as reached when viewed.

Event stream

* Group events by period.
* Render headline-first event cards.
* Support event importance.
* Show raw feed text as secondary/expandable detail.
* Make scoring/critical events visually distinct.
* Avoid duplicated period labels like 1st 1st.

Stats

* Replace player stat pill wall with impact players + compact tables.
* Keep stats below the main stream.
* Use sport-specific stat rendering.

Architecture

* Add or enforce sport-neutral game/event/progress models.
* Add sport renderer/adaptor pattern.
* Keep baseball-specific metadata in baseball renderer.

Validation loop

After implementation, run through these checks:

1. Open a final game. Confirm no final score appears at top.
2. Scroll to middle, leave, return. Confirm resume works.
3. Pin a live game. Confirm it appears in pinned section.
4. Simulate new live events while user is scrolled up. Confirm no jump.
5. Tap jump latest. Confirm latest event appears.
6. Switch Key/Flow/Full. Confirm selected mode persists.
7. Scroll to bottom. Confirm scoreboard appears and reached state saves.
8. Review screenshots. Confirm app no longer looks like a generic green iOS list.
9. Confirm MLB-specific terms are not hardcoded into core cross-sport components.
10. Confirm raw PBP is not the main visual headline when a better headline exists.

Expected outcome

The app should feel like:

A persistent sports stream where users pin games, catch up from where they left off, follow live play-by-play, and scroll down to the scoreboard.

Not:

A generic sports data list with white cards and green accents.