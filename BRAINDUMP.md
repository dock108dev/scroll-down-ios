# Scroll Down Sports Braindump: 8-Bit Situation Cards

## Core Thought

Key plays should start by showing the moment before the event.

Not the replay. Not the result. The setup.

The question the UI should answer is:

> What was true right before this mattered?

That is the missing context for plays like walks, strikeouts, penalties, power plays, third downs, late shots, or tying possessions. A walk only feels important if the user sees the bases were loaded or it moved the tying run. A strikeout only lands if the user sees runners in scoring position and two outs. A touchdown feels different on 3rd and goal than on a random drive summary.

The product direction is:

- show the pre-pitch, pre-snap, pre-shot, pre-possession situation
- use a compact 8-bit / analog scorebook style
- keep it readable and quiet, not arcade-noisy
- animate later only when the static setup is already useful

## Visual Language

Call it 8-bit-ish, not full pixel-art game.

The look should feel like:

- tiny scorebook diorama
- analog scoreboard
- pixel field/rink/court/diamond
- chunky dots for players/runners
- team-color ownership
- simple labels
- no fake realism

It should not feel like a mini video game taking over the card. It should feel like the app drew the situation on a little sports notebook.

Good ingredients:

- pixel diamond / field / rink / court / pitch strip
- analog scoreboard header
- small team-color dots
- one highlighted ball/puck/possession marker
- occupied bases / red zone / power play / possession indicators
- short context line above or inside the diorama

Avoid:

- too much movement
- exact formations unless the data really supports them
- fake player locations
- decorative pixel art that does not explain stakes
- saying the rule in long text when the diagram can show it

## Product Principle

This is a context feature, not a replay feature.

The replay comes later, if at all. The first useful thing is the pre-state.

The user should be able to glance at a key play card and understand:

- score pressure
- time/period pressure
- possession/side
- field/base/rink/court situation
- why the next event could swing the game

Then the text result can stay simple.

Example:

```text
B8 · 1 out · OAK down 4-2
[pixel diamond: runners on 1st and 2nd]
Jeff McNeil walks.
Bases loaded with one out.
```

That is much better than:

```text
Jeff McNeil walks.
Jeff McNeil
```

## Baseball First

Baseball is the best first sport because the situation is compact and visually obvious.

Pre-pitch state:

- inning half
- outs
- score
- bases occupied
- count if available
- batting team
- maybe pitcher/batter only if useful

8-bit view:

- small diamond
- base dots when occupied
- home plate / mound
- analog scoreboard strip with inning, score, outs
- team color for batting side
- optional count module

Why it helps:

- walk: shows if it loads the bases or moves tying run
- strikeout: shows if it kills a threat
- single/double: shows runners and likely run impact
- home run: shows how many were on
- groundout/flyout: shows outs and runner movement context

Baseball should support static before-state first.

Possible later animation:

- batter dot moves to first
- runners advance
- scoring runner flashes at home
- out lights tick up
- ball arc for homer

Only animate if backend data can support before/after state without lying.

## Football

Football can work well even without exact formations.

Pre-snap state:

- down and distance
- yard line / field position
- score and clock
- possession team
- red zone / goal-to-go
- timeout or quarter context if available

8-bit view:

- horizontal field strip
- yard markers
- ball at the spot
- offense dots in possession/team color
- defense dots in opposing/muted color
- first-down marker line
- end zone visible when relevant
- analog board: `3rd & 7`, `Q4 1:18`, `down 4`

Do not fake an exact formation. Generic offense/defense dots are fine unless the feed has real alignment data, which it probably will not.

Possible later animation:

- ball moves along field strip
- first-down marker flashes if converted
- touchdown path to end zone
- turnover flips possession color

## Hockey

Hockey is harder for exact positioning, but good for pressure state.

Pre-shot / pre-event state:

- period and time
- score state
- power play / penalty kill / even strength
- attacking team
- zone if available
- goalie pulled if available

8-bit view:

- rink strip
- net and goalie dot
- puck dot
- attacking skater dots
- power play indicator
- analog board: `3rd 5:12`, `tied`, `VGK PP`

Do not overdo player positions unless the backend has coordinates. For goals and shots, a generic attacking-zone setup is still useful.

Possible later animation:

- puck line toward net
- goalie/net flash on goal
- penalty box light for penalties
- strength-state change

## Basketball

Basketball is useful for score/time/possession pressure more than exact player layout.

Pre-shot / pre-possession state:

- quarter and clock
- score differential
- possession team
- shot clock if available
- bonus/foul context if available
- shot location only if available

8-bit view:

- half-court or small court
- possession marker
- ball dot
- scoreboard board: `Q4 0:42`, `down 2`
- optional shot clock module
- optional location dot for three, paint, free throw

Possible later animation:

- shot arc
- made basket flash
- possession arrow flip
- free throw dots

## Soccer

Soccer is uneven because feeds may not have location.

Pre-shot / set-piece state:

- minute
- score
- attacking team
- set piece type if available
- penalty/free kick/corner/card context
- attacking third if available

8-bit view:

- pitch strip
- goal area when relevant
- ball marker
- attacking team color
- analog board: `88'`, `tied`, `free kick`

Possible later animation:

- shot line toward goal
- card flash
- penalty dot
- corner kick arc

## Other Sports

Not every sport needs a field diagram.

Golf:

- leaderboard pressure card
- hole, score to par, rank, strokes back
- 8-bit analog leaderboard, not course animation

Tennis:

- score state card
- set/game/point pressure
- break point, match point, deuce
- simple court only if it adds value

Generic fallback:

- analog score/pressure board
- team/competitor color
- event label
- period/time
- no fake field

## Data Honesty

The UI must not pretend it knows more than the feed provides.

Use tiers:

1. Situation board
   - score, time, period, possession, event type
   - always safe

2. Sport diagram
   - bases, field spot, rink/court zone, possession
   - only when metadata supports it or generic position is honest

3. Micro-animation
   - runners advance, ball moves, shot path, puck path
   - only when before/after state is defensible

If data is missing, show a clean pressure board instead of a fake diagram.

## Card Composition

Preferred structure:

```text
[Situation strip]
[8-bit diagram]
[Result headline]
[One context sentence if needed]
```

The card should not duplicate player names.

The diagram owns the setup. The headline owns the result. The context sentence owns the why.

Example baseball:

```text
B8 · 1 out · OAK down 4-2
[diamond: runners on 1st and 2nd]
Jeff McNeil walks.
Bases loaded with one out.
```

Example football:

```text
Q4 · 1:18 · 3rd & 7 · down 4
[field strip: ball at own 42, first-down line at 49]
Bay Harbor converts over the middle.
Drive stays alive.
```

Example hockey:

```text
3rd · 5:12 · tied · VGK power play
[rink: attacking zone, puck high slot]
Tomas Hertl scores.
Power play turns into the lead.
```

## Implementation Shape

Do not bake this directly into play rows.

Create a presentation object and renderer-owned views.

Possible model:

```swift
struct KeyPlaySituationPresentation: Equatable {
    let title: String
    let contextLine: String
    let pressureLine: String?
    let sport: Sport
    let layout: SituationLayout
    let accent: SportsTheme.Tone
}

enum SituationLayout: Equatable {
    case baseball(BaseballSituation)
    case football(FootballSituation)
    case hockey(HockeySituation)
    case basketball(BasketballSituation)
    case soccer(SoccerSituation)
    case pressureBoard(PressureSituation)
}
```

The sport renderer should decide whether it can produce a situation.

The play row should only ask:

```swift
renderer.keyPlaySituation(for: event)
```

If nil, render the normal row.

## First Build Slice

Start with baseball.

Scope:

- only key / big-moment plays
- static pre-pitch card
- no animation yet
- no fake count if count is unavailable
- no duplicate player detail
- support runners/outs/inning/score from metadata when available

Minimum:

- pixel diamond
- occupied-base dots
- outs indicator
- score/inning strip
- batting team color
- compact text fallback

Useful events:

- walk
- strikeout
- single/double/triple
- home run
- groundout/flyout
- game end can skip diagram

Acceptance:

- a walk with runners on base visibly explains why it matters
- a strikeout with runners on base visibly explains the threat
- a scoring hit shows the pre-state before revealing result text
- missing base data does not render a fake diamond state

## Animation Later

Animation should be tiny and optional.

Good animation:

- 400 to 800 ms
- one movement
- settles fast
- does not loop forever
- respects Reduce Motion

Bad animation:

- full replay
- moving every player
- slow theatrical reveal
- hard-to-read arcade effects
- repeated motion while scrolling

Reduce Motion behavior:

- static pre-state
- optional final-state flash
- no travel animation

## Why This Matters

The catch-up stream should not just list plays. It should teach the stakes.

The current feed can tell the user what happened. Situation cards tell the user why it was a key moment.

This is especially important for users catching up after the game:

- they do not remember the base state
- they do not know the down and distance
- they do not know if it was tied, late, power play, or red zone
- they need the context before the result

That is the product win.
