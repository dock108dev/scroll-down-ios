# Scroll Down Sports iOS

Native SwiftUI catch-up app for Scroll Down Sports.

The app reads the same SDA game data shape used by the tagged `scroll-down-web` release, but strips the product down to:

- A home list of games from 72 hours before now through 48 hours after now.
- League and team search filters.
- A game catch-up page ordered as play-by-play, player stats, team stats, then the only visible score/box-score section at the bottom.
- Foreground refresh every 5 minutes, plus an iOS background app-refresh task request for live-ish updates when the system allows it.

## Backend

Default base URL:

```text
https://sda.dock108.dev
```

The client calls:

```text
GET /api/admin/sports/games?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD&limit=200
GET /api/admin/sports/games/{id}
```

The upstream currently returns `401 Missing API key` without credentials. The app reads `SDABaseURL` and `SDAApiKey` from `Info.plist`, backed by these Xcode build settings:

```text
SDA_API_BASE_URL=https://sda.dock108.dev
SDA_API_KEY=
```

For local simulator builds, pass a key as a build setting or add a user-local `.xcconfig` outside source control. For App Store builds, use a mobile-safe backend/proxy path; do not ship a private SDA key in the binary.

## Generate and Build

```sh
xcodegen generate
xcodebuild -project ScrollDownSports.xcodeproj -scheme ScrollDownSports -destination 'generic/platform=iOS Simulator' build
```

With a local development key:

```sh
xcodebuild -project ScrollDownSports.xcodeproj -scheme ScrollDownSports -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' SDA_API_KEY="$SPORTS_DATA_API_KEY" build
```
