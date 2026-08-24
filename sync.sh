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

# Personal permission config is gitignored (repo ships a friendly public default).
# If the live copy is missing, deploy the default so a fresh checkout just works.
if [ ! -f extensions/pi-permission-system/config.json ]; then
  mkdir -p extensions/pi-permission-system
  cp configs/permissions.json extensions/pi-permission-system/config.json
fi
