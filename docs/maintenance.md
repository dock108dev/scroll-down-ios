# Maintenance Notes

This file records current maintenance constraints that are useful to contributors and verifiable from the repository.

## Generated And Local-Only Files

Do not edit generated artifacts as source of truth:

- `ScrollDownSports.xcodeproj` is generated from `project.yml`.
- `.build/`, `build/`, `DerivedData/`, `xcuserdata/`, and `.aidlc/` are ignored local or generated state.
- `Config/Local.xcconfig` is ignored and may contain private machine-specific backend or signing values.

Repository scripts and CI use `Scripts/local_gate.sh`; it regenerates the Xcode project before build and test gates.

## Files Still Over 500 LOC

- `ScrollDownSports/Views/GameDetailView.swift` is 1053 LOC. The view owns scroll proxy actions, progress persistence, visibility preference handling, resize restoration, sticky controls, score reveal state, reading-history state, and refresh hooks through private SwiftUI `@State`. A clean extraction would need to preserve that state ownership and should only move pure scroll-target or viewport decision helpers into `GameDetailViewSupport.swift`.
- `ScrollDownSportsTests/SportsThemeTests.swift` is 787 LOC. The suite keeps palette, contrast, and cross-sport renderer presentation invariants together through shared fixtures. Split it only after the shared fixture setup is isolated.
- `Scripts/local_gate.sh` is 728 LOC. The gate modes share destination discovery, family-preserving simulator fallback, result-bundle cleanup, XcodeGen regeneration, simulator API overrides, xcodebuild argument assembly, dry-run output, and focused rerun files. A clean extraction would first need coverage for sourcing shared shell helpers from `Scripts/test_local_gate.sh`.
- `ScrollDownSportsTests/HomeViewModelTests.swift` is 719 LOC. The suite is fixture-heavy and grouped around home timeline, filtering, pinning, persisted snapshot, reading-progress, and card-state behavior. Splitting it without shared scenario builders would duplicate setup rather than remove current complexity.
- `ScrollDownSports/Models/SDADomainMapper.swift` is 664 LOC. It is the boundary between SDA DTOs and app-domain state, so extraction should happen around tested sport-specific mapping helpers rather than by file size alone.
- `ScrollDownSports/Rendering/StatPresentationBuilder.swift` is 593 LOC. The file centralizes stat grouping and presentation mapping; split by league only if league-specific render rules keep growing.
- `ScrollDownSports/ViewModels/HomeViewModel.swift` is 578 LOC. The view model coordinates API refresh, filtering, persistence, pins, reading history, and card-state assembly. Split only after adapter seams are pinned by focused tests.
- `ScrollDownSports/Models/DomainModels.swift` is 545 LOC. The file is a domain model contract; splitting should follow stable feature boundaries, not line count.
- `ScrollDownSports/Rendering/BaseballRenderer.swift` is 538 LOC. It centralizes baseball-specific situation policy, pre-pitch state extraction, score-pressure composition, and renderer output. It is a reasonable split candidate around pure decision/presentation helpers only when a targeted renderer refactor pins the boundary.
- `ScrollDownSportsTests/GameStateStoreTests.swift` is 527 LOC. The suite covers persistence, migration, corruption recovery, and read-state scenarios through shared fixtures.
- `ScrollDownSportsTests/DecodingTests.swift` is 510 LOC. The suite keeps date and DTO decoding coverage together around shared fixtures.
- `ScrollDownSports/Rendering/PeriodLabelFormatter.swift` is 503 LOC. It centralizes sport-specific period and clock normalization. It is barely over the threshold and should stay together unless sport-specific formatter helpers are extracted with focused tests.

## Documentation Policy

Root documentation is intentionally limited to `README.md`. Supporting documentation belongs under `docs/`.

Documentation should describe current, code-verifiable behavior. Product ideas, speculative designs, old audit trails, and generated working notes should not be kept as project docs unless they are clearly tied to current code or active contributor workflow.

## Validation Commands

Useful documentation-maintenance checks:

```sh
git ls-files '*.md'
find ScrollDownSports ScrollDownSportsTests ScrollDownSportsUITests Scripts -type f \( -name '*.swift' -o -name '*.sh' \) -print0 | xargs -0 wc -l | sort -nr | head -40
rg -n "README\\.md|docs/.*\\.md" project.yml Scripts Config .github ScrollDownSports ScrollDownSportsTests ScrollDownSportsUITests
```
