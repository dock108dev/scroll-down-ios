#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

CONFIG="$WORK_DIR/coverage-thresholds.json"
PASS_REPORT="$WORK_DIR/pass-report.json"
FAIL_REPORT="$WORK_DIR/fail-report.json"

cat > "$CONFIG" <<'JSON'
{
  "version": 1,
  "targetName": "ScrollDownSports.app",
  "reportPath": "unused.json",
  "targetMinimumLineCoverage": 50.0,
  "defaultFileMinimumLineCoverage": 30.0,
  "tolerancePercentagePoints": 0.25,
  "minimumImprovementPercentagePoints": 0.5,
  "excludedPathGlobs": [
    "ScrollDownSports/Resources/**",
    "ScrollDownSports/App/AppDelegate.swift"
  ],
  "includedPathOverrides": [
    "ScrollDownSports/App/AppEnvironment.swift"
  ],
  "fileMinimumLineCoverageOverrides": {
    "ScrollDownSports/App/BackgroundDataScheduler.swift": 40.0
  }
}
JSON

cat > "$PASS_REPORT" <<'JSON'
{
  "targets": [
    {
      "name": "ScrollDownSports.app",
      "files": [
        {
          "name": "AppEnvironment.swift",
          "path": "/tmp/repo/ScrollDownSports/App/AppEnvironment.swift",
          "coveredLines": 8,
          "executableLines": 10,
          "lineCoverage": 0.8
        },
        {
          "name": "BackgroundDataScheduler.swift",
          "path": "/tmp/repo/ScrollDownSports/App/BackgroundDataScheduler.swift",
          "coveredLines": 4,
          "executableLines": 10,
          "lineCoverage": 0.4
        },
        {
          "name": "AppDelegate.swift",
          "path": "/tmp/repo/ScrollDownSports/App/AppDelegate.swift",
          "coveredLines": 0,
          "executableLines": 20,
          "lineCoverage": 0
        }
      ]
    }
  ]
}
JSON

cat > "$FAIL_REPORT" <<'JSON'
{
  "targets": [
    {
      "name": "ScrollDownSports.app",
      "files": [
        {
          "name": "AppEnvironment.swift",
          "path": "/tmp/repo/ScrollDownSports/App/AppEnvironment.swift",
          "coveredLines": 2,
          "executableLines": 10,
          "lineCoverage": 0.2
        },
        {
          "name": "BackgroundDataScheduler.swift",
          "path": "/tmp/repo/ScrollDownSports/App/BackgroundDataScheduler.swift",
          "coveredLines": 2,
          "executableLines": 10,
          "lineCoverage": 0.2
        }
      ]
    }
  ]
}
JSON

swift "$ROOT_DIR/Scripts/check_xccov_thresholds.swift" \
  --report "$PASS_REPORT" \
  --config "$CONFIG" \
  --repo-root "/tmp/repo" > "$WORK_DIR/pass.out"

if swift "$ROOT_DIR/Scripts/check_xccov_thresholds.swift" \
  --report "$FAIL_REPORT" \
  --config "$CONFIG" \
  --repo-root "/tmp/repo" > "$WORK_DIR/fail.out" 2>&1; then
  echo "Expected coverage failure did not occur"
  exit 1
fi

grep -q "Coverage passed" "$WORK_DIR/pass.out"
grep -q "Coverage failed" "$WORK_DIR/fail.out"
