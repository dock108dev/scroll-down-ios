# Documentation Consolidation Audit

## Changed Files

- `docs/testing-and-ci.md`: corrected the canonical iPad destination from M4 to M5, replaced stale `OS=latest` CI matrix language with exact iOS 26.2 destinations, and documented that `ipad-visual` uses the canonical phone snapshot host while iPad coverage comes from explicit snapshot fixture sizes.
- `docs/local-development.md`: removed physical-phone networking and first-install guidance that is not represented in repository code, config, or CI. Kept only XcodeGen, build-setting, signing, simulator-gate, and UI-test fixture behavior that is backed by `project.yml`, `Config/Secrets.xcconfig`, `Info.plist`, `SDAApiClient`, `AppEnvironment`, and `Scripts/local_gate.sh`.
- `docs/maintenance.md`: refreshed the current over-500-LOC list and removed the stale `SituationDiagramViews.swift` over-threshold entry.
- `docs/audits/cleanup-report.md`: rewrote the prior pass audit into a current cleanup constraint report because source size-note comments refer contributors to the cleanup report.
- `docs/audits/docs-consolidation.md`: added this pass record.

## Audited Without Edits

- `README.md`: already contained the required project summary, local run commands, deployment basics, and `/docs` pointers, and its deployment statements matched `project.yml`, `Config/Secrets.xcconfig`, `Info.plist`, and `.github/workflows/ci.yml`.
- `docs/app-reference.md`: matched the current app entry point, navigation shells, API client endpoints, DTO validation, home window, persistence keys, refresh loops, background scheduler, renderer registry, score-spoiler behavior, and build metadata.

## Removed As Unverifiable Or Outdated

- Removed claims that iPad visual gates run on the pinned iPad simulator destination; current `Scripts/local_gate.sh` unsets `TEST_DESTINATION` for `ipad-visual`.
- Removed stale M4 iPad simulator references; current local gate and CI use iPad Pro 13-inch (M5) and iPad Pro 11-inch (M5) on iOS 26.2.
- Removed `OS=latest` CI matrix descriptions; current `.github/workflows/ci.yml` pins matrix destinations to iOS 26.2.
- Removed local physical-phone backend advice and first-install prompt handling from contributor docs because those are platform operating notes, not repo-verifiable behavior.
- Removed historical cleanup-pass details and command results from `docs/audits/cleanup-report.md` because they described prior edits rather than current code.

## Intentional Gaps

- The docs do not enumerate every DTO field or snapshot file. The maintained contract is the endpoint shape, required detail validation, score-source behavior, and gate ownership; exhaustive field lists would duplicate source files and drift.
- The docs do not describe ignored `.aidlc/` planning files as project documentation. `.gitignore` marks `.aidlc/` as local working state, and root documentation remains limited to `README.md` plus untouched customer-voice files such as `BRAINDUMP.md`.

## Validation

- `git diff --check`
- `Scripts/local_gate.sh script-checks`

## Escalations

None.
