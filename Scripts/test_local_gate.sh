#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="$ROOT_DIR/Scripts/local_gate.sh"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

assert_contains() {
  local file="$1"
  local expected="$2"
  if ! grep -Fq -- "$expected" "$file"; then
    echo "Missing expected local gate output: $expected"
    echo "Output file: $file"
    exit 1
  fi
}

assert_not_contains() {
  local file="$1"
  local forbidden="$2"
  if [ ! -e "$file" ]; then
    return 0
  fi
  if grep -Fq -- "$forbidden" "$file"; then
    echo "Unexpected local gate output: $forbidden"
    echo "Output file: $file"
    exit 1
  fi
}

bash "$GATE" --help > "$WORK_DIR/help.out"
assert_contains "$WORK_DIR/help.out" "fast"
assert_contains "$WORK_DIR/help.out" "unit"
assert_contains "$WORK_DIR/help.out" "coverage"
assert_contains "$WORK_DIR/help.out" "detail-scroll"
assert_contains "$WORK_DIR/help.out" "ui-smoke"
assert_contains "$WORK_DIR/help.out" "visual"
assert_contains "$WORK_DIR/help.out" "accessibility"
assert_contains "$WORK_DIR/help.out" "multitasking"
assert_contains "$WORK_DIR/help.out" "ipad-ui-smoke"
assert_contains "$WORK_DIR/help.out" "ipad-visual"
assert_contains "$WORK_DIR/help.out" "ipad-accessibility"
assert_contains "$WORK_DIR/help.out" "ipad-multitasking"
assert_contains "$WORK_DIR/help.out" "performance-smoke"
assert_contains "$WORK_DIR/help.out" "full-local"
assert_contains "$WORK_DIR/help.out" "clean-artifacts"
assert_contains "$GATE" "resolve_requested_destination"
assert_contains "$GATE" "latest_destination_id_for_name"
assert_contains "$GATE" "fallback_destination_id_for_family"
assert_contains "$GATE" "create_destination_id_for"
assert_contains "$GATE" 'destination_id="$(fallback_destination_id_for_family "$requested_family")"'
assert_contains "$GATE" "No usable \$requested_family simulator destination was found."

FAKE_BIN="$WORK_DIR/fake-bin"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/xcodegen" <<'FAKE_XCODEGEN'
#!/usr/bin/env bash
set -euo pipefail
exit 0
FAKE_XCODEGEN
cat > "$FAKE_BIN/xcodebuild" <<'FAKE_XCODEBUILD'
#!/usr/bin/env bash
set -euo pipefail
if printf '%s\n' "$@" | grep -Fq -- "-showdestinations"; then
  cat "${FAKE_DESTINATIONS_FILE:?}"
  exit 0
fi
printf '%s\n' "$*" >> "${FAKE_XCODEBUILD_LOG:?}"
exit 0
FAKE_XCODEBUILD
cat > "$FAKE_BIN/xcrun" <<'FAKE_XCRUN'
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" != "simctl" ]; then
  exit 1
fi
shift
case "${1:-}" in
  list)
    case "${2:-}" in
      devices)
        if [ -n "${FAKE_SIMCTL_DEVICES_FILE:-}" ]; then
          cat "$FAKE_SIMCTL_DEVICES_FILE"
        fi
        ;;
      runtimes)
        if [ -n "${FAKE_SIMCTL_RUNTIMES_FILE:-}" ]; then
          cat "$FAKE_SIMCTL_RUNTIMES_FILE"
        fi
        ;;
      devicetypes)
        if [ -n "${FAKE_SIMCTL_DEVICETYPES_FILE:-}" ]; then
          cat "$FAKE_SIMCTL_DEVICETYPES_FILE"
        fi
        ;;
    esac
    ;;
  create)
    printf '%s %s %s\n' "$2" "$3" "$4" >> "${FAKE_SIMCTL_CREATE_LOG:?}"
    printf '%s\n' "${FAKE_SIMCTL_CREATE_ID:-CREATED-SIM-ID}"
    ;;
esac
FAKE_XCRUN
chmod +x "$FAKE_BIN/xcodegen" "$FAKE_BIN/xcodebuild" "$FAKE_BIN/xcrun"

cat > "$WORK_DIR/mixed-destinations.txt" <<'EOF_DESTINATIONS'
Available destinations for the "ScrollDownSports" scheme:
  { platform:iOS Simulator, id:IPHONE-FALLBACK-ID, OS:26.2, name:iPhone 17 Pro }
  { platform:iOS Simulator, id:IPAD-FALLBACK-ID, OS:26.1, name:iPad Air 13-inch (M3) }
EOF_DESTINATIONS

FAKE_XCODEBUILD_LOG="$WORK_DIR/ipad-fallback-xcodebuild.log" \
FAKE_DESTINATIONS_FILE="$WORK_DIR/mixed-destinations.txt" \
PATH="$FAKE_BIN:$PATH" \
TEST_DESTINATION="platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=26.2" \
  bash "$GATE" unit > "$WORK_DIR/ipad-fallback.out" 2> "$WORK_DIR/ipad-fallback.err"
assert_contains "$WORK_DIR/ipad-fallback-xcodebuild.log" "-destination platform=iOS Simulator,id=IPAD-FALLBACK-ID"
assert_contains "$WORK_DIR/ipad-fallback.err" "Using an available ipad simulator because requested destination"
assert_not_contains "$WORK_DIR/ipad-fallback-xcodebuild.log" "IPHONE-FALLBACK-ID"

cat > "$WORK_DIR/phone-only-destinations.txt" <<'EOF_DESTINATIONS'
Available destinations for the "ScrollDownSports" scheme:
  { platform:iOS Simulator, id:IPHONE-FALLBACK-ID, OS:26.2, name:iPhone 17 Pro }
EOF_DESTINATIONS

cat > "$WORK_DIR/no-simctl-devices.txt" <<'EOF_DEVICES'
== Devices ==
EOF_DEVICES

cat > "$WORK_DIR/no-simctl-runtimes.txt" <<'EOF_RUNTIMES'
== Runtimes ==
EOF_RUNTIMES

cat > "$WORK_DIR/no-simctl-devicetypes.txt" <<'EOF_DEVICETYPES'
== Device Types ==
EOF_DEVICETYPES

set +e
FAKE_XCODEBUILD_LOG="$WORK_DIR/ipad-missing-xcodebuild.log" \
FAKE_DESTINATIONS_FILE="$WORK_DIR/phone-only-destinations.txt" \
FAKE_SIMCTL_DEVICES_FILE="$WORK_DIR/no-simctl-devices.txt" \
FAKE_SIMCTL_RUNTIMES_FILE="$WORK_DIR/no-simctl-runtimes.txt" \
FAKE_SIMCTL_DEVICETYPES_FILE="$WORK_DIR/no-simctl-devicetypes.txt" \
FAKE_SIMCTL_CREATE_LOG="$WORK_DIR/ipad-missing-simctl-create.log" \
PATH="$FAKE_BIN:$PATH" \
TEST_DESTINATION="platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=26.2" \
  bash "$GATE" unit > "$WORK_DIR/ipad-missing.out" 2> "$WORK_DIR/ipad-missing.err"
missing_status=$?
set -e
if [ "$missing_status" -eq 0 ]; then
  echo "Expected iPad destination resolution to fail when only iPhone simulators are available"
  exit 1
fi
assert_contains "$WORK_DIR/ipad-missing.err" "No usable ipad simulator destination was found."
assert_not_contains "$WORK_DIR/ipad-missing-xcodebuild.log" "IPHONE-FALLBACK-ID"

cat > "$WORK_DIR/placeholders-only-destinations.txt" <<'EOF_DESTINATIONS'
Available destinations for the "ScrollDownSports" scheme:
  { platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Any iOS Device }
  { platform:iOS Simulator, id:dvtdevice-DVTiOSDeviceSimulatorPlaceholder-iphonesimulator:placeholder, name:Any iOS Simulator Device }
EOF_DESTINATIONS

cat > "$WORK_DIR/simctl-runtimes.txt" <<'EOF_RUNTIMES'
== Runtimes ==
iOS 26.2 (26.2 - 23C54) - com.apple.CoreSimulator.SimRuntime.iOS-26-2
EOF_RUNTIMES

cat > "$WORK_DIR/simctl-devicetypes.txt" <<'EOF_DEVICETYPES'
== Device Types ==
iPhone 17 Pro Max (com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max)
EOF_DEVICETYPES

FAKE_XCODEBUILD_LOG="$WORK_DIR/created-phone-xcodebuild.log" \
FAKE_DESTINATIONS_FILE="$WORK_DIR/placeholders-only-destinations.txt" \
FAKE_SIMCTL_DEVICES_FILE="$WORK_DIR/no-simctl-devices.txt" \
FAKE_SIMCTL_RUNTIMES_FILE="$WORK_DIR/simctl-runtimes.txt" \
FAKE_SIMCTL_DEVICETYPES_FILE="$WORK_DIR/simctl-devicetypes.txt" \
FAKE_SIMCTL_CREATE_LOG="$WORK_DIR/created-phone-simctl-create.log" \
FAKE_SIMCTL_CREATE_ID="CREATED-PHONE-ID" \
PATH="$FAKE_BIN:$PATH" \
TEST_DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.2" \
  bash "$GATE" unit > "$WORK_DIR/created-phone.out" 2> "$WORK_DIR/created-phone.err"
assert_contains "$WORK_DIR/created-phone-xcodebuild.log" "-destination platform=iOS Simulator,id=CREATED-PHONE-ID"
assert_contains "$WORK_DIR/created-phone-simctl-create.log" "ScrollDownSports iPhone 17 Pro Max iOS 26.2"
assert_contains "$WORK_DIR/created-phone.err" "Created iphone simulator destination"

bash "$GATE" --dry-run build > "$WORK_DIR/build.out"
assert_contains "$WORK_DIR/build.out" "xcodegen generate --spec"
assert_contains "$WORK_DIR/build.out" "-destination 'generic/platform=iOS Simulator'"
assert_contains "$WORK_DIR/build.out" "CODE_SIGNING_ALLOWED=NO"
assert_contains "$WORK_DIR/build.out" "SDA_API_KEY="
assert_contains "$WORK_DIR/build.out" "SDA_API_BASE_URL=http://127.0.0.1.invalid"
assert_contains "$ROOT_DIR/Config/Secrets.xcconfig" 'SDA_API_BASE_URL = https:/$()/sda.dock108.dev'
assert_contains "$ROOT_DIR/Config/Secrets.xcconfig" "SDS_DEVELOPMENT_TEAM ="
assert_contains "$ROOT_DIR/project.yml" "CODE_SIGN_STYLE: Automatic"
assert_contains "$ROOT_DIR/project.yml" 'DEVELOPMENT_TEAM: "$(SDS_DEVELOPMENT_TEAM)"'
assert_contains "$ROOT_DIR/docs/local-development.md" "The checked-in default backend is"
assert_contains "$ROOT_DIR/README.md" "Local development"

bash "$GATE" --dry-run coverage > "$WORK_DIR/coverage.out"
assert_contains "$WORK_DIR/coverage.out" ".build/TestResults/Coverage.xcresult"
assert_contains "$WORK_DIR/coverage.out" "-enableCodeCoverage YES"
assert_contains "$WORK_DIR/coverage.out" "-only-testing:ScrollDownSportsTests"
assert_contains "$WORK_DIR/coverage.out" ".build/coverage/xccov-report.json"
assert_contains "$WORK_DIR/coverage.out" "Scripts/check_xccov_thresholds.swift"

bash "$GATE" --dry-run ui-smoke > "$WORK_DIR/ui-smoke.out"
assert_contains "$WORK_DIR/ui-smoke.out" ".build/TestResults/UISmoke.xcresult"
assert_contains "$WORK_DIR/ui-smoke.out" "-only-testing:ScrollDownSportsUITests/ScrollDownSportsCriticalFlowsUITests"

bash "$GATE" --dry-run visual > "$WORK_DIR/visual.out"
assert_contains "$WORK_DIR/visual.out" ".build/TestResults/Visual.xcresult"
assert_contains "$WORK_DIR/visual.out" "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2"
assert_contains "$WORK_DIR/visual.out" "-only-testing:ScrollDownSportsTests/HomeVisualRegressionTests"
assert_contains "$WORK_DIR/visual.out" "-only-testing:ScrollDownSportsTests/StatSectionSnapshotTests"

TEST_DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=latest" bash "$GATE" --dry-run visual > "$WORK_DIR/visual-phone-override.out"
assert_contains "$WORK_DIR/visual-phone-override.out" "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2"
assert_not_contains "$WORK_DIR/visual-phone-override.out" "iPhone 16,OS=latest"

TEST_DESTINATION="platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=26.2" bash "$GATE" --dry-run visual > "$WORK_DIR/visual-ipad-override.out"
assert_contains "$WORK_DIR/visual-ipad-override.out" "platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=26.2"

set +e
TEST_DESTINATION="platform=iOS Simulator,name=iPad Air 13-inch (M3),OS=26.2" bash "$GATE" --dry-run visual > "$WORK_DIR/visual-ipad-wrong-device.out" 2> "$WORK_DIR/visual-ipad-wrong-device.err"
wrong_visual_status=$?
set -e
if [ "$wrong_visual_status" -eq 0 ]; then
  echo "Expected noncanonical iPad visual destination to fail"
  exit 1
fi
assert_contains "$WORK_DIR/visual-ipad-wrong-device.err" "iPad visual runs require the pinned destination"

bash "$GATE" --dry-run accessibility > "$WORK_DIR/accessibility.out"
assert_contains "$WORK_DIR/accessibility.out" ".build/TestResults/Accessibility.xcresult"
assert_contains "$WORK_DIR/accessibility.out" "-only-testing:ScrollDownSportsUITests/ScrollDownSportsAccessibilityUITests"

bash "$GATE" --dry-run multitasking > "$WORK_DIR/multitasking.out"
assert_contains "$WORK_DIR/multitasking.out" "Scripts/check_multitasking_project_invariants.rb"

bash "$GATE" --dry-run ipad-ui-smoke > "$WORK_DIR/ipad-ui-smoke.out"
assert_contains "$WORK_DIR/ipad-ui-smoke.out" ".build/TestResults/IPadUISmoke.xcresult"
assert_contains "$WORK_DIR/ipad-ui-smoke.out" "platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=26.2"
assert_contains "$WORK_DIR/ipad-ui-smoke.out" "-only-testing:ScrollDownSportsUITests/ScrollDownSportsCriticalFlowsUITests"

set +e
TEST_DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=latest" bash "$GATE" --dry-run ipad-ui-smoke > "$WORK_DIR/ipad-ui-smoke-phone.out" 2> "$WORK_DIR/ipad-ui-smoke-phone.err"
wrong_ipad_smoke_status=$?
set -e
if [ "$wrong_ipad_smoke_status" -eq 0 ]; then
  echo "Expected iPad UI smoke gate to reject an iPhone destination"
  exit 1
fi
assert_contains "$WORK_DIR/ipad-ui-smoke-phone.err" "iPad gate requires an iPad simulator destination."

bash "$GATE" --dry-run ipad-visual > "$WORK_DIR/ipad-visual.out"
assert_contains "$WORK_DIR/ipad-visual.out" ".build/TestResults/IPadVisual.xcresult"
assert_contains "$WORK_DIR/ipad-visual.out" "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2"
assert_contains "$WORK_DIR/ipad-visual.out" "-only-testing:ScrollDownSportsTests/HomeVisualRegressionTests"

bash "$GATE" --dry-run ipad-accessibility > "$WORK_DIR/ipad-accessibility.out"
assert_contains "$WORK_DIR/ipad-accessibility.out" ".build/TestResults/IPadAccessibility.xcresult"
assert_contains "$WORK_DIR/ipad-accessibility.out" "platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=26.2"
assert_contains "$WORK_DIR/ipad-accessibility.out" "-only-testing:ScrollDownSportsUITests/ScrollDownSportsAccessibilityUITests"

bash "$GATE" --dry-run ipad-multitasking > "$WORK_DIR/ipad-multitasking.out"
assert_contains "$WORK_DIR/ipad-multitasking.out" "Scripts/check_multitasking_project_invariants.rb"

bash "$GATE" --dry-run performance-smoke > "$WORK_DIR/performance.out"
assert_contains "$WORK_DIR/performance.out" ".build/TestResults/PerformanceSmoke.xcresult"
assert_contains "$WORK_DIR/performance.out" "-only-testing:ScrollDownSportsTests/PerformanceSmokeTests"
assert_contains "$WORK_DIR/performance.out" "-only-testing:ScrollDownSportsUITests/ScrollDownSportsPerformanceSmokeUITests"

bash "$GATE" --dry-run detail-scroll > "$WORK_DIR/detail-scroll.out"
assert_contains "$WORK_DIR/detail-scroll.out" ".build/TestResults/DetailScroll.xcresult"
assert_contains "$WORK_DIR/detail-scroll.out" "-only-testing:ScrollDownSportsTests/DetailLongFeedScrollTests"

bash "$GATE" --dry-run script-checks > "$WORK_DIR/script-checks.out"
assert_contains "$WORK_DIR/script-checks.out" "Scripts/check_no_admin_api_paths.sh"
assert_contains "$WORK_DIR/script-checks.out" "Scripts/check_multitasking_project_invariants.rb"

bash "$GATE" --dry-run clean-artifacts > "$WORK_DIR/clean.out"
assert_contains "$WORK_DIR/clean.out" ".build/DerivedData"
assert_contains "$WORK_DIR/clean.out" ".build/TestResults"
assert_contains "$WORK_DIR/clean.out" ".build/coverage"
assert_not_contains "$WORK_DIR/clean.out" "ScrollDownSportsTests/__Snapshots__"
assert_not_contains "$WORK_DIR/clean.out" "ScrollDownSportsTests/Fixtures"

echo "Local gate command surface passed."
