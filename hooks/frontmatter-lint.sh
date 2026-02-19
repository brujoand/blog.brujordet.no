#!/usr/bin/env bash
set -euo pipefail

fail=0

for f in "$@"; do
  [[ "$f" == content/post/*.md || "$f" == content/post/**/*.md ]] || continue

  if ! grep -q '^title:' "$f"; then
    echo "ERROR: missing 'title' in front matter: $f"
    fail=1
  fi

  if ! grep -q '^date:' "$f"; then
    echo "ERROR: missing 'date' in front matter: $f"
    fail=1
  fi

  if ! grep -q '^categories:' "$f"; then
    echo "ERROR: missing 'categories' in front matter: $f"
    fail=1
  fi
done

exit $fail
