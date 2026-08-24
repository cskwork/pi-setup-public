#!/usr/bin/env bash
# Save current pi setup drift back to GitHub.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
git add -A
if git diff --cached --quiet; then
  echo "Already in sync ✅"
else
  git commit -m "sync: $(date '+%Y-%m-%d %H:%M')" >/dev/null
  git push --quiet
  echo "Committed and pushed ✅"
fi

# Pull live permission config (user edits it via the TUI modal) into the repo copy
if [ -f extensions/pi-permission-system/config.json ]; then
  cp extensions/pi-permission-system/config.json configs/permissions.json
else
  # Live copy vanished — self-heal from the repo canonical
  mkdir -p extensions/pi-permission-system
  cp configs/permissions.json extensions/pi-permission-system/config.json
fi
