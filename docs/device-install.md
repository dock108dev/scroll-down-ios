# Device Install

## Backend Targeting

Direct iPhone builds use the same backend settings as simulator builds:

- `SDA_API_BASE_URL` becomes `SDABaseURL` in `Info.plist`.
- `SDA_API_KEY` becomes `SDAApiKey` in `Info.plist`.
- The checked-in default backend is `https://sda.dock108.dev`.
- `Config/Local.xcconfig` can override either value and is ignored by git.

For a local backend on a physical phone, do not use `127.0.0.1` or `localhost`; those point at the phone. Use a reachable HTTPS URL such as a tunnel or LAN HTTPS endpoint, then set it in `Config/Local.xcconfig`.

## Signing Setup

1. Copy the local config example if needed:

   ```sh
   cp Config/Local.xcconfig.example Config/Local.xcconfig
   ```

2. Set private values in `Config/Local.xcconfig`:

   ```xcconfig
   SDA_API_BASE_URL = https:/$()/sda.dock108.dev
   SDA_API_KEY = <api-key-if-required>
   SDS_DEVELOPMENT_TEAM = <apple-team-id>
   ```

3. Regenerate the Xcode project:

   ```sh
   xcodegen generate --spec project.yml
   ```

4. Open `ScrollDownSports.xcodeproj`, select the `ScrollDownSports` scheme, select the connected iPhone, and build/run.

5. If the phone prompts for Developer Mode or trust, accept the prompt and rerun.

## CLI Smoke

Xcode is still the best path for the first install because it can resolve account and provisioning prompts. Once signing is configured, a CLI build should also work:

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
