#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW="$ROOT_DIR/.github/workflows/ci.yml"

assert_contains() {
  local expected="$1"
  if ! grep -Fq -- "$expected" "$WORKFLOW"; then
    echo "Missing workflow entry: $expected"
    exit 1
  fi
}

assert_not_contains() {
  local forbidden="$1"
  if grep -Fiq -- "$forbidden" "$WORKFLOW"; then
    echo "Forbidden workflow entry: $forbidden"
    exit 1
  fi
}

assert_contains "pull_request:"
assert_contains "schedule:"
assert_contains "workflow_dispatch:"
assert_contains "runs-on: macos-26"
assert_contains "DEVELOPER_DIR: /Applications/Xcode_26.2.app/Contents/Developer"
assert_contains "bash Scripts/local_gate.sh build"
assert_contains "bash Scripts/local_gate.sh coverage"
assert_contains "bash Scripts/local_gate.sh script-checks"
assert_contains "bash Scripts/local_gate.sh ui-smoke"
assert_contains "bash Scripts/local_gate.sh visual"
assert_contains "bash Scripts/local_gate.sh accessibility"
assert_contains "bash Scripts/local_gate.sh performance-smoke"
assert_contains 'TEST_DESTINATION: ${{ matrix.device.destination }}'
assert_contains "ScrollDownSports-pr-xcresults"
assert_contains "ScrollDownSports-pr-coverage"
assert_contains "ScrollDownSports-pr-snapshot-artifacts"
assert_contains "ScrollDownSports-pr-simulator-diagnostics"
assert_contains "ScrollDownSports-visual-"
assert_contains "ScrollDownSports-ui-accessibility-"
assert_contains "ScrollDownSports-performance"

assert_not_contains "npm "
assert_not_contains "pnpm "
assert_not_contains "yarn "
assert_not_contains "node "
assert_not_contains "playwright"
assert_not_contains "cocoapods"
assert_not_contains "fastlane"
assert_not_contains "runs-on: macos-15"

echo "CI workflow shape passed."
