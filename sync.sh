#!/usr/bin/env bash
# Save current pi setup drift back to GitHub.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
git add -A

# Privacy tripwire: block domain identifiers from entering the public repo.
# Checks only ADDED lines; 'swarmforge' allowlisted (public repo name).
LEAKS=$(git diff --cached -- . ':(exclude)sync.sh' | grep -E '^\+[^+]' | grep -iv 'swarmforge' \
  | grep -inE 'aidt|sso2|lcms|심사계|tb_lms_|tb_sso_|dongahub|aidtbook|d-aidt' || true)
if [ -n "$LEAKS" ]; then
  echo "⛔ PRIVATE LEAK? Staged additions contain domain identifiers:"
  echo "$LEAKS" | head -10
  echo "Unstage or move to a gitignored domain pack, then re-run."
  git reset --quiet
  exit 1
fi

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
