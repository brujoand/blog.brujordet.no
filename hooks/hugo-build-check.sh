#!/usr/bin/env bash
set -euo pipefail

HUGO=$(mise x -- which hugo 2>/dev/null || which hugo 2>/dev/null || true)
if [[ -z "$HUGO" ]]; then
  echo "ERROR: hugo not found (run: mise install)"
  exit 1
fi

"$HUGO" --renderToMemory --quiet 2>&1 || {
  echo "ERROR: Hugo build failed"
  exit 1
}
