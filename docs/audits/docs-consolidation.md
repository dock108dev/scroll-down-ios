# Documentation Consolidation Audit

## Changed Files

- `README.md`: Rewritten as the root quickstart with one project paragraph, local gate commands, credential setup, deployment basics, and links into `/docs`.
- `docs/app-reference.md`: Rewritten as the durable code reference for app entry, views, API configuration, game windows, local persistence, refresh behavior, presentation routing, and build metadata.
- `docs/testing-and-ci.md`: Added as the focused reference for `Scripts/local_gate.sh`, simulator destination behavior, coverage policy, and `.github/workflows/ci.yml`.
- `docs/audits/cleanup-report.md`: Deleted because it described a prior code cleanup pass, not current project behavior or operator guidance.
- `docs/audits/docs-consolidation.md`: Rewritten as the record of this pass.
- `BRAINDUMP.md`: Intentionally unchanged because it is customer voice.

## Statements Removed As Unverifiable Or Outdated

- Removed the stale statement that no GitHub Actions workflow is checked in. `.github/workflows/ci.yml` is present and defines PR, push, scheduled, and manual gates.
- Removed the stale statement that `GameWindow.home` covers seven days before today through the end of today. Current code starts 72 hours before the current instant and ends tomorrow in the New York calendar.
- Removed README-level test inventory, coverage policy, visual regression, accessibility, and performance details. Those claims were moved to `docs/testing-and-ci.md` so the root README stays lean.
- Removed the cleanup report's implementation history from the active docs set. It was historical pass output, not current documentation.
- Avoided documenting live SDA service behavior, release readiness, App Store status, or production credential values because those are not provable from checked-in code and config.

## Intentional Gaps

- `.aidlc` markdown was not moved into `/docs` because `.gitignore` marks `.aidlc/` as generated working state, and none of its markdown files are tracked project documentation.
- Markdown files under `.build`, `build`, and `DerivedData` were not moved or edited because they are generated dependency or Xcode artifacts under ignored build directories.
- `Config/Local.xcconfig` was not documented beyond setup mechanics because it is ignored local state and may contain machine-specific credentials.

## Validation

- Audited tracked markdown inventory with `git ls-files '*.md'`.
- Audited ignored/generated documentation surfaces with `find . -path './.git' -prune -o -name '*.md' -print` and `.gitignore`.
- Audited app entry and lifecycle: `ScrollDownSportsApp`, `AppDelegate`, `AppScenePhaseHandler`, and `BackgroundDataScheduler`.
- Audited API and configuration: `SDAApiClient`, `GameWindow`, `Info.plist`, `project.yml`, `Config/Secrets.xcconfig`, and `Config/Local.xcconfig.example`.
- Audited persistence and refresh behavior: `GameStateStore`, `UserDefaultsGameStateStore`, `BackgroundRefreshService`, `HomeViewModel`, and `GameDetailViewModel`.
- Audited presentation behavior: `ContentView`, `HomeView`, `HomeGameCardState`, `GameDetailView`, `DetailStreamMode`, and `SportRendererRegistry`.
- Audited test and CI surfaces: `Scripts/local_gate.sh`, `Scripts/check_xccov_thresholds.swift`, `Config/coverage-thresholds.json`, `Scripts/test_xccov_thresholds.sh`, `Scripts/test_ci_workflow_shape.sh`, `Scripts/test_local_gate.sh`, `.github/workflows/ci.yml`, `ScrollDownSportsTests`, and `ScrollDownSportsUITests`.
- Passed: `bash Scripts/local_gate.sh script-checks`.

## Escalations

None.
