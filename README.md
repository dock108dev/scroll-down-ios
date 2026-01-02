# Scroll Down Sports iOS App

A SwiftUI iOS app for consuming sports game data, designed to work with the [Scroll Down API Spec](https://github.com/dock108/scroll-down-api-spec).

## Features

- 📱 **SwiftUI** native iOS app (iOS 16+)
- 🎭 **Mock-first development** - works without network
- 🔄 **Swappable data layer** - easily switch between mock and real API
- 📋 **Spec-aligned models** - Codable types match OpenAPI exactly
- 🏠 **Spoiler-safe game list** with league filtering
- 📊 **Game detail** with stats, odds, social posts, and play-by-play

## Project Structure

```
scroll-down-app/
├── ScrollDown.xcodeproj/
└── ScrollDown/
    ├── Sources/
    │   ├── ScrollDownApp.swift      # App entry point
    │   ├── ContentView.swift        # Root view
    │   ├── AppConfig.swift          # Data mode configuration
    │   ├── Models/                  # Codable data models
    │   │   ├── Enums.swift
    │   │   ├── Game.swift
    │   │   ├── GameSummary.swift
    │   │   ├── GameListResponse.swift
    │   │   ├── GameDetailResponse.swift
    │   │   ├── TeamStat.swift
    │   │   ├── PlayerStat.swift
    │   │   ├── OddsEntry.swift
    │   │   ├── SocialPost.swift
    │   │   ├── PlayEntry.swift
    │   │   └── PbpEvent.swift
    │   ├── Mock/                    # Mock data layer
    │   │   ├── MockLoader.swift
    │   │   └── games/               # Mock JSON files
    │   │       ├── game-001.json
    │   │       ├── game-002.json
    │   │       ├── game-list.json
    │   │       ├── pbp-001.json
    │   │       └── social-posts.json
    │   ├── Networking/              # API service layer
    │   │   ├── GameService.swift    # Protocol definition
    │   │   ├── MockGameService.swift
    │   │   └── RealGameService.swift
    │   ├── Screens/                 # UI screens
    │   │   ├── Home/
    │   │   │   ├── HomeView.swift
    │   │   │   └── GameRowView.swift
    │   │   └── Game/
    │   │       └── GameDetailView.swift
    │   └── Components/              # Reusable components
    └── Resources/
        └── Assets.xcassets/
```

## Getting Started

### Requirements

- Xcode 15.0+
- iOS 16.0+
- macOS Sonoma or later

### Build & Run

1. Open `ScrollDown.xcodeproj` in Xcode
2. Select your target device/simulator
3. Press ⌘R to build and run

The app will launch showing **"Scroll Down Sports"** with mock game data.

## Data Modes

The app supports two data modes controlled by `AppConfig`:

### Mock Mode (default)
- Loads data from bundled JSON files
- No network required
- Simulates realistic API delays
- Perfect for development and testing

### API Mode
- Connects to real Scroll Down API
- Requires backend to be running
- Currently returns `notImplemented` error (TODO)

## API Spec Alignment

All models are implemented to match the [OpenAPI specification](https://github.com/dock108/scroll-down-api-spec):

| Model | OpenAPI Schema |
|-------|---------------|
| `Game` | GameMeta |
| `GameSummary` | GameSummary |
| `GameListResponse` | GameListResponse |
| `GameDetailResponse` | GameDetailResponse |
| `TeamStat` | TeamStat |
| `PlayerStat` | PlayerStat |
| `OddsEntry` | OddsEntry |
| `SocialPostEntry` | SocialPostEntry |
| `PlayEntry` | PlayEntry |
| `PbpEvent` | PbpEvent |

## Mock Data

Mock JSON files are sourced from `scroll-down-api-spec/examples/`:

- `game-001.json` - Full game detail (Celtics vs Lakers)
- `game-002.json` - Full game detail (Bulls vs Heat)
- `game-list.json` - List of game summaries
- `pbp-001.json` - Play-by-play events
- `social-posts.json` - Social post list

## Development

### Adding New Screens

1. Create view in `Sources/Screens/`
2. Inject `AppConfig` via `@EnvironmentObject`
3. Use `appConfig.gameService` for data
4. Handle loading/error states

### Updating Models

1. Check OpenAPI spec for schema changes
2. Update corresponding Swift model
3. Verify mock JSON still decodes
4. Run tests

## Out of Scope (for now)

- ❌ Real API networking
- ❌ Caching/persistence
- ❌ UI polish/animations
- ❌ Highlight rendering
- ❌ Matching logic
- ❌ Authentication

## License

Proprietary - All rights reserved

