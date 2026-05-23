# Scroll Down Sports iOS

Scroll Down Sports iOS is a SwiftUI app for browsing Scroll Down Sports games, pinning games, and reading a game detail stream before reaching the score and box score near the bottom of the page. The app talks to the SDA admin sports API configured through Xcode build settings.

## Run Locally

Install Xcode and XcodeGen, then generate the project after changing `project.yml`:

```sh
xcodegen generate
```

Build the app for the simulator:

```sh
xcodebuild -project ScrollDownSports.xcodeproj -scheme ScrollDownSports -destination 'generic/platform=iOS Simulator' build
```

Run the unit tests:

```sh
xcodebuild -project ScrollDownSports.xcodeproj -scheme ScrollDownSports -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' -derivedDataPath .build/DerivedData test
```

For local API credentials, copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig` and set `SDA_API_KEY`. `Config/Local.xcconfig` is ignored by git and is included by `Config/Secrets.xcconfig` when present.

## Deployment Basics

The app target uses bundle identifier `com.dock108.scrolldownsports`, iOS deployment target `18.0`, and Release settings from `Config/Secrets.xcconfig`. `DEVELOPMENT_TEAM` is empty in `project.yml`, so signing must be supplied before archive or App Store distribution.

Both Debug and Release builds read `SDA_API_BASE_URL` and `SDA_API_KEY` into `Info.plist` as `SDABaseURL` and `SDAApiKey`; any Release credential value supplied through those build settings becomes part of the built app configuration.

There are no checked-in GitHub Actions workflows in this repo.

## Docs

- [App reference](docs/app-reference.md)
- [Documentation consolidation audit](docs/audits/docs-consolidation.md)
