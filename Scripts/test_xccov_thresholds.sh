#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

CONFIG="$WORK_DIR/coverage-thresholds.json"
SCENARIO_FAIL_CONFIG="$WORK_DIR/scenario-fail-coverage-thresholds.json"
PASS_REPORT="$WORK_DIR/pass-report.json"
FAIL_REPORT="$WORK_DIR/fail-report.json"
REPO_ROOT="$WORK_DIR/repo"

mkdir -p "$REPO_ROOT/ScrollDownSportsTests"
touch "$REPO_ROOT/ScrollDownSportsTests/ScenarioCoverageTests.swift"

cat > "$CONFIG" <<'JSON'
{
  "version": 1,
  "targetName": "ScrollDownSports.app",
  "reportPath": "unused.json",
  "targetMinimumLineCoverage": 50.0,
  "defaultFileMinimumLineCoverage": 30.0,
  "tolerancePercentagePoints": 0.25,
  "minimumImprovementPercentagePoints": 0.5,
  "ratchetMilestones": [50.0, 70.0, 80.0],
  "excludedPathGlobs": [
    "ScrollDownSports/Resources/**",
    "ScrollDownSports/App/AppDelegate.swift"
  ],
  "includedPathOverrides": [
    "ScrollDownSports/App/AppEnvironment.swift"
  ],
  "fileMinimumLineCoverageOverrides": {
    "ScrollDownSports/App/BackgroundDataScheduler.swift": 40.0
  },
  "scenarioCoverageRequirements": [
    {
      "sourcePath": "ScrollDownSports/Views/GameDetailView.swift",
      "testPathGlobs": ["ScrollDownSportsTests/ScenarioCoverageTests.swift"],
      "minimumMatchedFiles": 1
    }
  ]
}
JSON

cp "$CONFIG" "$SCENARIO_FAIL_CONFIG"
perl -0pi -e 's#ScenarioCoverageTests#MissingScenarioTests#g' "$SCENARIO_FAIL_CONFIG"

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
  --repo-root "$REPO_ROOT" > "$WORK_DIR/pass.out"

if swift "$ROOT_DIR/Scripts/check_xccov_thresholds.swift" \
  --report "$FAIL_REPORT" \
  --config "$CONFIG" \
  --repo-root "$REPO_ROOT" > "$WORK_DIR/fail.out" 2>&1; then
  echo "Expected coverage failure did not occur"
  exit 1
fi

if swift "$ROOT_DIR/Scripts/check_xccov_thresholds.swift" \
  --report "$PASS_REPORT" \
  --config "$SCENARIO_FAIL_CONFIG" \
  --repo-root "$REPO_ROOT" > "$WORK_DIR/scenario-fail.out" 2>&1; then
  echo "Expected scenario coverage failure did not occur"
  exit 1
fi

grep -q "Coverage passed" "$WORK_DIR/pass.out"
grep -q "Scenario coverage requirements: 1" "$WORK_DIR/pass.out"
grep -q "Next milestone: 70.00%" "$WORK_DIR/pass.out"
grep -q "Coverage failed" "$WORK_DIR/fail.out"
grep -q "delta -" "$WORK_DIR/fail.out"
grep -q "Scenario coverage failed" "$WORK_DIR/scenario-fail.out"
