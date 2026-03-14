# Development

Guide for local development, testing, and debugging.

---

## Environments

The iOS app supports three runtime environments via `AppConfig.shared.environment`:

| Mode | Description | Use Case |
|------|-------------|----------|
| `.live` | Production backend API | Default, real data |
| `.localhost` | Local dev server (port 8000) | Backend development |
| `.mock` | Generated local data via `MockGameService` | Offline development |

**Default:** Live mode. Mock mode does not provide flow data, team colors, or unified timelines.

### Switching Modes

```swift
// In code
AppConfig.shared.environment = .localhost
```

**Note:** The Admin Settings UI (`AdminSettingsView`) exists but the long-press trigger on the freshness text is not currently rendered in the home layout. Access admin settings by setting `showingAdminSettings = true` in code.

## Mock Data

Static mock JSON lives in `ScrollDown/Sources/Mock/games/`:

| File | Content |
|------|---------|
| `game-list.json` | Sample game feed |
| `game-001.json` | Full game detail |
| `game-002.json` | Full game detail (variant) |
| `pbp-001.json` | Play-by-play events |
| `social-posts.json` | Social post samples |

`MockDataGenerator` dynamically creates games with realistic data. The mock service uses a fixed dev clock (November 12, 2024) so temporal grouping behaves consistently.

**Note:** Mock service does not generate flow data, team colors, or unified timelines. These come from the real API only.

## Building & Testing

```bash
# Build for simulator
xcodebuild -project ScrollDown.xcodeproj -scheme ScrollDown -destination 'generic/platform=iOS Simulator' -configuration Debug build

# Run tests
xcodebuild test -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Clean build
xcodebuild -scheme ScrollDown clean build
```

## Adding New Files

This project uses an Xcode project file (not SPM). Every new `.swift` file must be added to `ScrollDown.xcodeproj/project.pbxproj`. Use the `xcodeproj` Ruby gem:

```bash
# Install if needed
gem install xcodeproj

# Add files via Ruby script — see existing examples in commit history
```

Each file needs a `PBXFileReference` entry and a `PBXBuildFile` entry in the target's source build phase. The project uses individual file references, not folder references.

## Snapshot Mode (Time Override)

Freeze the app to a specific date to test historical data. **Debug builds only.**

```bash
export IOS_BETA_ASSUME_NOW=2024-10-23T04:00:00Z
```

See [beta-time-override.md](beta-time-override.md) for full documentation.

## Project Structure

```
ScrollDown/Sources/
├── Auth/                    # Login, signup, account management
│   ├── Models/              # AuthModels (UserRole, requests/responses)
│   ├── Services/            # AuthService (JWT, Keychain)
│   ├── ViewModels/          # AuthViewModel (session state)
│   └── Views/               # LoginView, SignupView, AccountView
├── Components/              # Shared UI (PulsingDotView, MiniScorebar, skeletons)
├── Extensions/              # Date formatting, string helpers
├── FairBet/                 # Odds comparison module
│   ├── Models/              # APIBet, BookPrice, FairBetLeague, LiveBetModels, ParlayCorrelation
│   ├── Services/            # FairBetAPIClient
│   ├── Theme/               # FairBetTheme (namespaced colors)
│   ├── ViewModels/          # OddsComparisonViewModel, LiveOddsViewModel
│   └── Views/               # BetCard, ParlaySheet, LiveOddsView, LiveGameHeader
├── Models/                  # Game, GameSummary, GameDetailResponse, MLB/NHL stat models
├── Networking/              # APIConfiguration, GameService, RealGameService, RealtimeService
├── Screens/
│   ├── Game/                # GameDetailView + extensions (Layout, Stats, Timeline, MLB, etc.)
│   ├── History/             # HistoryView, DateNavigatorView
│   ├── Home/                # HomeView, GameRowView, SettingsView, FairBetHeader
│   ├── ParlayCalc/          # ParlayCalculatorView (standalone)
│   └── Team/                # TeamView
├── Services/                # HapticService, ReadingPositionStore, TimeService
├── Simulator/               # MLB Monte Carlo simulator
│   ├── Models/              # SimulatorAPIModels (teams, roster, results)
│   ├── Services/            # SimulatorAPIClient
│   ├── Theme/               # SimulatorTheme (colors, gradients)
│   ├── ViewModels/          # MLBSimulatorViewModel
│   └── Views/               # SimulatorView, TeamPicker, Lineup, Results, Playback
├── Theme/                   # Typography
└── ViewModels/              # HistoryViewModel
```

## QA Checklist

### Core UI
- [ ] System, light, and dark themes
- [ ] Long team names and 4-char abbreviations display correctly
- [ ] iPad adaptive layout (constrained content width)
- [ ] All four tabs work (Games / FairBet / Simulator / Settings)

### Games Tab
- [ ] Empty states show contextual messages
- [ ] Loading skeletons with shimmer animation appear
- [ ] Search filters games by team name
- [ ] Section collapse states persist within session
- [ ] Score reveal respects user preference
- [ ] Hold-to-reveal shows score on demand
- [ ] Catch-up button bulk-reveals all scores
- [ ] Reset button undoes catch-up

### FairBet Tab
- [ ] Pre-game/Live/Calc sub-tabs switch correctly
- [ ] FairBet first page loads immediately, remaining pages load progressively
- [ ] League filter pills only show leagues with data
- [ ] BetCard shows accent stripe on high-EV bets
- [ ] Parlay builder: add/remove legs, correlation warnings display
- [ ] Parlay sheet: book odds input computes EV
- [ ] Live odds: games grouped with pulsing live indicator, 30s polling
- [ ] Standalone calculator: add legs, fair odds compute, EV displays

### Simulator Tab
- [ ] Teams load and are selectable
- [ ] Roster loads for selected teams
- [ ] Custom lineup builder expands/collapses
- [ ] Simulation runs and results display (probability bars, scores, charts)
- [ ] Game playback: diamond renders, play/pause/step works
- [ ] Haptic feedback on simulation complete

### Account & Auth
- [ ] Login/signup flows work
- [ ] Account view shows profile and role
- [ ] Logout clears session
- [ ] Admin users see History in Settings
- [ ] Guest users see sign-in prompt

### Live Games
- [ ] Live game detail shows PBP as primary content
- [ ] Auto-polling starts (~45s interval)
- [ ] Polling stops on dismiss or game transitioning to final
- [ ] Header shows pulsing LIVE badge

## Debugging

### Console logs
Filter by subsystem `com.scrolldown.app` in Console.app:

| Category | Content |
|----------|---------|
| `time` | Snapshot mode events |
| `routing` | Navigation and game routing |
| `networking` | API calls and responses |
| `teamColors` | Team color cache loading |
| `timeline` | Timeline and flow loading |

### Common Issues

**Flow not loading:**
- Check `viewModel.hasFlowData` returns true
- Verify API responses in network logs
- Confirm game has flow data generated (not all games have flow)

**Team colors showing default indigo:**
- Check `TeamColorCache` loaded successfully
- Verify `/api/admin/sports/teams` returns color hex values
- Cache expires after 7 days — force refresh by clearing UserDefaults

**Build fails after adding new files:**
- Ensure files are added to `ScrollDown.xcodeproj` via `xcodeproj` gem
- Check both `PBXFileReference` and `PBXBuildFile` entries exist
