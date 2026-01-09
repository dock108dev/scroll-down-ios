# Documentation

Technical documentation for the Scroll Down iOS app.

## Overview

This app provides a native iOS experience for catching up on sports games at your own pace. It's built with SwiftUI and follows MVVM architecture.

## Core Guides

| Document | Description |
|----------|-------------|
| [Architecture](architecture.md) | MVVM structure, data flow, and design principles |
| [Development](development.md) | Mock mode, testing, debugging, QA checklist |
| [Changelog](CHANGELOG.md) | Feature history and version updates |
| [Agent Notes](../AGENTS.md) | Context for AI coding assistants |

## Beta Features

| Document | Description |
|----------|-------------|
| [Beta Time Override](BETA_TIME_OVERRIDE.md) | Time-snapshotted mode for testing historical data |
| [Quick Start Guide](BETA_TIME_OVERRIDE_QUICKSTART.md) | Fast reference for time override usage |

## Beta Development Phases

| Phase | Status | Description | Summary |
|-------|--------|-------------|---------|
| [Phase A](PHASE_A.md) | ✅ Complete | Routing and trust fixes | — |
| [Phase B](PHASE_B.md) | ✅ Complete | Real backend feeds | — |
| [Phase C](PHASE_C.md) | ✅ Complete | Timeline usability improvements | [Summary](PHASE_C_SUMMARY.md) |
| [Phase D](PHASE_D.md) | ✅ Complete | Recaps and reveal control | [Summary](PHASE_D_SUMMARY.md) |
| [Phase E](PHASE_E.md) | ✅ Complete | Social blending (optional, reveal-aware) | [Summary](PHASE_E_SUMMARY.md) |
| [Phase F](PHASE_F.md) | ✅ Complete | Quality polish (empty states, loading, typography) | [Summary](PHASE_F_SUMMARY.md) |

**Status:** 🎉 Beta Ready - All phases complete

## Implementation Summaries

| Document | Description |
|----------|-------------|
| [Beta Time Override Summary](BETA_TIME_OVERRIDE_SUMMARY.md) | Complete implementation details |
| [Beta Time Override Validation](BETA_TIME_OVERRIDE_VALIDATION.md) | Validation checklist and test scenarios |
| [Beta Time Override Commit Guide](BETA_TIME_OVERRIDE_COMMIT.md) | Git commit guidance |
| [Phase Commit Messages](COMMIT_MESSAGE.md) | Historical commit message templates |

## Quick Reference

- **Environment toggle:** `AppConfig.shared.environment`
- **Run tests:** `xcodebuild test -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Key screens:** HomeView → GameDetailView → CompactTimelineView
