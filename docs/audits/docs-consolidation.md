# Documentation Consolidation Audit

## Changed Files

- `README.md`: Kept the root quickstart lean and tightened the project paragraph to mention sport-rendered play-by-play, which is backed by the current renderer registry and detail play-row code.
- `docs/app-reference.md`: Added the current play-row situation and raw-feed detail behavior, replaced the vague v2 detail-contract sentence with the exact `SDAApiClient` rejection checks, corrected tennis routing to `TennisRenderer`, and documented the current situation-card policy, confidence gate, score-spoiler context, and pressure-board fallback model.
- `docs/testing-and-ci.md`: Tightened the current situation-card regression ownership split and corrected GitHub Actions wording so `ipad-visual` is described as pinned to the local-gate iPad destination while the other iPad gates use the workflow iPad matrix.
- `docs/audits/cleanup-report.md`: Rewritten as a current-only justification for the three in-code cleanup-report size notes, with current LOC counts and validation commands.
- `docs/audits/docs-consolidation.md`: Rewritten as the record of this documentation pass.

## Reviewed Without Edits

- `docs/device-install.md`: Kept because its backend targeting, ignored local override, signing, and CLI smoke instructions match `Config/Secrets.xcconfig`, `Config/Local.xcconfig.example`, `project.yml`, and `Scripts/local_gate.sh`.
- `BRAINDUMP.md`: Intentionally unchanged because it is customer voice.

## Statements Removed As Unverifiable Or Outdated

- Replaced the stale renderer statement that grouped tennis with generic sports; current `SportRendererRegistry` routes tennis to `TennisRenderer`.
- Replaced vague "v2 detail contract checks" wording with code-backed checks from `SDAApiClient`.
- Removed stale cleanup-report history about prior code edits, dead-code removal, fixture consolidation, and a prior unit-test result; those are not stable current documentation facts.
- Removed cleanup-report LOC values that no longer matched the current tree.
- Replaced GitHub Actions wording that could imply `ipad-visual` follows the workflow iPad matrix; `Scripts/local_gate.sh` pins that gate to iPad Pro 13-inch (M4) on iOS 26.2.
- Avoided documenting live SDA service behavior, release readiness, App Store status, or production credential values because those are not provable from checked-in code and config.

## Intentional Gaps

- `.aidlc` markdown was not moved into `/docs` because `.gitignore` marks `.aidlc/` as generated working state, and none of its markdown files are tracked project documentation.
- Markdown files under `.build`, `build`, and `DerivedData` were not moved or edited because they are generated dependency or Xcode artifacts under ignored build directories.
- `Config/Local.xcconfig` was not documented beyond setup mechanics because it is ignored local state and may contain machine-specific credentials.
- `docs/audits/cleanup-report.md` remains unlinked from the README because it is a narrow audit artifact for current in-code size justifications, not a primary reader entry point.
- Source files, tests, snapshots, and Xcode project files already had unrelated working-tree changes before this pass; this was a documentation-only pass, so they were reviewed for evidence but not edited.

## Validation

- Audited tracked markdown inventory with `git ls-files '*.md'`.
- Audited ignored/generated documentation surfaces with `find . -maxdepth 3` excluding `.git`, `.build`, `build`, and `DerivedData`.
- Audited app entry and lifecycle: `ScrollDownSportsApp`, `AppDelegate`, `AppScenePhaseHandler`, and `BackgroundDataScheduler`.
- Audited API and configuration: `SDAApiClient`, `GameWindow`, `SDADTOs`, `SDADomainMapper`, `Info.plist`, `PrivacyInfo.xcprivacy`, `project.yml`, `Config/Secrets.xcconfig`, and `Config/Local.xcconfig.example`.
- Audited persistence and refresh behavior: `GameStateStore`, `UserDefaultsGameStateStore`, `BackgroundRefreshService`, `HomeViewModel`, and `GameDetailViewModel`.
- Audited presentation behavior: `ContentView`, `HomeView`, `HomeSectionsView`, `HomeGameCardState`, `GameDetailView`, `CatchUpSections`, `PlayRow`, `DetailStreamMode`, `SportRendererRegistry`, situation metadata/rendering files, and situation-card tests.
- Audited test and CI surfaces: `Scripts/local_gate.sh`, `Scripts/check_xccov_thresholds.swift`, `Config/coverage-thresholds.json`, `Scripts/test_xccov_thresholds.sh`, `Scripts/test_ci_workflow_shape.sh`, `Scripts/test_local_gate.sh`, `Scripts/check_multitasking_project_invariants.rb`, `.github/workflows/ci.yml`, `ScrollDownSportsTests`, and `ScrollDownSportsUITests`.
- Passed: `Scripts/local_gate.sh script-checks`.

## Escalations

None.
