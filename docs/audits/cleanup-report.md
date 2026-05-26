# Cleanup Audit

This audit is a narrow note for current code comments that cite the cleanup report. It is not product documentation and is not linked from the root README.

## Current Cleanup References

- `ScrollDownSports/Views/GameDetailView.swift` has an inline size note that points here.
- `Scripts/local_gate.sh` has an inline size note that points here.
- `ScrollDownSportsTests/HomeViewModelTests.swift` has an inline size note that points here.
- `ScrollDownSportsTests/TestFixtures.swift` provides shared `previewPresentation(...)` and `eventPresentation(...)` builders used by home, detail, label, and snapshot tests.
- `ScrollDownSportsTests/SnapshotSupport/ComponentSnapshotFixtures.swift` preserves snapshot-specific fixture defaults while delegating shared presentation construction to `TestFixtures`.

## Files still >500 LOC

- `ScrollDownSports/Views/GameDetailView.swift` remains 799 LOC. Justification: scroll proxy actions, progress persistence, visibility preference handling, resize restoration, and refresh hooks share private SwiftUI `@State` ownership in this view. A clean next extraction would first move more pure, stateless scroll-target and viewport decision helpers into `GameDetailViewSupport.swift` without changing the public screen API. The file has a one-line size note pointing here.
- `Scripts/local_gate.sh` remains 637 LOC. Justification: the gate modes share destination discovery, result-bundle cleanup, xcodebuild argument assembly, and dry-run behavior. A clean next extraction would move reusable command/result helpers into a sourced `Scripts/local_gate_lib.sh` after `Scripts/test_local_gate.sh` covers the sourced-library path. The file has a one-line size note pointing here.
- `ScrollDownSportsTests/HomeViewModelTests.swift` remains 508 LOC. Justification: the suite is fixture-heavy and grouped around home timeline/card-state behavior; mechanically splitting it would duplicate setup helpers. A clean next extraction would separate card-state phase assertions from timeline section assertions after introducing shared scenario builders. The file has a one-line size note pointing here.

## Validation

Current documentation-pass validation is recorded in `docs/audits/docs-consolidation.md`.

## Escalations

- None.
