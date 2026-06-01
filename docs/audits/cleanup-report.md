# Cleanup Report

This audit records current cleanup constraints referenced by source size-note comments.

## Large Files Kept Intact

- `ScrollDownSports/Views/GameDetailView.swift` is 1053 LOC. It keeps scroll/progress/read-history state in one SwiftUI view because the behavior depends on private `@State` ownership for visible-event tracking, sticky navigation, resize restoration, score reveal, and refresh hooks.
- `ScrollDownSportsTests/SportsThemeTests.swift` is 787 LOC. It keeps palette, contrast, and cross-sport renderer presentation invariants together through shared fixtures.
- `Scripts/local_gate.sh` is 728 LOC. It keeps gate modes together because destination discovery, simulator fallback, result-bundle cleanup, XcodeGen regeneration, simulator API overrides, dry-run output, and focused rerun files share helper functions.
- `ScrollDownSportsTests/HomeViewModelTests.swift` is 719 LOC. It keeps home timeline, filtering, pinning, persisted snapshot, reading-progress, and card-state scenarios together through shared fixtures.
- `ScrollDownSports/Models/SDADomainMapper.swift` is 664 LOC. It keeps the DTO-to-domain mapping boundary together until sport-specific mapping seams are extracted with focused tests.
- `ScrollDownSports/Rendering/StatPresentationBuilder.swift` is 593 LOC. It keeps stat grouping and presentation mapping together.
- `ScrollDownSports/ViewModels/HomeViewModel.swift` is 578 LOC. It keeps API refresh, filtering, persistence, pins, reading history, and card-state assembly together.
- `ScrollDownSports/Models/DomainModels.swift` is 545 LOC. It keeps the app domain model contract together.
- `ScrollDownSports/Rendering/BaseballRenderer.swift` is 538 LOC. It keeps baseball situation parsing, confidence gating, score-pressure composition, and diagram assembly together around shared private inputs.
- `ScrollDownSportsTests/GameStateStoreTests.swift` is 527 LOC. It keeps persistence, migration, corruption recovery, and read-state scenarios together.
- `ScrollDownSportsTests/DecodingTests.swift` is 510 LOC. It keeps date and DTO decoding coverage together around shared fixtures.
- `ScrollDownSports/Rendering/PeriodLabelFormatter.swift` is 503 LOC. It keeps sport-specific period and clock normalization in one parser surface.

## Size Notes Below 500 LOC

- `ScrollDownSports/Views/SituationDiagramViews.swift` currently has a size-note comment but is 338 LOC. The comment remains useful because the file still groups shared situation diagram chrome and sport-specific strips that need matching layout.

## Verification Surface

Use these repository checks when changing the cleanup constraints:

```sh
find ScrollDownSports ScrollDownSportsTests ScrollDownSportsUITests Scripts -type f \( -name '*.swift' -o -name '*.sh' \) -print0 | xargs -0 wc -l | sort -nr | head -30
Scripts/local_gate.sh --dry-run script-checks
```
