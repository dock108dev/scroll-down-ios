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
detail-scroll
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

`fast` and `build` generate the project and build the simulator app. `unit` runs `ScrollDownSportsTests` without coverage enforcement. `coverage` runs `ScrollDownSportsTests` with coverage, writes `.build/TestResults/Coverage.xcresult`, emits `.build/coverage/xccov-report.json` and `.build/coverage/xccov-files.json`, and runs `Scripts/check_xccov_thresholds.swift`. `detail-scroll` is the focused long-feed detail scrolling gate; run it with `Scripts/local_gate.sh detail-scroll`.

`ui-smoke` runs `ScrollDownSportsUITests/ScrollDownSportsCriticalFlowsUITests`. `visual` runs the committed snapshot regression test classes selected in the wrapper. `accessibility` runs `ScrollDownSportsUITests/ScrollDownSportsAccessibilityUITests`. `multitasking` runs project and app-shape checks that preserve iPad multitasking eligibility. The `ipad-ui-smoke`, `ipad-accessibility`, and `ipad-multitasking` gates run the matching iPad-family checks. `ipad-visual` writes `.build/TestResults/IPadVisual.xcresult` and runs the same committed snapshot selection on the canonical snapshot host; iPad coverage in those tests comes from explicit snapshot fixture sizes. `performance-smoke` runs `ScrollDownSportsTests/PerformanceSmokeTests` and `ScrollDownSportsUITests/ScrollDownSportsPerformanceSmokeUITests`.

`full-local` runs build, coverage, repository script checks, and UI smoke. `script-checks` runs `Scripts/test_xccov_thresholds.sh`, `Scripts/test_ci_workflow_shape.sh`, `Scripts/test_local_gate.sh`, and `Scripts/check_multitasking_project_invariants.rb`. `clean-artifacts` removes generated local gate artifacts under `.build`.

## Simulator Destination

The canonical phone simulator destination is iPhone 17 Pro on iOS 26.2. The canonical iPad simulator destination is iPad Pro 13-inch (M5) on iOS 26.2. `Scripts/local_gate.sh` preserves simulator family during fallback: an iPhone request can fall back only to an installed iPhone simulator, and an iPad request can fall back only to an installed iPad simulator. Callers can override most simulator test gates with `TEST_DESTINATION`; iPad gates reject iPhone destinations.

Visual baselines are committed under `ScrollDownSportsTests/__Snapshots__`. Snapshot recording is disabled by default and is enabled only when `SNAPSHOT_RECORD=1` is set for a visual gate run. The default `visual` gate keeps the canonical phone baseline stable even if a phone matrix destination is present. An explicit `visual` run with an iPad destination is accepted only for the pinned iPad Pro 13-inch (M5) iOS 26.2 destination. The `ipad-visual` gate ignores `TEST_DESTINATION` and uses the canonical phone snapshot host while selecting the iPad snapshot result bundle.

## Situation Card Regression Layers

Situation card regressions are split by ownership. `SituationPresentationInvariantTests`, `SituationCardPolicyTests`, `PressureBoardFallbackTests`, `SportRendererInvariantTests`, `BaseballPrePitchMetadataTests`, `BaseballSituationAcceptanceTests`, `BasketballPossessionPressureTests`, `FootballFieldSituationTests`, `HockeyPressureSituationTests`, `SoccerSetPieceSituationTests`, and `GolfTennisPressureBoardTests` own renderer meaning: eligibility, confidence, ownership, fallback behavior, score-pressure boundaries, and duplicate-detail suppression. `SituationDecodingTests` and `SituationContractDecodingTests` own API compatibility for `situationBefore`, sport metadata, metadata merge behavior, score snapshots, score deltas, and presentation fields.

Static appearance belongs to the visual gates. `EventAndScoreboardSnapshotTests` covers situation cards inside play rows, including collapsed and expanded raw-feed states and compact width. `SituationDiagramLayoutSnapshotTests` covers baseball diamond modules, pressure-board fallback rows, Dynamic Type, and iPad readable widths. `visual` and `ipad-visual` run those snapshot suites with recording disabled unless `SNAPSHOT_RECORD=1` is explicitly set.

Accessibility ownership is separate. `SituationAccessibilitySummaryTests` owns row summary content, duplicate announcement suppression, and the invariant that decorative diagram panels stay hidden while the play row exposes one combined accessibility value. Device-level accessibility gates remain `accessibility` and `ipad-accessibility`.

## Coverage Policy

`Config/coverage-thresholds.json` configures the coverage policy for `Scripts/check_xccov_thresholds.swift`. The policy targets `ScrollDownSports.app`, reads `.build/coverage/xccov-report.json`, applies a global line-coverage floor, applies per-file floors for selected app files, excludes generated, DTO, fixture, resource, config, lifecycle, and UI-fixture payload paths from the global calculation, and requires matching scenario test files for selected source paths.

## GitHub Actions

`.github/workflows/ci.yml` runs on pull requests, pushes to `main`, schedules, and manual dispatch. The PR job installs XcodeGen, blocks `SNAPSHOT_RECORD=1`, runs `Scripts/local_gate.sh build`, `coverage`, `script-checks`, and `ui-smoke`, then uploads XCTest result bundles, coverage reports, snapshot artifacts, simulator diagnostics, and the generated Xcode project.

Scheduled and manually dispatched jobs run heavier gates. The visual matrix declares compact-phone and large-phone destinations for iPhone 17 Pro and iPhone 17 Pro Max on iOS 26.2; the local gate still pins `visual` to the canonical phone snapshot host. The UI/accessibility matrix runs `ui-smoke` and `accessibility` on iPhone 16e, iPhone 17 Pro, and iPhone 17 Pro Max destinations on iOS 26.2. The iPad job runs `ipad-visual`, then runs `ipad-ui-smoke`, `ipad-accessibility`, and `ipad-multitasking` against iPad Pro 11-inch (M5) and iPad Pro 13-inch (M5) matrix destinations on iOS 26.2. The performance job runs `performance-smoke`.
