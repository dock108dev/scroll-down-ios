# Testing And CI

## Local Gate Wrapper

`Scripts/local_gate.sh` is the local gate entry point. It regenerates `ScrollDownSports.xcodeproj` from `project.yml`, writes Xcode artifacts under `.build`, disables simulator code signing, and clears `SDA_API_KEY` while setting `SDA_API_BASE_URL` to `http://127.0.0.1.invalid` for simulator gates.

This simulator gate behavior is intentionally different from direct iPhone installs. Physical-device builds use `Config/Secrets.xcconfig` plus ignored `Config/Local.xcconfig`, defaulting to `https://sda.dock108.dev` unless a private local override is set.

The wrapper supports these gates:

```text
fast
build
unit
coverage
ui-smoke
visual
accessibility
multitasking
ipad-ui-smoke
ipad-visual
ipad-accessibility
ipad-multitasking
performance-smoke
full-local
script-checks
clean-artifacts
```

`fast` and `build` generate the project and build the simulator app. `unit` runs `ScrollDownSportsTests` without coverage enforcement. `coverage` runs `ScrollDownSportsTests` with coverage, writes `.build/TestResults/Coverage.xcresult`, emits `.build/coverage/xccov-report.json` and `.build/coverage/xccov-files.json`, and runs `Scripts/check_xccov_thresholds.swift`.

`ui-smoke` runs `ScrollDownSportsUITests/ScrollDownSportsCriticalFlowsUITests`. `visual` runs the committed snapshot regression test classes selected in the wrapper. `accessibility` runs `ScrollDownSportsUITests/ScrollDownSportsAccessibilityUITests`. `multitasking` runs project and app-shape checks that preserve iPad multitasking eligibility. The `ipad-ui-smoke`, `ipad-accessibility`, and `ipad-multitasking` gates run the matching iPad-family checks; `ipad-visual` runs the iPad snapshot gate on the pinned canonical iPad destination. `performance-smoke` runs `ScrollDownSportsTests/PerformanceSmokeTests` and `ScrollDownSportsUITests/ScrollDownSportsPerformanceSmokeUITests`.

`full-local` runs build, coverage, repository script checks, and UI smoke. `script-checks` runs `Scripts/test_xccov_thresholds.sh`, `Scripts/test_ci_workflow_shape.sh`, `Scripts/test_local_gate.sh`, and `Scripts/check_multitasking_project_invariants.rb`. `clean-artifacts` removes generated local gate artifacts under `.build`.

## Simulator Destination

The canonical phone simulator destination is iPhone 17 Pro on iOS 26.2. The canonical iPad simulator destination is iPad Pro 13-inch (M4) on iOS 26.2. `Scripts/local_gate.sh` preserves simulator family during fallback: an iPhone request can fall back only to an installed iPhone simulator, and an iPad request can fall back only to an installed iPad simulator. Callers can override nonvisual simulator gates with `TEST_DESTINATION`.

Visual baselines are committed under `ScrollDownSportsTests/__Snapshots__`. Snapshot recording is disabled by default and is enabled only when `SNAPSHOT_RECORD=1` is set for a visual gate run. The default `visual` gate keeps the canonical phone baseline stable even if a phone matrix destination is present. An explicit iPad visual run uses the pinned iPad Pro 13-inch (M4) iOS 26.2 destination and fails clearly if that simulator is unavailable.

## Situation Card Regression Layers

Situation card regressions are split by ownership. `SituationPresentationInvariantTests`, `SituationCardPolicyTests`, `PressureBoardFallbackTests`, `SportRendererInvariantTests`, `BaseballPrePitchMetadataTests`, `BaseballSituationAcceptanceTests`, `BasketballPossessionPressureTests`, `FootballFieldSituationTests`, `HockeyPressureSituationTests`, `SoccerSetPieceSituationTests`, and `GolfTennisPressureBoardTests` own renderer meaning: eligibility, confidence, ownership, fallback behavior, score-pressure boundaries, and duplicate-detail suppression. `SituationDecodingTests` and `SituationContractDecodingTests` own API compatibility for `situationBefore`, sport metadata, metadata merge behavior, score snapshots, score deltas, presentation fields, and future sport state payloads.

Static appearance belongs to the visual gates. `EventAndScoreboardSnapshotTests` covers situation cards inside play rows, including collapsed and expanded raw-feed states and compact width. `SituationDiagramLayoutSnapshotTests` covers baseball diamond modules, pressure-board fallback rows, Dynamic Type, and iPad readable widths. `visual` and `ipad-visual` run those snapshot suites with recording disabled unless `SNAPSHOT_RECORD=1` is explicitly set.

Accessibility ownership is separate. `SituationAccessibilitySummaryTests` owns row summary content, duplicate announcement suppression, and the invariant that decorative diagram panels stay hidden while the play row exposes one combined accessibility value. Device-level accessibility gates remain `accessibility` and `ipad-accessibility`.

## Coverage Policy

`Config/coverage-thresholds.json` configures the coverage policy for `Scripts/check_xccov_thresholds.swift`. The policy targets `ScrollDownSports.app`, reads `.build/coverage/xccov-report.json`, applies a global line-coverage floor, applies per-file floors for selected app files, excludes generated, DTO, fixture, resource, config, lifecycle, and UI-fixture payload paths from the global calculation, and requires matching scenario test files for selected source paths.

## GitHub Actions

`.github/workflows/ci.yml` runs on pull requests, pushes to `main`, schedules, and manual dispatch. The PR job installs XcodeGen, blocks `SNAPSHOT_RECORD=1`, runs `Scripts/local_gate.sh build`, `coverage`, `script-checks`, and `ui-smoke`, then uploads XCTest result bundles, coverage reports, snapshot artifacts, simulator diagnostics, and the generated Xcode project.

Scheduled and manually dispatched jobs run heavier gates. The visual matrix keeps phone visual coverage separate from iPad coverage. The UI/accessibility matrix runs `ui-smoke` and `accessibility` on iPhone SE (3rd generation), iPhone 16, and iPhone 16 Pro Max destinations with `OS=latest`. The iPad job runs `ipad-visual` on the pinned local-gate iPad destination, then runs `ipad-ui-smoke`, `ipad-accessibility`, and `ipad-multitasking` against the iPad Pro 11-inch (M4) and iPad Pro 13-inch (M4) matrix destinations with `OS=latest`. The performance job runs `performance-smoke`.
