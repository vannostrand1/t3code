#!/usr/bin/env bash
set -eu
printf 'T3 frontier team preflight\n'
for name in t3 git python3 claude codex; do
  if command -v "$name" >/dev/null 2>&1; then
    printf 'FOUND %s: %s\n' "$name" "$(command -v "$name")"
  else
    printf 'MISSING %s\n' "$name"
  fi
done
printf 'No changes made. Confirm provider IDs inside T3.\n'
