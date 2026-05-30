# Cleanup Report

This audit records current cleanup constraints referenced by source size-note comments.

## Large Files Kept Intact

- `ScrollDownSports/Views/GameDetailView.swift` is 848 LOC. It keeps scroll/progress state in one SwiftUI view because the behavior depends on private `@State` ownership for visible-event tracking, sticky navigation, resize restoration, score reveal, and refresh hooks.
- `ScrollDownSportsTests/SportsThemeTests.swift` is 703 LOC. It keeps palette, contrast, and cross-sport renderer presentation invariants together through shared fixtures.
- `Scripts/local_gate.sh` is 641 LOC. It keeps gate modes together because destination discovery, simulator fallback, result-bundle cleanup, XcodeGen regeneration, simulator API overrides, dry-run output, and focused rerun files share helper functions.
- `ScrollDownSports/Rendering/BaseballRenderer.swift` is 538 LOC. It keeps baseball situation parsing, confidence gating, score-pressure composition, and diagram assembly together around shared private inputs.
- `ScrollDownSportsTests/HomeViewModelTests.swift` is 508 LOC. It keeps home timeline, filtering, pinning, persisted snapshot, and card-state scenarios together through shared fixtures.
- `ScrollDownSports/Rendering/PeriodLabelFormatter.swift` is 503 LOC. It keeps sport-specific period and clock normalization in one parser surface.

## Size Notes Below 500 LOC

- `ScrollDownSports/Views/SituationDiagramViews.swift` currently has a size-note comment but is 338 LOC. The comment remains useful because the file still groups shared situation diagram chrome and sport-specific strips that need matching layout.

## Verification Surface

Use these repository checks when changing the cleanup constraints:

```sh
find ScrollDownSports ScrollDownSportsTests ScrollDownSportsUITests Scripts -type f \( -name '*.swift' -o -name '*.sh' \) -print0 | xargs -0 wc -l | sort -nr | head -30
Scripts/local_gate.sh --dry-run script-checks
```
