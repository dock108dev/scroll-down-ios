# AIDLC Planning Index

## Intent Source (authoritative)
- BRAINDUMP.md

## Reference Docs (optional context — never expand scope)
- README.md

## Discovery (pre-built — current repo state)
- .aidlc/discovery/findings.md
- .aidlc/discovery/topics.json

## Research (pre-built — answers to discovery topics)
- .aidlc/research/backend-presentation-contract.md
- .aidlc/research/background-refresh-product-role.md
- .aidlc/research/core-model-neutralization.md
- .aidlc/research/event-headline-normalization.md
- .aidlc/research/event-importance-model.md
- .aidlc/research/follow-live-edge-state.md
- .aidlc/research/game-progress-restore-by-event.md
- .aidlc/research/home-card-state-contract.md
- .aidlc/research/home-section-information-architecture.md
- .aidlc/research/live-refresh-scroll-contract.md
- .aidlc/research/local-pin-progress-store.md
- .aidlc/research/new-event-diffing.md
- .aidlc/research/period-grouping-clock-labels.md
- .aidlc/research/pin-to-bottom-conflict.md
- .aidlc/research/priority-mode-redesign.md
- .aidlc/research/product-invariant-test-coverage.md
- .aidlc/research/raw-feed-expansion-state.md
- .aidlc/research/scoreboard-grid-data-availability.md
- .aidlc/research/scoreboard-reached-detection.md
- .aidlc/research/scoreboard-reveal-vs-layout-spoiler.md
- .aidlc/research/sport-renderer-boundaries.md
- .aidlc/research/stats-impact-table-shape.md
- .aidlc/research/sticky-header-nav-treatment.md
- .aidlc/research/visual-token-system.md

## Existing Issues (20 files in .aidlc/issues/)
Read individual issue files for full specs:
- .aidlc/issues/ISSUE-001.md
- .aidlc/issues/ISSUE-002.md
- .aidlc/issues/ISSUE-003.md
- .aidlc/issues/ISSUE-004.md
- .aidlc/issues/ISSUE-005.md
- .aidlc/issues/ISSUE-006.md
- .aidlc/issues/ISSUE-007.md
- .aidlc/issues/ISSUE-008.md
- .aidlc/issues/ISSUE-009.md
- .aidlc/issues/ISSUE-010.md
- .aidlc/issues/ISSUE-011.md
- .aidlc/issues/ISSUE-012.md
- .aidlc/issues/ISSUE-013.md
- .aidlc/issues/ISSUE-014.md
- .aidlc/issues/ISSUE-015.md
- .aidlc/issues/ISSUE-016.md
- .aidlc/issues/ISSUE-017.md
- .aidlc/issues/ISSUE-018.md
- .aidlc/issues/ISSUE-019.md
- .aidlc/issues/ISSUE-020.md

## Issue Backlog Summary
- Total issues: 20
- Completion: 0/20 (0.0%)
- Priority totals: high=13, medium=7, low=0
- Status totals: pending=20

### Category Rollup (Labels)
- feature: 10
- infra: 7
- visual: 6
- progress: 5
- all-sports: 4
- pinning: 4
- live: 3
- stream: 3
- architecture: 2
- detail: 2
- home: 2
- api: 1
- background-refresh: 1
- design-system: 1
- header: 1
- invariants: 1
- motion: 1
- navigation: 1
- persistence: 1
- polish: 1
- presentation: 1
- rendering: 1
- scoreboard: 1
- scroll: 1
- stats: 1
- tests: 1

### Active Issues
- ISSUE-001 [pending] [high] — Add shared sports design tokens and surface components labels: infra, design-system, visual
- ISSUE-002 [pending] [high] — Separate API DTOs from sport-neutral domain models labels: infra, architecture, all-sports
- ISSUE-003 [pending] [high] — Add injectable local game state store for pins and progress labels: infra, persistence, pinning, progress
- ISSUE-004 [pending] [high] — Implement event identity baselines and new-play diffing labels: infra, live, progress
- ISSUE-005 [pending] [high] — Rebuild home information architecture around Pinned, Today, Earlier labels: feature, home, pinning
- ISSUE-006 [pending] [high] — Create state-aware home game cards labels: feature, home, visual
- ISSUE-007 [pending] [high] — Add detail header card and stream control bar labels: feature, detail, pinning
- ISSUE-008 [pending] [high] — Replace P1/P2/P3 with persistent Key, Flow, Full modes labels: feature, stream, progress
- ISSUE-009 [pending] [high] — Persist and restore reading position by event id labels: feature, progress, detail
- ISSUE-010 [pending] [high] — Implement non-hijacking live refresh and jump-to-latest behavior labels: feature, live, scroll
- ISSUE-011 [pending] [medium] — Render headline-first event cards with raw-feed expansion labels: feature, stream, visual
- ISSUE-012 [pending] [medium] — Group the stream by sport periods and fix duplicated labels labels: feature, stream, all-sports
- ISSUE-013 [pending] [medium] — Redesign bottom scoreboard card and reached-scoreboard state labels: feature, scoreboard, progress
- ISSUE-014 [pending] [medium] — Replace stat pill walls with impact summaries and compact tables labels: feature, stats, visual
- ISSUE-015 [pending] [medium] — Add product invariant test coverage for scroll-down behavior labels: tests, invariants
- ISSUE-016 [pending] [high] — Add sport renderer registry and move sport-specific display logic out of core screens labels: infra, architecture, all-sports, rendering
- ISSUE-017 [pending] [high] — Decode and consume optional backend presentation fields with legacy fallbacks labels: infra, api, presentation, all-sports
- ISSUE-018 [pending] [high] — Make background refresh update persisted home and pinned-game state labels: infra, background-refresh, pinning, live
- ISSUE-019 [pending] [medium] — Make navigation and filters opaque to prevent header ghosting labels: visual, navigation, header
- ISSUE-020 [pending] [medium] — Apply final sports-native visual identity, motion, and screenshot polish labels: polish, visual, motion

### Completed Issues
- none

## Other Project Docs
- .build/DerivedData/Build/Intermediates.noindex/ScrollDownSports.build/Debug-iphonesimulator/ScrollDownSports.build/ScrollDownSports-DebugDylibInstallName-normal-arm64.txt
- .build/DerivedData/Build/Intermediates.noindex/ScrollDownSports.build/Debug-iphonesimulator/ScrollDownSports.build/ScrollDownSports-DebugDylibPath-normal-arm64.txt
- .build/DerivedData/Build/Intermediates.noindex/ScrollDownSports.build/Debug-iphonesimulator/ScrollDownSports.build/ScrollDownSports-ExecutorLinkFileList-normal-arm64.txt
- .build/DerivedData/Build/Intermediates.noindex/XCBuildData/0dafd5a3b283502437c91aff45fc74b2.xcbuilddata/target-graph.txt
- .build/DerivedData/Build/Intermediates.noindex/XCBuildData/d0200a50d810885e72a6abe4e6f0b54e.xcbuilddata/target-graph.txt
- BRAINDUMP.md
