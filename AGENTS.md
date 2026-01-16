# AGENTS.md — Scroll Down (iOS App)

> Context for AI agents (Codex, Cursor, Copilot) working on this codebase.
> For Cursor-specific rules, see `.cursorrules`.

## Quick Context

**What is this?** Native iOS client for Scroll Down Sports — a thoughtful way to catch up on games.

**Tech Stack:** Swift, SwiftUI, MVVM architecture

**Key Directories:**
- `ScrollDown/Sources/` — App source code
- `ScrollDown/Resources/` — Assets
- `ScrollDown/Sources/Mock/` — Mock data for development
- `ScrollDown/Tests/` — Unit tests
- `docs/` — Technical documentation

## Core Product Principles

1. **Progressive disclosure** — Show context before scores; users arrive after games are played
2. **User-controlled pacing** — They decide when to reveal results
3. **Mobile-first experience** — Designed for touch navigation and vertical scrolling

## Architecture Overview

```
ScrollDownApp.swift          # App entry point
├── ContentView.swift        # Root navigation
├── Screens/
│   ├── Home/                # Game list (HomeView)
│   └── Game/                # Game detail (GameDetailView + extensions)
├── ViewModels/              # Presentation logic
├── Models/                  # Data models (aligned with API spec)
├── Networking/              # API services
└── Components/              # Reusable UI components
```

## Related Repos

- `scroll-down-api-spec` — API specification (source of truth for models)
- `scroll-down-sports-ui` — Web frontend
- `sports-data-admin` — Backend implementation

## Data Contract

Models align with `scroll-down-api-spec`. When API changes:
1. Spec updates first
2. Then update Swift models to match

## Testing

```bash
xcodebuild test -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Do NOT

- **Auto-commit changes** — Wait for user to review and commit manually
- Run commands that require interactive input
- Run long-running commands (>5s) without periodic output
- Update remote servers via SSH without explicit request
- Break progressive disclosure defaults
- Add dependencies without justification
- Use `print()` in production code (use OSLog/Logger instead)
