# Scroll Down Sports iOS

Scroll Down Sports iOS is a SwiftUI app for browsing SDA game feeds. It supports league and team filtering, pinned games, catch-up progress, sport-rendered play-by-play, and score/box-score payoff sections on game detail screens.

The app is generated from `project.yml` with XcodeGen. Runtime SDA API settings come from Xcode build settings expanded into `Info.plist`.

## Run Locally

Install Xcode and XcodeGen, then run the fast local build gate:

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
Scripts/local_gate.sh multitasking
Scripts/local_gate.sh performance-smoke
```

For local API credentials or direct-device signing, copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig` and set the private values there. `Config/Local.xcconfig` is ignored by git and is included by `Config/Secrets.xcconfig` when present.

## Deployment Basics

`project.yml` defines the app bundle identifier as `com.dock108.scrolldownsports`, the iOS deployment target as `18.0`, Swift version `6.0`, marketing version `0.1.0`, and current project version `1`. Direct iPhone installs use automatic signing and read `SDS_DEVELOPMENT_TEAM` from `Config/Secrets.xcconfig`, with private overrides in ignored `Config/Local.xcconfig`.

Debug and Release both read `SDA_API_BASE_URL` and `SDA_API_KEY` from `Config/Secrets.xcconfig`, with optional local overrides from `Config/Local.xcconfig`. Those settings become `SDABaseURL` and `SDAApiKey` in `Info.plist`; any Release credential supplied there is part of the built app configuration. The checked-in backend default is production SDA at `https://sda.dock108.dev`.

The checked-in GitHub Actions workflow runs `Scripts/local_gate.sh` gates on pull requests, pushes to `main`, schedules, and manual dispatch.

## Docs

- [App reference](docs/app-reference.md)
- [Local development](docs/local-development.md)
- [Testing and CI](docs/testing-and-ci.md)
- [Maintenance notes](docs/maintenance.md)

Supporting documentation lives under `docs/`. Root-level documentation is intentionally limited to this README.
