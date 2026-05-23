# Scroll Down Sports iOS

Scroll Down Sports iOS is a SwiftUI app for browsing Scroll Down Sports games, pinning games, and reading a game detail stream before reaching the score and box score near the bottom of the page. The app talks to the SDA admin sports API configured through Xcode build settings.

## Run Locally

Install Xcode and XcodeGen, then generate the project after changing `project.yml`:

```sh
xcodegen generate
```

Build the app for the simulator:

```sh
xcodebuild -project ScrollDownSports.xcodeproj -scheme ScrollDownSports -destination 'generic/platform=iOS Simulator' build
```

Run the unit tests:

```sh
xcodebuild -project ScrollDownSports.xcodeproj -scheme ScrollDownSports -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' -derivedDataPath .build/DerivedData -resultBundlePath .build/TestResults/ScrollDownSports.xcresult -enableCodeCoverage YES test
```

For local API credentials, copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig` and set `SDA_API_KEY`. `Config/Local.xcconfig` is ignored by git and is included by `Config/Secrets.xcconfig` when present.

## Testing

### Simulator Standard

The canonical local and CI test destination is:

```sh
-destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2'
```

If that exact simulator is unavailable locally, substitute another installed iOS 26 simulator. Visual baselines, when added, are authoritative only for the documented iPhone 17 Pro / iOS 26.2 destination.

All local test artifacts should stay under:

```text
.build/DerivedData
.build/TestResults/
.build/coverage/
```

### Current Test Inventory

Existing tools:

- Unit: XCTest through the `ScrollDownSportsTests` target in the `ScrollDownSports` scheme.
- Component: SwiftUI render snapshots use Point-Free SnapshotTesting through the `ScrollDownSportsTests` target; component-adjacent behavior is also covered by view-state and source invariant XCTest cases.
- E2E/UI: no UI test target, test plan, or simulator automation harness is configured.
- Visual: component baselines are committed under `ScrollDownSportsTests/__Snapshots__`.
- Coverage: the `ScrollDownSports` scheme gathers coverage for the app target, emits `xccov` JSON locally and in CI, and checks the filtered baseline with `Scripts/check_xccov_thresholds.swift`.
- CI: `.github/workflows/ci.yml` regenerates the Xcode project, builds, runs XCTest with coverage, emits `xccov` JSON reports, checks coverage, and uploads result artifacts.

Existing tests:

- Domain logic: game windows, DTO decoding and mapping, home timeline grouping/filtering/anchors, persistence, event diffing, stream filtering/order, restore target resolution, background refresh, sports renderer routing, score hiding, and stats/scoreboard presentation.
- Components: view-state and source invariant coverage for home cards, game headers, scoreboard reach, sticky detail chrome, stream controls, and shared sports theme surfaces.
- Screens: no automated rendered-screen tests currently launch Home or Game Detail in a simulator.
- Flows: no automated UI flow currently opens the app, navigates between screens, scrolls the detail stream, or asserts rendered output.

Gaps:

- Resume progress: unit/state coverage exists; simulator scroll-restore flow coverage is missing.
- Home timeline anchor: unit coverage exists; rendered home launch/anchor verification is missing.
- Score-at-bottom: unit/state coverage exists; UI and accessibility spoiler-safety coverage is missing.
- Fake data leakage: persistence purge coverage exists; rendered production-feed leakage checks are missing.
- Period formatting: targeted formatting coverage exists; broader sport/event matrix coverage is missing.
- Raw enum mapping: detail validation and label suppression coverage exists; full fallback matrix coverage is missing.
- Visual regression: no baseline screenshots, diff output, or visual gate exists.

### Current Gates

Generate the Xcode project:

```sh
xcodegen generate
```

Build the app for iOS Simulator:

```sh
xcodebuild \
  -project ScrollDownSports.xcodeproj \
  -scheme ScrollDownSports \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedData \
  build
```

Run the XCTest unit gate:

```sh
xcodebuild \
  -project ScrollDownSports.xcodeproj \
  -scheme ScrollDownSports \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
  -derivedDataPath .build/DerivedData \
  -resultBundlePath .build/TestResults/ScrollDownSports.xcresult \
  -enableCodeCoverage YES \
  test \
  -only-testing:ScrollDownSportsTests
```

Generate and check coverage reports from the current XCTest target:

```sh
mkdir -p .build/coverage
xcrun xccov view --report .build/TestResults/ScrollDownSports.xcresult
xcrun xccov view --report --json .build/TestResults/ScrollDownSports.xcresult > .build/coverage/xccov-report.json
xcrun xccov view --archive --file-list --json .build/TestResults/ScrollDownSports.xcresult > .build/coverage/xccov-files.json
swift Scripts/check_xccov_thresholds.swift \
  --report .build/coverage/xccov-report.json \
  --config Config/coverage-thresholds.json \
  --repo-root "$PWD"
```

### Planned Gates

These commands define the native iOS gate names and artifact paths for the next test targets. They are not active until a `ScrollDownSportsUITests` target and deterministic fixture launch mode are added to the scheme.

UI smoke:

```sh
xcodebuild \
  -project ScrollDownSports.xcodeproj \
  -scheme ScrollDownSports \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
  -derivedDataPath .build/DerivedData \
  -resultBundlePath .build/TestResults/UISmoke.xcresult \
  test \
  -only-testing:ScrollDownSportsUITests/HomeSmokeTests \
  -only-testing:ScrollDownSportsUITests/PinnedGameSmokeTests \
  -only-testing:ScrollDownSportsUITests/GameDetailSmokeTests \
  -only-testing:ScrollDownSportsUITests/OfflineSmokeTests \
  -only-testing:ScrollDownSportsUITests/BackgroundStateSmokeTests
```

Visual regression:

```sh
xcodebuild \
  -project ScrollDownSports.xcodeproj \
  -scheme ScrollDownSports \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
  -derivedDataPath .build/DerivedData \
  -resultBundlePath .build/TestResults/Visual.xcresult \
  test \
  -only-testing:ScrollDownSportsTests/HomeVisualRegressionTests \
  -only-testing:ScrollDownSportsTests/GameDetailVisualRegressionTests \
  -only-testing:ScrollDownSportsTests/HomeGameCardSnapshotTests \
  -only-testing:ScrollDownSportsTests/HomeSectionSnapshotTests \
  -only-testing:ScrollDownSportsTests/GameDetailChromeSnapshotTests \
  -only-testing:ScrollDownSportsTests/EventAndScoreboardSnapshotTests \
  -only-testing:ScrollDownSportsTests/StatSectionSnapshotTests
```

Record visual baselines only when the visual change is intentional:

```sh
SNAPSHOT_RECORD=1 \
xcodebuild \
  -project ScrollDownSports.xcodeproj \
  -scheme ScrollDownSports \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
  -derivedDataPath .build/DerivedData \
  -resultBundlePath .build/TestResults/VisualRecord.xcresult \
  test \
  -only-testing:ScrollDownSportsTests/HomeVisualRegressionTests \
  -only-testing:ScrollDownSportsTests/GameDetailVisualRegressionTests
```

Snapshot recording is disabled by default. Missing or changed baselines fail unless `SNAPSHOT_RECORD=1` is set for an intentional recording run.

Visual baselines live under:

```text
ScrollDownSportsTests/__Snapshots__/
```

Review snapshot diffs as product changes, not just image churn. Intentional updates should preserve density, spacing rhythm, dominant color balance, and the catch-up-first hierarchy; regressions include card-size explosions, duplicated controls, overlapping floating pills, clipped core labels, repeated score modules, and low-value repeated boxes that flatten the visual hierarchy.

Accessibility:

```sh
xcodebuild \
  -project ScrollDownSports.xcodeproj \
  -scheme ScrollDownSports \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
  -derivedDataPath .build/DerivedData \
  -resultBundlePath .build/TestResults/Accessibility.xcresult \
  test \
  -only-testing:ScrollDownSportsUITests/AccessibilityAuditTests
```

The future accessibility gate must enforce the same spoiler-safety rule as the UI: scores cannot appear in labels before the scoreboard has been reached.

### Full Local Gate

Run the current full local gate:

```sh
xcodegen generate

xcodebuild \
  -project ScrollDownSports.xcodeproj \
  -scheme ScrollDownSports \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedData \
  build

xcodebuild \
  -project ScrollDownSports.xcodeproj \
  -scheme ScrollDownSports \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
  -derivedDataPath .build/DerivedData \
  -resultBundlePath .build/TestResults/ScrollDownSports.xcresult \
  -enableCodeCoverage YES \
  test \
  -only-testing:ScrollDownSportsTests

mkdir -p .build/coverage
xcrun xccov view --report --json .build/TestResults/ScrollDownSports.xcresult > .build/coverage/xccov-report.json
xcrun xccov view --archive --file-list --json .build/TestResults/ScrollDownSports.xcresult > .build/coverage/xccov-files.json
swift Scripts/check_xccov_thresholds.swift \
  --report .build/coverage/xccov-report.json \
  --config Config/coverage-thresholds.json \
  --repo-root "$PWD"
```

After UI smoke, visual, and accessibility targets exist, the full local gate is:

```sh
xcodegen generate

xcodebuild \
  -project ScrollDownSports.xcodeproj \
  -scheme ScrollDownSports \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
  -derivedDataPath .build/DerivedData \
  -resultBundlePath .build/TestResults/All.xcresult \
  -enableCodeCoverage YES \
  test
```

The future full gate must use deterministic fixtures, not the live SDA API, for UI smoke, visual, and accessibility coverage.

## Deployment Basics

The app target uses bundle identifier `com.dock108.scrolldownsports`, iOS deployment target `18.0`, and Release settings from `Config/Secrets.xcconfig`. `DEVELOPMENT_TEAM` is empty in `project.yml`, so signing must be supplied before archive or App Store distribution.

Both Debug and Release builds read `SDA_API_BASE_URL` and `SDA_API_KEY` into `Info.plist` as `SDABaseURL` and `SDAApiKey`; any Release credential value supplied through those build settings becomes part of the built app configuration.

The checked-in GitHub Actions workflow uses the same scheme, stable result bundle path, coverage report paths, and coverage checker documented above.

## Docs

- [App reference](docs/app-reference.md)
- [Documentation consolidation audit](docs/audits/docs-consolidation.md)
