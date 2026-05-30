#!/usr/bin/env bash
set -euo pipefail

# Size note: gate modes stay together until shared xcodebuild/result-bundle helpers are split; see cleanup report.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/ScrollDownSports.xcodeproj"
PROJECT_YML="$ROOT_DIR/project.yml"
SCHEME="ScrollDownSports"
DERIVED_DATA="$ROOT_DIR/.build/DerivedData"
RESULTS_DIR="$ROOT_DIR/.build/TestResults"
COVERAGE_DIR="$ROOT_DIR/.build/coverage"
ARTIFACTS_DIR="$ROOT_DIR/.build/artifacts"
CANONICAL_PHONE_DESTINATION_NAME="iPhone 17 Pro"
CANONICAL_PHONE_DESTINATION_OS="26.2"
CANONICAL_IPAD_DESTINATION_NAME="iPad Pro 13-inch (M5)"
CANONICAL_IPAD_DESTINATION_OS="26.2"
LOCAL_API_BASE_URL="http://127.0.0.1.invalid"
DRY_RUN=0
CURRENT_GATE=""
STRICT_DESTINATION=0

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
  multitasking         Check iPad multitasking project and app-shape invariants.
  ipad-ui-smoke        Run critical XCUITest flows on an iPad-family simulator.
  ipad-visual          Run committed visual snapshots for the iPad nightly job.
  ipad-accessibility   Run accessibility XCUITest audits on an iPad-family simulator.
  ipad-multitasking    Check iPad multitasking project and app-shape invariants.
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

fallback_destination_id_for_family() {
  local family="$1"
  local name_regex
  case "$family" in
    iphone)
      name_regex="^iPhone"
      ;;
    ipad)
      name_regex="^iPad"
      ;;
    *)
      echo "Unknown simulator destination family: $family" >&2
      exit 1
      ;;
  esac

  xcodebuild -showdestinations -project "$PROJECT" -scheme "$SCHEME" 2>/dev/null | awk -F '[{},]' \
    -v name_regex="$name_regex" '
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
      if (platform == "iOS Simulator" && name ~ name_regex && id !~ /placeholder/ && id != "" && os != "") {
        print os " " id;
      }
    }
  ' | sort -V | tail -n 1 | awk '{print $2}'
}

simctl_destination_id_for() {
  local wanted_name="$1"
  local wanted_os="$2"
  xcrun simctl list devices available 2>/dev/null | awk \
    -v wanted_name="$wanted_name" \
    -v wanted_runtime="iOS $wanted_os" '
      /^-- / {
        runtime = $0;
        gsub(/^-- | --$/, "", runtime);
        next;
      }
      runtime == wanted_runtime && index($0, "    " wanted_name " (") == 1 {
        print;
        exit;
      }
    ' | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/'
}

runtime_identifier_for_os() {
  local wanted_os="$1"
  xcrun simctl list runtimes 2>/dev/null | awk -v wanted_os="$wanted_os" '
    index($0, "iOS " wanted_os " ") == 1 && $0 !~ /unavailable/ {
      print $NF;
      exit;
    }
  '
}

device_type_identifier_for_name() {
  local wanted_name="$1"
  xcrun simctl list devicetypes 2>/dev/null | awk -v wanted_name="$wanted_name" '
    index($0, wanted_name " (com.apple.CoreSimulator.SimDeviceType.") == 1 {
      sub(/^.*\(/, "");
      sub(/\).*$/, "");
      print;
      exit;
    }
  '
}

create_destination_id_for() {
  local wanted_name="$1"
  local wanted_os="$2"
  local runtime_id device_type_id destination_id
  if [ "$wanted_name" = "" ] || [ "$wanted_os" = "" ] || [ "$wanted_os" = "latest" ]; then
    return 0
  fi

  destination_id="$(simctl_destination_id_for "$wanted_name" "$wanted_os")"
  if [ "$destination_id" != "" ]; then
    echo "$destination_id"
    return 0
  fi

  runtime_id="$(runtime_identifier_for_os "$wanted_os")"
  device_type_id="$(device_type_identifier_for_name "$wanted_name")"
  if [ "$runtime_id" = "" ] || [ "$device_type_id" = "" ]; then
    return 0
  fi

  xcrun simctl create "ScrollDownSports $wanted_name iOS $wanted_os" "$device_type_id" "$runtime_id" 2>/dev/null
}

destination_family_for_name() {
  local name="$1"
  case "$name" in
    iPhone*) echo "iphone" ;;
    iPad*) echo "ipad" ;;
    *) echo "" ;;
  esac
}

destination_family_for_spec() {
  local spec="$1"
  local name
  name="$(destination_field "$spec" "name")"
  destination_family_for_name "$name"
}

require_ipad_destination_spec() {
  local spec="${TEST_DESTINATION:-}"
  local family
  if [ "$spec" = "" ]; then
    return 0
  fi

  family="$(destination_family_for_spec "$spec")"
  if [ "$family" = "ipad" ]; then
    return 0
  fi

  echo "iPad gate requires an iPad simulator destination." >&2
  echo "Set TEST_DESTINATION to an iPad simulator, or leave it unset for the canonical iPad destination." >&2
  exit 1
}

require_canonical_ipad_visual_spec() {
  local spec="${TEST_DESTINATION:-}"
  local requested_name requested_os
  if [ "$spec" = "" ]; then
    return 0
  fi

  requested_name="$(destination_field "$spec" "name")"
  requested_os="$(destination_field "$spec" "OS")"
  if [ "$requested_name" = "$CANONICAL_IPAD_DESTINATION_NAME" ] && [ "$requested_os" = "$CANONICAL_IPAD_DESTINATION_OS" ]; then
    return 0
  fi

  echo "iPad visual runs require the pinned destination: platform=iOS Simulator,name=$CANONICAL_IPAD_DESTINATION_NAME,OS=$CANONICAL_IPAD_DESTINATION_OS." >&2
  exit 1
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
  local strict="${2:-0}"
  local requested_name requested_os requested_family destination_id
  requested_name="$(destination_field "$requested" "name")"
  requested_os="$(destination_field "$requested" "OS")"
  requested_family="$(destination_family_for_name "$requested_name")"

  if [ "$requested_name" = "" ]; then
    echo "$requested"
    return 0
  fi

  if [ "$strict" -eq 1 ] && { [ "$requested_os" = "latest" ] || [ "$requested_os" = "" ]; }; then
    echo "Pinned simulator destination required for this gate: '$requested'." >&2
    echo "Set OS to an exact runtime, for example OS=$CANONICAL_IPAD_DESTINATION_OS." >&2
    exit 1
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

  destination_id="$(create_destination_id_for "$requested_name" "$requested_os")"
  if [ "$destination_id" != "" ]; then
    echo "platform=iOS Simulator,id=$destination_id"
    echo "Created $requested_family simulator destination for '$requested'." >&2
    return 0
  fi

  if [ "$strict" -eq 1 ]; then
    echo "Required simulator destination was not found: '$requested'." >&2
    xcodebuild -showdestinations -project "$PROJECT" -scheme "$SCHEME" >&2 || true
    exit 1
  fi

  if [ "$requested_family" = "" ]; then
    echo "Requested simulator destination was not found and its family could not be inferred: '$requested'." >&2
    echo "Use an iPhone or iPad simulator name, or pass a concrete simulator id." >&2
    exit 1
  fi

  destination_id="$(fallback_destination_id_for_family "$requested_family")"
  if [ "$destination_id" != "" ]; then
    echo "platform=iOS Simulator,id=$destination_id"
    echo "Using an available $requested_family simulator because requested destination '$requested' was not found." >&2
    return 0
  fi

  echo "Requested $requested_family destination was not found." >&2
  echo "No usable $requested_family simulator destination was found." >&2
  echo "Install the requested simulator, or set TEST_DESTINATION to an available $requested_family simulator." >&2
  xcodebuild -showdestinations -project "$PROJECT" -scheme "$SCHEME" >&2 || true
  exit 1
}

resolve_destination() {
  if [ "${TEST_DESTINATION:-}" != "" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "$TEST_DESTINATION"
    else
      resolve_requested_destination "$TEST_DESTINATION" "$STRICT_DESTINATION"
    fi
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "platform=iOS Simulator,name=$CANONICAL_PHONE_DESTINATION_NAME,OS=$CANONICAL_PHONE_DESTINATION_OS"
    return 0
  fi

  local destination_id
  destination_id="$(destination_id_for "$CANONICAL_PHONE_DESTINATION_NAME" "$CANONICAL_PHONE_DESTINATION_OS")"
  if [ "$destination_id" != "" ]; then
    echo "platform=iOS Simulator,id=$destination_id"
    return 0
  fi

  destination_id="$(create_destination_id_for "$CANONICAL_PHONE_DESTINATION_NAME" "$CANONICAL_PHONE_DESTINATION_OS")"
  if [ "$destination_id" != "" ]; then
    echo "platform=iOS Simulator,id=$destination_id"
    echo "Created iphone simulator destination for $CANONICAL_PHONE_DESTINATION_NAME iOS $CANONICAL_PHONE_DESTINATION_OS." >&2
    return 0
  fi

  if [ "$STRICT_DESTINATION" -eq 1 ]; then
    echo "Required simulator destination was not found: $CANONICAL_PHONE_DESTINATION_NAME iOS $CANONICAL_PHONE_DESTINATION_OS." >&2
    xcodebuild -showdestinations -project "$PROJECT" -scheme "$SCHEME" >&2 || true
    exit 1
  fi

  destination_id="$(fallback_destination_id_for_family iphone)"
  if [ "$destination_id" != "" ]; then
    echo "platform=iOS Simulator,id=$destination_id"
    echo "Using an available iphone simulator because $CANONICAL_PHONE_DESTINATION_NAME iOS $CANONICAL_PHONE_DESTINATION_OS was not found." >&2
    return 0
  fi

  echo "No usable iPhone simulator destination was found." >&2
  echo "Install $CANONICAL_PHONE_DESTINATION_NAME with iOS $CANONICAL_PHONE_DESTINATION_OS, or set TEST_DESTINATION to an available iPhone simulator." >&2
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
  if [ "$(destination_family_for_spec "${TEST_DESTINATION:-}")" = "ipad" ]; then
    require_canonical_ipad_visual_spec
    STRICT_DESTINATION=1
  else
    unset TEST_DESTINATION
    STRICT_DESTINATION=0
  fi
  run_visual_selection visual "$RESULTS_DIR/Visual.xcresult"
}

run_visual_selection() {
  local gate="$1"
  local result_bundle="$2"
  run_xcode_test "$gate" "$result_bundle" no \
    -only-testing:ScrollDownSportsTests/HomeVisualRegressionTests \
    -only-testing:ScrollDownSportsTests/GameDetailVisualRegressionTests \
    -only-testing:ScrollDownSportsTests/HomeGameCardSnapshotTests \
    -only-testing:ScrollDownSportsTests/HomeSectionSnapshotTests \
    -only-testing:ScrollDownSportsTests/GameDetailChromeSnapshotTests \
    -only-testing:ScrollDownSportsTests/EventAndScoreboardSnapshotTests \
    -only-testing:ScrollDownSportsTests/SituationDiagramLayoutSnapshotTests \
    -only-testing:ScrollDownSportsTests/StatSectionSnapshotTests
}

run_accessibility() {
  run_xcode_test accessibility "$RESULTS_DIR/Accessibility.xcresult" no \
    -only-testing:ScrollDownSportsUITests/ScrollDownSportsAccessibilityUITests
}

run_multitasking() {
  start_gate multitasking
  run_cmd ruby "$ROOT_DIR/Scripts/check_multitasking_project_invariants.rb"
}

run_ipad_ui_smoke() {
  require_ipad_destination_spec
  TEST_DESTINATION="${TEST_DESTINATION:-platform=iOS Simulator,name=$CANONICAL_IPAD_DESTINATION_NAME,OS=$CANONICAL_IPAD_DESTINATION_OS}"
  STRICT_DESTINATION=0
  run_xcode_test ipad-ui-smoke "$RESULTS_DIR/IPadUISmoke.xcresult" no \
    -only-testing:ScrollDownSportsUITests/ScrollDownSportsCriticalFlowsUITests
}

run_ipad_visual() {
  if [ "${SNAPSHOT_RECORD:-}" = "1" ]; then
    echo "SNAPSHOT_RECORD=1 will record iPad visual baselines. Leave it unset for verification."
  fi
  # Snapshot baselines are view-size driven and are recorded from the canonical
  # snapshot host. Running the same baselines on iPad simulator hardware adds
  # device-specific rendering drift without improving iPad runtime coverage.
  unset TEST_DESTINATION
  STRICT_DESTINATION=0
  run_visual_selection ipad-visual "$RESULTS_DIR/IPadVisual.xcresult"
}

run_ipad_accessibility() {
  require_ipad_destination_spec
  TEST_DESTINATION="${TEST_DESTINATION:-platform=iOS Simulator,name=$CANONICAL_IPAD_DESTINATION_NAME,OS=$CANONICAL_IPAD_DESTINATION_OS}"
  STRICT_DESTINATION=0
  run_xcode_test ipad-accessibility "$RESULTS_DIR/IPadAccessibility.xcresult" no \
    -only-testing:ScrollDownSportsUITests/ScrollDownSportsAccessibilityUITests
}

run_ipad_multitasking() {
  require_ipad_destination_spec
  TEST_DESTINATION="${TEST_DESTINATION:-platform=iOS Simulator,name=$CANONICAL_IPAD_DESTINATION_NAME,OS=$CANONICAL_IPAD_DESTINATION_OS}"
  start_gate ipad-multitasking
  run_cmd ruby "$ROOT_DIR/Scripts/check_multitasking_project_invariants.rb"
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
  run_cmd ruby "$ROOT_DIR/Scripts/check_multitasking_project_invariants.rb"
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
  multitasking)
    run_multitasking
    ;;
  ipad-ui-smoke)
    run_ipad_ui_smoke
    ;;
  ipad-visual)
    run_ipad_visual
    ;;
  ipad-accessibility)
    run_ipad_accessibility
    ;;
  ipad-multitasking)
    run_ipad_multitasking
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
