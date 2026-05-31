#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if rg -n '"/api/admin|/api/admin' "$ROOT_DIR/ScrollDownSports"; then
  echo "Release client code must not call SDA admin API paths. Use /api/v1 consumer endpoints." >&2
  exit 1
fi
