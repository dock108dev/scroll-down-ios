# AGENTS.md — Scroll Down (iOS App)

> This file provides context for AI agents (Codex, Cursor, Copilot) working on this codebase.

## Quick Context

**What is this?** Native iOS client for Scroll Down Sports — a thoughtful way to catch up on games.

**Tech Stack:** Swift, SwiftUI, MVVM architecture

**Key Directories:**
- `ScrollDown/Sources/` — App source code
- `ScrollDown/Resources/` — Mock data and assets
- `ScrollDown/Tests/` — Unit tests

## Core Product Principles

1. **Progressive disclosure** — Show context before scores; users arrive after games are played
2. **User-controlled pacing** — They decide when to reveal results
3. **Mobile-first experience** — Designed for touch navigation and vertical scrolling

## Coding Standards

See `.cursorrules` for complete coding standards. Key points:

1. **MVVM Architecture** — Views don't contain business logic
2. **Swift Conventions** — Follow Swift API Design Guidelines
3. **SwiftUI** — Every view needs a `#Preview`, support dark mode
4. **No Force Unwrapping** — Use guard statements
5. **Incremental Changes** — Don't rewrite, improve incrementally

## Related Repos

- `scroll-down-api-spec` — API specification (source of truth for models)
- `scroll-down-sports-ui` — Web frontend
- `sports-data-admin` — Backend implementation

## Do NOT

- Break progressive disclosure defaults
- Add dependencies without justification
- Use `print()` in production code

## Data Contract

Models should align with `scroll-down-api-spec`. When API changes:
1. Spec updates first
2. Then update Swift models to match

## Testing

- Run: `xcodebuild test -scheme ScrollDown`
