# Scroll Down Sports iOS

Scroll Down Sports iOS is a SwiftUI app for browsing Scroll Down Sports game feeds, pinning games, resuming catch-up progress, and reading play-by-play before score and box-score payoff sections near the bottom of each game detail screen. It reads the SDA admin sports API base URL and optional API key from Xcode build settings that are expanded into the app `Info.plist`.

## Run Locally

Install Xcode and XcodeGen. The local gate wrapper regenerates `ScrollDownSports.xcodeproj` from `project.yml` before build and test gates.

Run the fast local build gate:

```sh
Scripts/local_gate.sh fast
```

Run the PR-quality local gate:

```sh
Scripts/local_gate.sh full-local
```

Run focused gates as needed:

```sh
Scripts/local_gate.sh unit
Scripts/local_gate.sh coverage
Scripts/local_gate.sh ui-smoke
Scripts/local_gate.sh visual
Scripts/local_gate.sh accessibility
Scripts/local_gate.sh performance-smoke
```

Clean generated local gate artifacts:

```sh
Scripts/local_gate.sh clean-artifacts
```

For local API credentials, copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig` and set `SDA_API_KEY`. `Config/Local.xcconfig` is ignored by git and is included by `Config/Secrets.xcconfig` when present.

## Deployment Basics

`project.yml` defines the app bundle identifier as `com.dock108.scrolldownsports`, the iOS deployment target as `18.0`, Swift version `6.0`, marketing version `0.1.0`, and current project version `1`. `DEVELOPMENT_TEAM` is empty, so signing must be supplied before archive or App Store distribution.

Debug and Release both read `SDA_API_BASE_URL` and `SDA_API_KEY` from `Config/Secrets.xcconfig`, with optional local overrides from `Config/Local.xcconfig`. Those settings become `SDABaseURL` and `SDAApiKey` in `Info.plist`; any Release credential supplied there is part of the built app configuration.

The checked-in GitHub Actions workflow runs `Scripts/local_gate.sh` gates on pull requests, pushes to `main`, schedules, and manual dispatch.

## Docs

- [App reference](docs/app-reference.md)
- [Testing and CI](docs/testing-and-ci.md)
- [Documentation consolidation audit](docs/audits/docs-consolidation.md)
