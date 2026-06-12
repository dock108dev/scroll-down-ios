#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPLOAD_DIR="$ROOT_DIR/.build/artifacts/uploads"

usage() {
  cat <<'EOF'
Usage: Scripts/package_ci_artifact.sh <artifact-name> <path> [<path>...]

Packages existing CI diagnostic paths into one .tar.gz file under
.build/artifacts/uploads. Missing paths are ignored so failure-only diagnostics
can be collected from always() workflow steps.
EOF
}

if [ "$#" -lt 2 ]; then
  usage >&2
  exit 2
fi

artifact_name="$1"
shift

mkdir -p "$UPLOAD_DIR"
archive="$UPLOAD_DIR/$artifact_name.tar.gz"
temp_archive="$archive.tmp"
rm -f "$archive"
rm -f "$temp_archive"

included_paths=()
for requested_path in "$@"; do
  if [[ "$requested_path" == *[\*\?\[]* ]]; then
    while IFS= read -r matched_path; do
      if [ -e "$ROOT_DIR/$matched_path" ]; then
        included_paths+=("$matched_path")
      fi
    done < <(cd "$ROOT_DIR" && compgen -G "$requested_path" || true)
  elif [ -e "$ROOT_DIR/$requested_path" ]; then
    included_paths+=("$requested_path")
  fi
done

if [ "${#included_paths[@]}" -eq 0 ]; then
  echo "No files found for $artifact_name."
  exit 0
fi

(
  cd "$ROOT_DIR"
  tar -czf "$temp_archive" "${included_paths[@]}"
)
mv "$temp_archive" "$archive"

echo "Packaged ${#included_paths[@]} path(s) into $archive."
