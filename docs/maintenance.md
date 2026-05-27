# Cleanup Audit

This file exists only because current code comments cite the cleanup report for large-file size notes. It is not product documentation and is intentionally not linked from the root README.

## Current Code References

- `ScrollDownSports/Views/GameDetailView.swift` has a size note for private SwiftUI scroll and progress state ownership.
- `Scripts/local_gate.sh` has a size note for keeping shared local-gate command assembly in one script.
- `ScrollDownSportsTests/HomeViewModelTests.swift` has a size note for keeping fixture-heavy timeline and card-state coverage together.

## Files Still Over 500 LOC

- `ScrollDownSports/Views/GameDetailView.swift` is 810 LOC. The view owns scroll proxy actions, progress persistence, visibility preference handling, resize restoration, sticky controls, score reveal state, and refresh hooks through private SwiftUI `@State`. A clean extraction would need to preserve that state ownership and should only move pure scroll-target or viewport decision helpers into `GameDetailViewSupport.swift`.
- `Scripts/local_gate.sh` is 638 LOC. The gate modes share destination discovery, family-preserving simulator fallback, result-bundle cleanup, XcodeGen regeneration, simulator API overrides, xcodebuild argument assembly, dry-run output, and focused rerun files. A clean extraction would first need coverage for sourcing shared shell helpers from `Scripts/test_local_gate.sh`.
- `ScrollDownSportsTests/HomeViewModelTests.swift` is 508 LOC. The suite is fixture-heavy and grouped around home timeline, filtering, pinning, persisted snapshot, and card-state behavior. Splitting it without shared scenario builders would duplicate setup rather than remove current complexity.

## Validation

- Current file references were checked with `rg "Size note|cleanup report|cleanup-report"`.
- Current line counts were checked with `wc -l ScrollDownSports/Views/GameDetailView.swift Scripts/local_gate.sh ScrollDownSportsTests/HomeViewModelTests.swift`.

## Escalations

None.
