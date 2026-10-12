#!/usr/bin/env bash
# Fail when a Pi settings or profile file still uses a field that a package has
# removed. pi-subagents 0.68.0 (2026-09-15) dropped `fallbackModels`; from
# 0.70.1 the extension refuses to load while any agent override has it:
#   Builtin override '<name>' in '<file>' uses removed field 'fallbackModels'
#
# Usage: scripts/check-removed-fields.sh [file ...]
# With no arguments it checks this repo's settings.json and profiles. Pass a
# project's .pi/settings.json to check that too, e.g. before opening Pi there.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
files=("$@")
if [ ${#files[@]} -eq 0 ]; then
  files=(settings.json profiles/pi-subagents/*.json)
fi
status=0
for file in "${files[@]}"; do
  [ -f "$file" ] || { echo "  WARN $file not found"; continue; }
  if grep -n '"fallbackModels"' "$file"; then
    echo "  FAIL $file uses removed field fallbackModels; pi-subagents >= 0.70.1 refuses to load. Remove it and configure one model per agent."
    status=1
  fi
done
[ $status -eq 0 ] && echo "  OK no removed pi-subagents fields in ${#files[@]} file(s)"
exit $status
