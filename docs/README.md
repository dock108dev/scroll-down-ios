# Documentation

Technical documentation for the Scroll Down iOS app.

## Overview

This app provides a native iOS experience for catching up on sports games at your own pace. It's built with SwiftUI and follows MVVM architecture.

## Guides

| Document | Description |
|----------|-------------|
| [Architecture](architecture.md) | MVVM structure, data flow, and design principles |
| [Development](development.md) | Mock mode, testing, debugging, QA checklist |
| [Changelog](CHANGELOG.md) | Feature history and version updates |
| [Agent Notes](../AGENTS.md) | Context for AI coding assistants |

## Quick Reference

- **Environment toggle:** `AppConfig.shared.environment`
- **Run tests:** `xcodebuild test -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Key screens:** HomeView → GameDetailView → CompactTimelineView
