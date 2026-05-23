# Documentation Consolidation Audit

## Changed Files

- `README.md`: Rewritten as the root quickstart. It now contains one project paragraph, local build/test commands, deployment basics, and links into `/docs`.
- `docs/app-reference.md`: Added as the single durable reference for current app behavior, API configuration, local persistence, refresh behavior, presentation routing, and build metadata.
- `docs/audits/cleanup-report.md`: Deleted. It described an earlier code cleanup pass rather than current project behavior, duplicated source-control history, and did not serve this documentation set.
- `docs/audits/docs-consolidation.md`: Added as the required record of this documentation pass.
- `BRAINDUMP.md`: Intentionally unchanged because it is customer voice.

## Statements Removed As Unverifiable Or Outdated

- Removed the README claim that the app reads the same SDA shape as a tagged `scroll-down-web` release. This repo does not contain that tag or release reference.
- Removed the README claim that the home list spans 72 hours before now through 48 hours after now. Current code uses `GameWindow.home`, which spans seven days before today through the end of today in the New York calendar.
- Removed the README claim that the upstream currently returns `401 Missing API key` without credentials. That is a live service condition, not a stable claim from checked-in code.
- Removed the README statement that the game page is ordered exactly as play-by-play, player stats, team stats, then the only visible score or box-score section at the bottom. Current code does order those sections that way, but the new docs describe the actual `GameDetailView` structure without the unverifiable "only visible" phrasing.
- Removed the previous cleanup report's implementation claims from the docs set. They are historical pass notes, not current operational documentation.

## Intentional Gaps

- `.aidlc` markdown files were not consolidated into product docs. They are tool working artifacts, not user-facing project documentation, and the repo `.gitignore` already treats AIDLC run/report/archive output as generated workspace state.
- `build/DerivedData` text files were not rewritten or moved. They are generated Xcode build outputs under an ignored build directory, not source documentation.
- No CI runbook was added because the repo has no checked-in `.github` workflow files.

## Validation

- Audited app entry points: `ScrollDownSportsApp`, `AppDelegate`, `BackgroundDataScheduler`, and `ContentView`.
- Audited API and config surfaces: `SDAApiClient`, `GameWindow`, `Info.plist`, `project.yml`, `Config/Secrets.xcconfig`, and `Config/Local.xcconfig.example`.
- Audited persistence and refresh behavior: `GameStateStore`, `UserDefaultsGameStateStore`, `BackgroundRefreshState`, `BackgroundRefreshService`, `HomeViewModel`, and `GameDetailViewModel`.
- Audited presentation behavior: `HomeView`, `HomeGameCardState`, `GameDetailView`, `StreamControlBar`, `ScoreboardCardViews`, `DetailStreamMode`, and `SportRendererRegistry`.
- Verified with `xcodebuild -project ScrollDownSports.xcodeproj -scheme ScrollDownSports -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' -derivedDataPath .build/DerivedData test`: 89 tests passed, 0 failures.

## Escalations

None.
