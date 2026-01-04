# Scroll Down Sports — iOS App

Spoiler-free sports recaps for iOS. Built with SwiftUI.

## Quick Start

```bash
# Open in Xcode
open ScrollDown.xcodeproj

# Or build from command line
xcodebuild -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**Requirements:** Xcode 15+, iOS 16+

## Architecture

```
ScrollDown/Sources/
├── Models/         # Codable data models (spec-aligned)
├── ViewModels/     # Business logic (MVVM)
├── Views/Screens/  # SwiftUI views
├── Components/     # Reusable UI components
├── Networking/     # GameService protocol + implementations
└── Mock/           # Mock data for development
```

**Data Flow:** Views → ViewModels → GameService (mock or real)

## Development

The app runs in **mock mode** by default—no backend required. Toggle via `AppConfig.dataMode`.

### Key Principles
- **Spoiler-safe by default** — scores hidden until user chooses to reveal
- **MVVM architecture** — views don't contain business logic
- **Spec-aligned models** — match [scroll-down-api-spec](https://github.com/dock108/scroll-down-api-spec)

### Compact Timeline
Tap a compact timeline moment to open its expanded view with a play-by-play slice.
Timeline scores surface via separators (live, halftime, period end) instead of inside play rows.

### Running Tests

```bash
xcodebuild test -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Related Repos

| Repo | Purpose |
|------|---------|
| `scroll-down-api-spec` | API specification (source of truth) |
| `scroll-down-sports-ui` | Web frontend |
| `sports-data-admin` | Backend implementation |

## License

Proprietary — All rights reserved
