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
assert_contains "$WORK_DIR/help.out" "ui-smoke"
assert_contains "$WORK_DIR/help.out" "visual"
assert_contains "$WORK_DIR/help.out" "accessibility"
assert_contains "$WORK_DIR/help.out" "performance-smoke"
assert_contains "$WORK_DIR/help.out" "full-local"
assert_contains "$WORK_DIR/help.out" "clean-artifacts"
assert_contains "$GATE" "resolve_requested_destination"
assert_contains "$GATE" "latest_destination_id_for_name"
assert_contains "$GATE" "Using an available iPhone simulator because requested destination"

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
assert_contains "$ROOT_DIR/docs/device-install.md" "The checked-in default backend is"
assert_contains "$ROOT_DIR/README.md" "Device install"

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
assert_contains "$WORK_DIR/visual.out" "-only-testing:ScrollDownSportsTests/HomeVisualRegressionTests"
assert_contains "$WORK_DIR/visual.out" "-only-testing:ScrollDownSportsTests/StatSectionSnapshotTests"

bash "$GATE" --dry-run accessibility > "$WORK_DIR/accessibility.out"
assert_contains "$WORK_DIR/accessibility.out" ".build/TestResults/Accessibility.xcresult"
assert_contains "$WORK_DIR/accessibility.out" "-only-testing:ScrollDownSportsUITests/ScrollDownSportsAccessibilityUITests"

bash "$GATE" --dry-run performance-smoke > "$WORK_DIR/performance.out"
assert_contains "$WORK_DIR/performance.out" ".build/TestResults/PerformanceSmoke.xcresult"
assert_contains "$WORK_DIR/performance.out" "-only-testing:ScrollDownSportsTests/PerformanceSmokeTests"
assert_contains "$WORK_DIR/performance.out" "-only-testing:ScrollDownSportsUITests/ScrollDownSportsPerformanceSmokeUITests"

bash "$GATE" --dry-run clean-artifacts > "$WORK_DIR/clean.out"
assert_contains "$WORK_DIR/clean.out" ".build/DerivedData"
assert_contains "$WORK_DIR/clean.out" ".build/TestResults"
assert_contains "$WORK_DIR/clean.out" ".build/coverage"
assert_not_contains "$WORK_DIR/clean.out" "ScrollDownSportsTests/__Snapshots__"
assert_not_contains "$WORK_DIR/clean.out" "ScrollDownSportsTests/Fixtures"

echo "Local gate command surface passed."
