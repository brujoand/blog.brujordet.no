#!/usr/bin/env bash
set -euo pipefail

fail=0

for f in "$@"; do
  [[ "$f" == content/* ]] || continue

  while IFS= read -r src; do
    local_path="static/${src#/}"
    if [[ ! -f "$local_path" ]]; then
      echo "ERROR: missing static asset '$src' referenced in $f"
      fail=1
    fi
  done < <(grep -oP '(?<=src="/)[^"]+' "$f" 2>/dev/null || true)
done

exit $fail
