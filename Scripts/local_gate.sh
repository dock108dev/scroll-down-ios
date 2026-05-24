#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/ScrollDownSports.xcodeproj"
PROJECT_YML="$ROOT_DIR/project.yml"
SCHEME="ScrollDownSports"
DERIVED_DATA="$ROOT_DIR/.build/DerivedData"
RESULTS_DIR="$ROOT_DIR/.build/TestResults"
COVERAGE_DIR="$ROOT_DIR/.build/coverage"
ARTIFACTS_DIR="$ROOT_DIR/.build/artifacts"
CANONICAL_DESTINATION_NAME="iPhone 17 Pro"
CANONICAL_DESTINATION_OS="26.2"
LOCAL_API_BASE_URL="http://127.0.0.1.invalid"
DRY_RUN=0
CURRENT_GATE=""

usage() {
  cat <<'EOF'
Usage: Scripts/local_gate.sh [--dry-run] <gate>

Gates:
  fast                 Generate the project and build the simulator app.
  build                Same as fast.
  unit                 Run ScrollDownSportsTests without coverage enforcement.
  coverage             Run unit tests with coverage and enforce thresholds.
  ui-smoke             Run deterministic critical XCUITest flows.
  visual               Run committed visual snapshot regression tests.
  accessibility        Run accessibility XCUITest audits.
  performance-smoke    Run XCTest and XCUITest performance smoke gates.
  full-local           Run the PR-quality local gate: build, coverage, script checks, and UI smoke.
  script-checks        Run repository script/CI shape checks.
  clean-artifacts      Remove generated local gate artifacts under .build.

Environment:
  TEST_DESTINATION     Override the simulator destination for test gates.
  SNAPSHOT_RECORD      Set to 1 only when intentionally recording visual baselines.
EOF
}

print_command() {
  printf '+'
  for arg in "$@"; do
    case "$arg" in
      *[!A-Za-z0-9_./:=+-]*)
        printf " '%s'" "${arg//\'/\'\\\'\'}"
        ;;
      *)
        printf " %s" "$arg"
        ;;
    esac
  done
  printf '\n'
}

print_redirect_command() {
  local output="$1"
  shift
  printf '+'
  for arg in "$@"; do
    case "$arg" in
      *[!A-Za-z0-9_./:=+-]*)
        printf " '%s'" "${arg//\'/\'\\\'\'}"
        ;;
      *)
        printf " %s" "$arg"
        ;;
    esac
  done
  printf ' > %s\n' "$output"
}

run_cmd() {
  if [ "$DRY_RUN" -eq 1 ]; then
    print_command "$@"
    return 0
  fi

  "$@"
}

record_failure() {
  local status=$?
  if [ "$status" -ne 0 ] && [ -n "$CURRENT_GATE" ]; then
    mkdir -p "$RESULTS_DIR"
    local rerun_command="Scripts/local_gate.sh $CURRENT_GATE"
    printf '%s\n' "$rerun_command" > "$RESULTS_DIR/$CURRENT_GATE.rerun"
    echo
    echo "Gate '$CURRENT_GATE' failed."
    echo "Focused rerun: $rerun_command"
    echo "Rerun command recorded at: .build/TestResults/$CURRENT_GATE.rerun"
  fi
  exit "$status"
}
trap record_failure EXIT

start_gate() {
  CURRENT_GATE="$1"
  mkdir -p "$RESULTS_DIR"
  printf '%s\n' "Scripts/local_gate.sh $CURRENT_GATE" > "$RESULTS_DIR/$CURRENT_GATE.rerun"
}

require_xcodegen() {
  if ! command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen is required. Install it with: brew install xcodegen"
    exit 1
  fi
}

generate_project() {
  require_xcodegen
  run_cmd xcodegen generate --spec "$PROJECT_YML"
}

destination_id_for() {
  local wanted_name="$1"
  local wanted_os="$2"
  xcodebuild -showdestinations -project "$PROJECT" -scheme "$SCHEME" 2>/dev/null | awk -F '[{},]' \
    -v wanted_name="$wanted_name" \
    -v wanted_os="$wanted_os" '
      /platform:iOS Simulator/ {
        id = ""; name = ""; os = ""; platform = "";
        for (idx = 1; idx <= NF; idx++) {
          field = $idx;
          gsub(/^ +| +$/, "", field);
          if (field ~ /^id:/) { sub(/^id:/, "", field); id = field; }
          if (field ~ /^name:/) { sub(/^name:/, "", field); name = field; }
          if (field ~ /^OS:/) { sub(/^OS:/, "", field); os = field; }
          if (field ~ /^platform:/) { sub(/^platform:/, "", field); platform = field; }
        }
        if (platform == "iOS Simulator" && name == wanted_name && os == wanted_os && id != "") {
          print id;
          exit;
        }
      }
    '
}

latest_destination_id_for_name() {
  local wanted_name="$1"
  xcodebuild -showdestinations -project "$PROJECT" -scheme "$SCHEME" 2>/dev/null | awk -F '[{},]' \
    -v wanted_name="$wanted_name" '
      /platform:iOS Simulator/ {
        id = ""; name = ""; os = ""; platform = "";
        for (idx = 1; idx <= NF; idx++) {
          field = $idx;
          gsub(/^ +| +$/, "", field);
          if (field ~ /^id:/) { sub(/^id:/, "", field); id = field; }
          if (field ~ /^name:/) { sub(/^name:/, "", field); name = field; }
          if (field ~ /^OS:/) { sub(/^OS:/, "", field); os = field; }
          if (field ~ /^platform:/) { sub(/^platform:/, "", field); platform = field; }
        }
        if (platform == "iOS Simulator" && name == wanted_name && id !~ /placeholder/ && id != "" && os != "") {
          print os " " id;
        }
      }
    ' | sort -V | tail -n 1 | awk '{print $2}'
}

fallback_destination_id() {
  xcodebuild -showdestinations -project "$PROJECT" -scheme "$SCHEME" 2>/dev/null | awk -F '[{},]' '
    /platform:iOS Simulator/ && /name:iPhone/ {
      id = ""; name = ""; platform = "";
      for (idx = 1; idx <= NF; idx++) {
        field = $idx;
        gsub(/^ +| +$/, "", field);
        if (field ~ /^id:/) { sub(/^id:/, "", field); id = field; }
        if (field ~ /^name:/) { sub(/^name:/, "", field); name = field; }
        if (field ~ /^platform:/) { sub(/^platform:/, "", field); platform = field; }
      }
      if (platform == "iOS Simulator" && name ~ /^iPhone/ && id !~ /placeholder/ && id != "") {
        print id;
        exit;
      }
    }
  '
}

destination_field() {
  local spec="$1"
  local key="$2"
  printf '%s\n' "$spec" | awk -F ',' -v key="$key" '
    {
      for (idx = 1; idx <= NF; idx++) {
        field = $idx;
        gsub(/^ +| +$/, "", field);
        prefix = key "=";
        if (index(field, prefix) == 1) {
          sub(prefix, "", field);
          print field;
          exit;
        }
      }
    }
  '
}

resolve_requested_destination() {
  local requested="$1"
  local requested_name requested_os destination_id
  requested_name="$(destination_field "$requested" "name")"
  requested_os="$(destination_field "$requested" "OS")"

  if [ "$requested_name" = "" ]; then
    echo "$requested"
    return 0
  fi

  if [ "$requested_os" = "latest" ] || [ "$requested_os" = "" ]; then
    destination_id="$(latest_destination_id_for_name "$requested_name")"
  else
    destination_id="$(destination_id_for "$requested_name" "$requested_os")"
  fi

  if [ "$destination_id" != "" ]; then
    echo "platform=iOS Simulator,id=$destination_id"
    return 0
  fi

  destination_id="$(fallback_destination_id)"
  if [ "$destination_id" != "" ]; then
    echo "platform=iOS Simulator,id=$destination_id"
    echo "Using an available iPhone simulator because requested destination '$requested' was not found." >&2
    return 0
  fi

  echo "$requested"
}

resolve_destination() {
  if [ "${TEST_DESTINATION:-}" != "" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "$TEST_DESTINATION"
    else
      resolve_requested_destination "$TEST_DESTINATION"
    fi
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "platform=iOS Simulator,name=$CANONICAL_DESTINATION_NAME,OS=$CANONICAL_DESTINATION_OS"
    return 0
  fi

  local destination_id
  destination_id="$(destination_id_for "$CANONICAL_DESTINATION_NAME" "$CANONICAL_DESTINATION_OS")"
  if [ "$destination_id" != "" ]; then
    echo "platform=iOS Simulator,id=$destination_id"
    return 0
  fi

  destination_id="$(fallback_destination_id)"
  if [ "$destination_id" != "" ]; then
    echo "platform=iOS Simulator,id=$destination_id"
    echo "Using an available iPhone simulator because $CANONICAL_DESTINATION_NAME iOS $CANONICAL_DESTINATION_OS was not found." >&2
    return 0
  fi

  echo "No usable iPhone simulator destination was found." >&2
  echo "Install $CANONICAL_DESTINATION_NAME with iOS $CANONICAL_DESTINATION_OS, or set TEST_DESTINATION to an available simulator." >&2
  xcodebuild -showdestinations -project "$PROJECT" -scheme "$SCHEME" >&2 || true
  exit 1
}

prepare_result_bundle() {
  local result_bundle="$1"
  rm -rf "$result_bundle"
  mkdir -p "$(dirname "$result_bundle")"
}

run_build() {
  local gate="${1:-build}"
  start_gate "$gate"
  generate_project
  run_cmd xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO \
    SDA_API_KEY= \
    SDA_API_BASE_URL="$LOCAL_API_BASE_URL" \
    build
}

run_xcode_test() {
  local gate="$1"
  local result_bundle="$2"
  local coverage="$3"
  shift 3

  start_gate "$gate"
  generate_project
  prepare_result_bundle "$result_bundle"

  local destination
  destination="$(resolve_destination)"

  local args
  args=(
    xcodebuild
    -project "$PROJECT"
    -scheme "$SCHEME"
    -destination "$destination"
    -derivedDataPath "$DERIVED_DATA"
    -resultBundlePath "$result_bundle"
  )

  if [ "$coverage" = "yes" ]; then
    args+=(-enableCodeCoverage YES)
  fi

  args+=(
    CODE_SIGNING_ALLOWED=NO
    SDA_API_KEY=
    SDA_API_BASE_URL="$LOCAL_API_BASE_URL"
    test
  )

  while [ "$#" -gt 0 ]; do
    args+=("$1")
    shift
  done

  run_cmd "${args[@]}"
}

run_unit() {
  run_xcode_test unit "$RESULTS_DIR/Unit.xcresult" no \
    -only-testing:ScrollDownSportsTests
}

run_coverage() {
  run_xcode_test coverage "$RESULTS_DIR/Coverage.xcresult" yes \
    -only-testing:ScrollDownSportsTests

  mkdir -p "$COVERAGE_DIR"
  run_cmd xcrun xccov view --report "$RESULTS_DIR/Coverage.xcresult"
  if [ "$DRY_RUN" -eq 0 ]; then
    xcrun xccov view --report --json "$RESULTS_DIR/Coverage.xcresult" > "$COVERAGE_DIR/xccov-report.json"
    xcrun xccov view --archive --file-list --json "$RESULTS_DIR/Coverage.xcresult" > "$COVERAGE_DIR/xccov-files.json"
  else
    print_redirect_command "$COVERAGE_DIR/xccov-report.json" xcrun xccov view --report --json "$RESULTS_DIR/Coverage.xcresult"
    print_redirect_command "$COVERAGE_DIR/xccov-files.json" xcrun xccov view --archive --file-list --json "$RESULTS_DIR/Coverage.xcresult"
  fi
  run_cmd swift "$ROOT_DIR/Scripts/check_xccov_thresholds.swift" \
    --report "$COVERAGE_DIR/xccov-report.json" \
    --config "$ROOT_DIR/Config/coverage-thresholds.json" \
    --repo-root "$ROOT_DIR"
}

run_ui_smoke() {
  run_xcode_test ui-smoke "$RESULTS_DIR/UISmoke.xcresult" no \
    -only-testing:ScrollDownSportsUITests/ScrollDownSportsCriticalFlowsUITests
}

run_visual() {
  if [ "${SNAPSHOT_RECORD:-}" = "1" ]; then
    echo "SNAPSHOT_RECORD=1 will record visual baselines. Leave it unset for verification."
  fi
  # Snapshot baselines are tied to the canonical simulator runtime. Matrix
  # destinations are still useful for UI/performance gates, but visual snapshots
  # drift across simulator devices and OS releases.
  unset TEST_DESTINATION
  run_xcode_test visual "$RESULTS_DIR/Visual.xcresult" no \
    -only-testing:ScrollDownSportsTests/HomeVisualRegressionTests \
    -only-testing:ScrollDownSportsTests/GameDetailVisualRegressionTests \
    -only-testing:ScrollDownSportsTests/HomeGameCardSnapshotTests \
    -only-testing:ScrollDownSportsTests/HomeSectionSnapshotTests \
    -only-testing:ScrollDownSportsTests/GameDetailChromeSnapshotTests \
    -only-testing:ScrollDownSportsTests/EventAndScoreboardSnapshotTests \
    -only-testing:ScrollDownSportsTests/StatSectionSnapshotTests
}

run_accessibility() {
  run_xcode_test accessibility "$RESULTS_DIR/Accessibility.xcresult" no \
    -only-testing:ScrollDownSportsUITests/ScrollDownSportsAccessibilityUITests
}

run_performance_smoke() {
  run_xcode_test performance-smoke "$RESULTS_DIR/PerformanceSmoke.xcresult" no \
    -only-testing:ScrollDownSportsTests/PerformanceSmokeTests \
    -only-testing:ScrollDownSportsUITests/ScrollDownSportsPerformanceSmokeUITests
}

run_script_checks() {
  start_gate script-checks
  run_cmd bash "$ROOT_DIR/Scripts/test_xccov_thresholds.sh"
  run_cmd bash "$ROOT_DIR/Scripts/test_ci_workflow_shape.sh"
  run_cmd bash "$ROOT_DIR/Scripts/test_local_gate.sh"
}

run_full_local() {
  run_build build
  run_coverage
  run_script_checks
  run_ui_smoke
}

clean_artifacts() {
  start_gate clean-artifacts
  run_cmd rm -rf "$DERIVED_DATA" "$RESULTS_DIR" "$COVERAGE_DIR" "$ARTIFACTS_DIR"
}

if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

if [ "$#" -ne 1 ]; then
  usage
  exit 1
fi

case "$1" in
  fast)
    run_build fast
    ;;
  build)
    run_build build
    ;;
  unit)
    run_unit
    ;;
  coverage)
    run_coverage
    ;;
  ui-smoke)
    run_ui_smoke
    ;;
  visual)
    run_visual
    ;;
  accessibility)
    run_accessibility
    ;;
  performance-smoke)
    run_performance_smoke
    ;;
  full-local)
    run_full_local
    ;;
  script-checks)
    run_script_checks
    ;;
  clean-artifacts)
    clean_artifacts
    ;;
  *)
    echo "Unknown gate: $1"
    usage
    exit 1
    ;;
esac
