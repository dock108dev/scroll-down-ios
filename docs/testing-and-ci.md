# Testing And CI

## Local Gate Wrapper

`Scripts/local_gate.sh` is the local gate entry point. It regenerates `ScrollDownSports.xcodeproj` from `project.yml`, writes Xcode artifacts under `.build`, disables simulator code signing, and clears `SDA_API_KEY` while setting `SDA_API_BASE_URL` to `http://127.0.0.1.invalid` for simulator gates.

The wrapper supports these gates:

```text
fast
build
unit
coverage
ui-smoke
visual
accessibility
performance-smoke
full-local
script-checks
clean-artifacts
```

`fast` and `build` generate the project and build the simulator app. `unit` runs `ScrollDownSportsTests` without coverage enforcement. `coverage` runs `ScrollDownSportsTests` with coverage, writes `.build/TestResults/Coverage.xcresult`, emits `.build/coverage/xccov-report.json` and `.build/coverage/xccov-files.json`, and runs `Scripts/check_xccov_thresholds.swift`.

`ui-smoke` runs `ScrollDownSportsUITests/ScrollDownSportsCriticalFlowsUITests`. `visual` runs the committed snapshot regression test classes selected in the wrapper. `accessibility` runs `ScrollDownSportsUITests/ScrollDownSportsAccessibilityUITests`. `performance-smoke` runs `ScrollDownSportsTests/PerformanceSmokeTests` and `ScrollDownSportsUITests/ScrollDownSportsPerformanceSmokeUITests`.

`full-local` runs build, coverage, repository script checks, and UI smoke. `script-checks` runs `Scripts/test_xccov_thresholds.sh`, `Scripts/test_ci_workflow_shape.sh`, and `Scripts/test_local_gate.sh`. `clean-artifacts` removes generated local gate artifacts under `.build`.

## Simulator Destination

The canonical local simulator destination is iPhone 17 Pro on iOS 26.2. `Scripts/local_gate.sh` tries that destination first. If it is unavailable, the wrapper chooses an installed iPhone simulator; callers can override the destination with `TEST_DESTINATION`.

Visual baselines are committed under `ScrollDownSportsTests/__Snapshots__`. Snapshot recording is disabled by default and is enabled only when `SNAPSHOT_RECORD=1` is set for a visual gate run.

## Coverage Policy

`Config/coverage-thresholds.json` configures the coverage policy for `Scripts/check_xccov_thresholds.swift`. The policy targets `ScrollDownSports.app`, reads `.build/coverage/xccov-report.json`, applies a global line-coverage floor, applies per-file floors for selected app files, excludes generated, DTO, fixture, resource, config, lifecycle, and UI-fixture payload paths from the global calculation, and requires matching scenario test files for selected source paths.

## GitHub Actions

`.github/workflows/ci.yml` runs on pull requests, pushes to `main`, schedules, and manual dispatch. The PR job installs XcodeGen, blocks `SNAPSHOT_RECORD=1`, runs `Scripts/local_gate.sh build`, `coverage`, `script-checks`, and `ui-smoke`, then uploads XCTest result bundles, coverage reports, snapshot artifacts, simulator diagnostics, and the generated Xcode project.

Scheduled and manually dispatched jobs run heavier gates. The visual matrix runs `visual` on iPhone 16 and iPhone 16 Pro Max destinations with `OS=latest`. The UI/accessibility matrix runs `ui-smoke` and `accessibility` on iPhone SE (3rd generation), iPhone 16, and iPhone 16 Pro Max destinations with `OS=latest`. The performance job runs `performance-smoke`.
