# Maintenance Notes

This file records current maintenance constraints that are useful to contributors and verifiable from the repository.

## Generated And Local-Only Files

Do not edit generated artifacts as source of truth:

- `ScrollDownSports.xcodeproj` is generated from `project.yml`.
- `.build/`, `build/`, `DerivedData/`, `xcuserdata/`, and `.aidlc/` are ignored local or generated state.
- `Config/Local.xcconfig` is ignored and may contain private machine-specific backend or signing values.

Repository scripts and CI use `Scripts/local_gate.sh`; it regenerates the Xcode project before build and test gates.

## Files Still Over 500 LOC

- `ScrollDownSports/Views/GameDetailView.swift` is 848 LOC. The view owns scroll proxy actions, progress persistence, visibility preference handling, resize restoration, sticky controls, score reveal state, and refresh hooks through private SwiftUI `@State`. A clean extraction would need to preserve that state ownership and should only move pure scroll-target or viewport decision helpers into `GameDetailViewSupport.swift`.
- `ScrollDownSportsTests/SportsThemeTests.swift` is 703 LOC. The suite keeps palette, contrast, and cross-sport renderer presentation invariants together through shared fixtures. Split it only after the shared fixture setup is isolated.
- `Scripts/local_gate.sh` is 641 LOC. The gate modes share destination discovery, family-preserving simulator fallback, result-bundle cleanup, XcodeGen regeneration, simulator API overrides, xcodebuild argument assembly, dry-run output, and focused rerun files. A clean extraction would first need coverage for sourcing shared shell helpers from `Scripts/test_local_gate.sh`.
- `ScrollDownSports/Rendering/BaseballRenderer.swift` is 538 LOC. It centralizes baseball-specific situation policy, pre-pitch state extraction, score-pressure composition, and renderer output. It is a reasonable split candidate around pure decision/presentation helpers only when a targeted renderer refactor pins the boundary.
- `ScrollDownSportsTests/HomeViewModelTests.swift` is 508 LOC. The suite is fixture-heavy and grouped around home timeline, filtering, pinning, persisted snapshot, and card-state behavior. Splitting it without shared scenario builders would duplicate setup rather than remove current complexity.
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
