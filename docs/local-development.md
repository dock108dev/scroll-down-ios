# Local Development

## Project Generation

`project.yml` is the source for `ScrollDownSports.xcodeproj`. Run XcodeGen after editing target settings, source groups, package dependencies, schemes, or signing configuration:

```sh
xcodegen generate --spec project.yml
```

`Scripts/local_gate.sh` regenerates the project automatically before build and test gates, so routine local validation should use the gate script instead of invoking XcodeGen by hand.

## Backend Configuration

Debug and Release builds read SDA backend settings from Xcode build settings:

- `SDA_API_BASE_URL` becomes `SDABaseURL` in `Info.plist`.
- `SDA_API_KEY` becomes `SDAApiKey` in `Info.plist`.

The checked-in default backend is `https://sda.dock108.dev` in `Config/Secrets.xcconfig`, with an empty API key and empty development team. `Config/Secrets.xcconfig` optionally includes ignored `Config/Local.xcconfig`, so local credentials and signing values belong there.

Create local overrides when needed:

```sh
cp Config/Local.xcconfig.example Config/Local.xcconfig
```

Example shape:

```xcconfig
SDA_API_BASE_URL = https:/$()/sda.dock108.dev
SDA_API_KEY = <api-key-if-required>
SDS_DEVELOPMENT_TEAM = <apple-team-id>
```

`Scripts/local_gate.sh` intentionally overrides simulator gate builds to use `SDA_API_BASE_URL=http://127.0.0.1.invalid` and an empty API key. That keeps automated simulator gates deterministic and does not change the checked-in Debug or Release defaults used by normal Xcode builds.

For a local backend on a physical phone, do not use `127.0.0.1` or `localhost`; those point at the phone. Use a reachable HTTPS URL such as a tunnel or LAN HTTPS endpoint, then set it in `Config/Local.xcconfig`.

If `SDABaseURL` is absent or invalid at runtime, `SDAApiClient` falls back to `https://sda.dock108.dev`. If `SDAApiKey` is empty or still an unresolved build-setting placeholder, requests are sent without `X-API-Key`.

## Local Gates

The fast build gate is:

```sh
Scripts/local_gate.sh fast
```

The PR-quality local gate is:

```sh
Scripts/local_gate.sh full-local
```

Clean generated local gate artifacts with:

```sh
Scripts/local_gate.sh clean-artifacts
```

Generated artifacts live under `.build` and are ignored by git.

## Direct Device Install

Direct iPhone builds use automatic signing. Set `SDS_DEVELOPMENT_TEAM` in ignored `Config/Local.xcconfig`, regenerate the project, open `ScrollDownSports.xcodeproj`, select the `ScrollDownSports` scheme, select the connected iPhone, and build/run.

If the phone prompts for Developer Mode or trust, accept the prompt and rerun.

Xcode is the best path for the first install because it can resolve account and provisioning prompts. Once signing is configured, a CLI build should also work:

```sh
xcodebuild \
  -project ScrollDownSports.xcodeproj \
  -scheme ScrollDownSports \
  -configuration Debug \
  -destination 'platform=iOS,id=<device-udid>' \
  -derivedDataPath .build/DeviceDerivedData \
  build
```

After install, smoke test that the home feed loads, league filtering works, a game detail opens, and refresh returns data from the selected SDA backend.

## UI Test Fixtures

Debug UI-test runs can use fixture-backed API responses by setting `SDS_UI_TEST_FIXTURE`. The checked-in fixture modes are `critical-final-game` and `performance-long-stream`. UI-test-only launch settings also include `SDS_RESET_STATE`, `SDS_HOME_INITIAL_ANCHOR`, and `SDS_UI_TEST_DYNAMIC_TYPE`.

These environment variables are for debug UI tests only. They are not production configuration.
