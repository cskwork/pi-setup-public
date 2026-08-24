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

# Re-deploy permission config (self-heals if the runtime copy vanishes)
mkdir -p extensions/pi-permission-system
cmp -s configs/permissions.json extensions/pi-permission-system/config.json || \
  cp configs/permissions.json extensions/pi-permission-system/config.json
