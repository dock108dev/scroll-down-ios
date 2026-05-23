# Documentation Consolidation Audit

## Changed Files

- `README.md`: Tightened as the root quickstart with one project paragraph, the Xcode/XcodeGen prerequisite, local gate commands, credential setup, deployment basics, and links into `/docs`.
- `docs/audits/cleanup-report.md`: Kept as an audit-only note because `ScrollDownSports/Views/GameDetailView.swift` contains a current size-justification comment that points to the cleanup report. The file was tightened to remove unverified historical test-result counts.
- `docs/audits/docs-consolidation.md`: Updated as the record of this pass.

## Reviewed Without Edits

- `docs/app-reference.md`: Kept as the durable code reference for app entry, views, API configuration, game windows, local persistence, refresh behavior, presentation routing, and build metadata.
- `docs/testing-and-ci.md`: Kept as the focused reference for `Scripts/local_gate.sh`, simulator destination behavior, coverage policy, and `.github/workflows/ci.yml`.
- `BRAINDUMP.md`: Intentionally unchanged because it is customer voice.

## Statements Removed As Unverifiable Or Outdated

- Removed cleanup-report test-result counts for a full `xcodebuild test` run because those counts are not provable from checked-in code. Current validation commands belong in this audit.
- Did not reintroduce older claims that no GitHub Actions workflow is checked in, or that `GameWindow.home` covers seven days before today through the end of today. Current code and config show `.github/workflows/ci.yml` is present and `GameWindow.home` starts 72 hours before the current instant and ends tomorrow in the New York calendar.
- Kept detailed test inventory, coverage policy, visual regression, accessibility, and performance-gate details out of the root README because those details belong in `docs/testing-and-ci.md`.
- Avoided documenting live SDA service behavior, release readiness, App Store status, or production credential values because those are not provable from checked-in code and config.

## Intentional Gaps

- `.aidlc` markdown was not moved into `/docs` because `.gitignore` marks `.aidlc/` as generated working state, and none of its markdown files are tracked project documentation.
- Markdown files under `.build`, `build`, and `DerivedData` were not moved or edited because they are generated dependency or Xcode artifacts under ignored build directories.
- `Config/Local.xcconfig` was not documented beyond setup mechanics because it is ignored local state and may contain machine-specific credentials.
- `docs/audits/cleanup-report.md` was not linked from the README because it is a narrow audit artifact for an in-code cleanup justification, not a primary reader entry point.

## Validation

- Audited tracked markdown inventory with `git ls-files '*.md'`.
- Audited ignored/generated documentation surfaces with `find . -path './.git' -prune -o -path './.build' -prune -o -path './build' -prune -o -name '*.md' -print` and `.gitignore`.
- Audited app entry and lifecycle: `ScrollDownSportsApp`, `AppDelegate`, `AppScenePhaseHandler`, and `BackgroundDataScheduler`.
- Audited API and configuration: `SDAApiClient`, `GameWindow`, `Info.plist`, `project.yml`, `Config/Secrets.xcconfig`, and `Config/Local.xcconfig.example`.
- Audited persistence and refresh behavior: `GameStateStore`, `UserDefaultsGameStateStore`, `BackgroundRefreshService`, `HomeViewModel`, and `GameDetailViewModel`.
- Audited presentation behavior: `ContentView`, `HomeView`, `HomeGameCardState`, `GameDetailView`, `DetailStreamMode`, and `SportRendererRegistry`.
- Audited test and CI surfaces: `Scripts/local_gate.sh`, `Scripts/check_xccov_thresholds.swift`, `Config/coverage-thresholds.json`, `Scripts/test_xccov_thresholds.sh`, `Scripts/test_ci_workflow_shape.sh`, `Scripts/test_local_gate.sh`, `.github/workflows/ci.yml`, `ScrollDownSportsTests`, and `ScrollDownSportsUITests`.
- Passed: `bash Scripts/local_gate.sh script-checks`.

## Escalations

None.
