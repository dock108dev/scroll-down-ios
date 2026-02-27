# CI/CD

GitHub Actions pipeline for iOS builds and testing.

## Pipeline Overview

```
PR / Push to main
    │
    ├─ iOS Job (macos-15, 30min timeout)
    │       ├─ Select Xcode 16+
    │       ├─ Ensure iOS Simulator runtime
    │       ├─ Build (xcodebuild build-for-testing)
    │       ├─ Test (xcodebuild test-without-building)
    │       └─ Coverage summary (xcrun xccov)
    │
    └─ CodeQL (weekly + on push to main)
            └─ Swift static analysis
```

## Trigger Rules

| Event | iOS Job |
|-------|---------|
| PR to main | Always runs |
| Push to main | Always runs |

Concurrency: Runs are grouped by workflow + branch. In-progress runs are cancelled when a new push arrives.

## iOS Job

Runs on `macos-15`. Selects the latest Xcode 16.x available on the runner. Dynamically picks an available iPhone simulator.

Generates a placeholder `Info.plist` for CI (API key set to `CI_PLACEHOLDER`, local networking allowed).

```bash
xcodebuild build-for-testing -scheme ScrollDown -destination '...'
xcodebuild test-without-building -scheme ScrollDown -destination '...' -enableCodeCoverage YES
```

## Additional Workflows

- **CodeQL** (`codeql.yml`) — Static analysis for Swift. Runs on push to main and weekly.

## Secrets

| Secret | Used By | Purpose |
|--------|---------|---------|
| `GITHUB_TOKEN` | CI | Auto-provided by GitHub |

## Environment Variables

Set via Xcode environment or `Info.plist`:

| Variable | Purpose |
|----------|---------|
| `SPORTS_DATA_API_KEY` | Backend API authentication |
| `IOS_BETA_ASSUME_NOW` | Snapshot mode time override (debug only) |
