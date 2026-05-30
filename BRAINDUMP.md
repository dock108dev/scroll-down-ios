# Visual Polish BRAINDUMP

Date: 2026-05-29
Scope: production-ready theming, compact phone polish, and the UI defects visible in the marked-up simulator screenshots.

## North Star

Scroll Down should feel like a fast, professional sports desk app: clear hierarchy, confident spacing, restrained color, and zero "debug UI" artifacts. The current app has useful structure, but the visual language reads too homemade: scorebook paper/grid, mixed accent colors, outline-heavy cards, cramped segmented controls, and detail cards that repeat metadata until the stream feels noisy.

This pass should not merely tweak the current coloring. Replace the visual system with a cleaner neutral foundation, then re-apply sport/team color only where it carries meaning.

Important framing: the card/UI problems are sport agnostic. MLB is only the screenshot example. NBA, NHL, NFL, NCAAB, NCAAF, soccer, tennis, golf, and unknown/generic sports should all use the same polished detail-card system and interaction rules. The data inside those cards must stay sport specific: baseball can show inning/base/score context, basketball can show possession/clock/score context, hockey can show strength/zone/clock context, football can show down/distance/field context, and so on. Shared shell, sport-specific content.

## Screenshot Read

### Home: Cramped League Filter

The current iPhone league segmented picker is too dense. `All MLB NBA NHL NFL NCAAB NCAAF` does not fit with readable spacing, and iOS truncates at least one selected item to `NCA...`.

Fix direction:

- Replace compact-width segmented league picker with a custom horizontally scrolling chip row or a compact `League` menu.
- Preferred: chip row with 44-point minimum height, visible selected state, and no truncation. Chips can scroll horizontally, but each chip text must be complete.
- Keep segmented picker only for regular-width layouts where all labels fit comfortably.
- Add snapshot coverage for the iPhone 17 Pro-width case and the smaller phone compact case.

Target files:

- `ScrollDownSports/Views/HomeSectionsView.swift`
- `ScrollDownSports/ViewModels/HomeSections.swift`
- `ScrollDownSportsTests/HomeVisualRegressionTests.swift`

### Home: Future Games Missing Or Empty Jump

The home feed can appear to jump to a blank lower area after refresh/filter changes. The screenshot suggests the initial anchor logic is scrolling to a section that has no visible rows, or the current timeline window/filtering is hiding future pregame games that the user expects to see.

Fix direction:

- Audit `HomeViewModel.homeAnchorID(for:)` so it never returns an anchor whose section has no rendered rows.
- Audit `isVisibleInDefaultHomeTimeline(_:)` and `hasUsefulPregamePreview(_:)`; upcoming games should not disappear just because the backend lacks rich pregame presentation.
- Add a production empty state at the actual top of the feed when no games exist, not a blank grid canvas.
- Add a section-level empty state for `Later Today` / `Upcoming` when the time window contains no qualifying future games.
- Preserve user scroll position on refresh unless filters changed or the user is at the top.

Target files:

- `ScrollDownSports/ViewModels/HomeViewModel.swift`
- `ScrollDownSports/Views/HomeView.swift`
- `ScrollDownSports/Views/HomeSectionsView.swift`
- `ScrollDownSportsTests/HomeFunctionalityInvariantTests.swift`
- `ScrollDownSportsTests/HomeVisualRegressionTests.swift`

### Detail: Header Formatting Is Inconsistent

The detail game header is a dark block while the rest of the app uses light cards. It looks like a different product surface. Home cards and detail headers should share one game-summary system.

Fix direction:

- Create one reusable `GameSummaryCard` treatment for home and detail.
- Use the same team row rhythm, abbreviations, metadata, pin/read state, and status line across surfaces.
- If the detail header needs extra emphasis, use a subtle top border/accent rail, not a full dark rectangle.
- Keep score-spoiler behavior intact: top-region text must not reveal hidden scores.

Target files:

- `ScrollDownSports/Views/HomeGameCardView.swift`
- `ScrollDownSports/Views/GameDetailChrome.swift`
- `ScrollDownSports/Rendering/SportRenderer.swift`
- `ScrollDownSportsTests/HomeGameCardSnapshotTests.swift`
- `ScrollDownSportsTests/GameDetailChromeSnapshotTests.swift`

### Detail: Sport-Agnostic Detail Cards Are Too Busy

The play-by-play/detail card problem is not baseball-specific. The MLB rows make it obvious, but every sport suffers when the row repeats context, event type, situation data, score movement, and headline as separate visual blocks.

The current baseball example shows:

- event label in the row chrome
- a situation table repeating inning/team/play/score
- the headline repeating the same play
- a result line repeating score movement

The equivalent issue exists across sports whenever the card renders sport context plus a headline plus result text without deduping. This creates duplicate details and makes important plays harder to scan.

Fix direction:

- Situation panels should show sport-specific context the headline does not already say.
- Hide sport-specific fields when they duplicate `eventLabel`, the headline, or the result line.
- Hide score state/movement when the same score movement is already rendered as the row result line.
- Consider replacing table-like layouts with compact contextual chips, for example `Bottom 7th`, `CWS`, `Up 4` for baseball, or analogous possession/clock/period/down-distance chips for other sports.
- Keep the full situation payload accessible through accessibility value or raw-feed disclosure, but do not visually repeat it.
- Standardize play row vertical rhythm: context line, optional compact situation, headline, optional non-duplicative detail.

Target files:

- `ScrollDownSports/Views/PlayRow.swift`
- `ScrollDownSports/Views/SituationDiagramViews.swift`
- `ScrollDownSports/Rendering/BaseballRenderer.swift`
- `ScrollDownSports/Rendering/GenericSportRenderer.swift`
- `ScrollDownSports/Rendering/BasketballSituationPresentation.swift`
- `ScrollDownSports/Rendering/HockeyRenderer.swift`
- `ScrollDownSports/Rendering/ReservedSportRenderers.swift`
- `ScrollDownSports/Rendering/SportRenderer.swift`
- `ScrollDownSportsTests/PlayRowContentFilterTests.swift`
- `ScrollDownSportsTests/EventAndScoreboardSnapshotTests.swift`
- `ScrollDownSportsTests/SituationDiagramLayoutSnapshotTests.swift`
- `ScrollDownSportsTests/SportRendererInvariantTests.swift`

### Detail: Sticky Controls Feel Like Debug UI

The sticky stream controls are functional but visually heavy: dark `Top` / `End` blocks, a black progress pill, and a wide bar floating over the play feed. It feels bolted on.

Fix direction:

- Convert sticky controls into a compact translucent navigation strip using the same theme tokens as other controls.
- Use icon-first controls where possible: top, latest/end, return.
- Keep progress text but reduce visual weight: `71/71 read` should be secondary metadata, not a black badge.
- Ensure the strip does not occlude row content or create weird top clipping during programmatic scroll.

Target files:

- `ScrollDownSports/Views/DetailNavigationChrome.swift`
- `ScrollDownSports/Views/GameDetailView.swift`
- `ScrollDownSportsTests/GameDetailChromeSnapshotTests.swift`
- `ScrollDownSportsUITests/ScrollDownSportsCriticalFlowsUITests.swift`

## Theme Reset

The current coloring is not the direction. Problems:

- Warm paper + green scorebook grid makes the whole app feel busy before content appears.
- Green rails, blue links, purple pin buttons, brown/orange scoring outlines, and dark navy cards fight each other.
- Colored outlines around every card make the UI noisy.
- The grid background is visible even when the feed is empty, which makes blank states look broken.

Proposed production palette:

```text
App background       #F6F8FB
Surface             #FFFFFF
Surface muted       #F1F4F8
Ink                 #111827
Secondary ink       #667085
Hairline            #D8DEE8
Primary action      #1D4ED8
Deep navy           #0B1F3A
Live                #D92D20
Final/neutral       #475467
Success             #16835F
Warning/scoring     #B54708
Pinned              #334155
Text on fill        #FFFFFF
Dark background     #0B1220
Dark surface        #111827
Dark surface muted  #1F2937
Dark hairline       #344054
```

Rules:

- Background is neutral and calm. Remove the scorebook grid from primary app screens or reduce it to near-invisible debug-level texture.
- Cards are mostly white surfaces with neutral borders. Accent colors should appear as a rail, small chip, dot, or selected state, not as full-card outlines everywhere.
- Team colors are supporting accents, not the main theme.
- Pin state should not default to lavender/purple. Use a neutral slate treatment unless there is a strong product reason for purple.
- Dark mode must be designed, not just inverted.
- All semantic colors need contrast checks against light and dark surfaces.

Target files:

- `ScrollDownSports/DesignSystem/SportsTheme.swift`
- `ScrollDownSports/DesignSystem/SportsSurfaces.swift`
- `ScrollDownSports/DesignSystem/SportsLayoutMetrics.swift`
- `ScrollDownSportsTests/SportsThemeTests.swift`

## Component Work

### 1. App Chrome

- Tune navigation bar background to match the new app background and avoid giant floating white button shadows.
- Refresh button should be a standard toolbar icon, not a large floating rounded square unless the screen is intentionally using floating chrome.
- Match back and refresh affordances between home/detail.
- Check Dynamic Island safe-area spacing on iPhone 17 Pro-class devices.

### 2. Home Feed

- Redesign `HomeStickyHeader` as a compact control shelf.
- League filter should be readable on compact phones.
- Team search should use a smaller field height and clearer focused state.
- `Updated 6:35 PM` should be secondary and not consume prime vertical space.
- Home cards should be denser but more polished: reduce card height by improving typography, not by cramming text.
- Add useful future/upcoming empty states.

### 3. Detail Feed

- Use one game summary treatment with home.
- Stream mode control should feel native and polished. Segmented control is okay if it fits; use menu or tabs when Dynamic Type or width pressure makes it cramped.
- Rebuild sport-agnostic detail cards around information hierarchy:
  - primary: what happened
  - secondary: sport-specific game context
  - tertiary: raw feed/details
- The important stream should look curated, not like every row is an alert.
- Period headers should be calm, aligned, and not compete with cards.

### 4. Stats And Box Score

- Make `Player Stats`, `Team Stats`, and `Box Score` visually consistent with feed cards.
- Collapsed stat rows should have clear affordance but not oversized iconography.
- Verify that the score reveal / spoiler mechanics still feel intentional after the theme reset.

## Behavior Fixes To Include

### Blank Home After Refresh Or Filter

Reproduce with the iPhone 17 Pro simulator and live/prod API data if available. If live API data is unavailable, create a fixture that has only final games plus upcoming pregame games. The home screen must never land on a blank lower page after refresh, league switch, or filter clear.

Acceptance:

- Refresh preserves visible rows when possible.
- League switch starts at the first visible matching section.
- If there are no games, a real empty state is visible above the fold.
- Upcoming pregame games are visible even without rich pregame preview text, as long as teams and start time are concrete.

### Duplicate Sport-Specific Detail Data

Reproduce first with MLB final full play-by-play fixture because the screenshots show it clearly, then add coverage for at least one non-baseball renderer. The visible card should not repeat event type, score state, period/clock, possession/team, or result movement in multiple places.

Acceptance:

- No visual row contains the same event type both as a context label and a situation value.
- No visual row repeats the same score movement as both a sport-specific context field and result line.
- The dedupe policy applies across sports, not only MLB.
- Accessibility still exposes enough detail for VoiceOver.

## Implementation Order

1. Snapshot the current problems with phone visual tests before changing broad styling.
2. Replace theme tokens in `SportsTheme` and update contrast tests.
3. Restyle surfaces and remove colored outlines as the default.
4. Fix compact league control and home blank-anchor behavior.
5. Unify home/detail game summary cards.
6. Simplify sport-specific situation rendering and duplicate filters across renderers.
7. Restyle sticky detail navigation controls.
8. Re-record only intentional snapshot changes.
9. Run the focused gates, then the broader local gate.

## Verification Plan

Focused tests:

```sh
Scripts/local_gate.sh unit
Scripts/local_gate.sh visual
Scripts/local_gate.sh accessibility
Scripts/local_gate.sh ui-smoke
```

Before calling it production-ready:

```sh
Scripts/local_gate.sh full-local
Scripts/local_gate.sh ipad-ui-smoke
Scripts/local_gate.sh ipad-accessibility
Scripts/local_gate.sh performance-smoke
```

Manual simulator checks:

- iPhone 17 Pro, light mode, medium text
- iPhone SE-class compact width
- iPhone 17 Pro, accessibility text size
- iPad portrait and landscape
- Dark mode on phone and iPad

Manual scenarios:

- Home with final games only
- Home with upcoming games only
- Home with live plus upcoming games
- League switch across All, MLB, NCAAB, NCAAF
- Team search with no matches and with matches
- Detail important/standard/all plays
- Detail sticky top/end/return
- Detail final score reveal and stats sections

## Definition Of Done

- The app no longer uses the current beige/green scorebook-heavy palette as its primary visual identity.
- Compact phone controls never truncate important labels.
- Empty feed states are explicit, useful, and above the fold.
- Future/upcoming games are visible when the app has concrete game data.
- Detail rows do not visually duplicate sport-specific metadata.
- Home and detail cards feel like one product.
- Light and dark mode both pass contrast expectations.
- Snapshot updates are intentional and documented in the PR.
- Local gates pass, or any skipped gate has a concrete reason and follow-up.
