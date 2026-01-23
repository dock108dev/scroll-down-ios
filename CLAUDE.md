# Cursor Rules for Scroll Down (iOS App)

## Core Product Principles
1. **Progressive disclosure** — Show context before scores; users arrive after games are played
2. **User-controlled pacing** — They decide when to reveal results
3. **Mobile-first experience** — Designed for touch navigation and vertical scrolling

## Architecture
- **MVVM Architecture** — Views don't contain business logic
- **Swift Conventions** — Follow Swift API Design Guidelines
- **SwiftUI** — Every view needs a `#Preview`, support dark mode
- **No Force Unwrapping** — Use guard statements
- **Incremental Changes** — Don't rewrite, improve incrementally

## Coding Standards
1. Follow Swift API Design Guidelines
2. Use meaningful names for UI components
3. Keep view models focused on presentation logic
4. Add accessibility support where appropriate
5. Test UI components with previews

## Data Contract
Models should align with `scroll-down-api-spec`. When API changes:
1. Spec updates first
2. Then update Swift models to match

## Do NOT
- **Auto-commit changes** — Wait for user to review and commit manually
- Run commands that require interactive input to quit
- Run long-running commands (>5 seconds) without verbose logging (use logging that outputs every 30 seconds or so)
- Update code on remote servers through SSH unless specifically asked — all code changes should be done locally and applied through approved channels only
- Break progressive disclosure defaults
- Add dependencies without justification
- Use `print()` in production code
