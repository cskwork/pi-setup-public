#!/usr/bin/env bash
# sync-status.sh — READ-ONLY drift report for the agent prompt + essential skills.
# Writes nothing. The agent presents this as the as-is side of the sync plan.
set -uo pipefail  # no -e: a missing copy is a finding, not a crash

PRIV="${PI_SETUP:-$HOME/pi-setup}"
PUB="${PI_SETUP_PUBLIC:-$HOME/pi-setup-public}"
LIVE="$HOME/.agents/AGENTS.md"
SDLC="${SDLC_KIT:-$HOME/Documents/Git/sdlc-kit}"
PBOX="${PROMPTBOX:-$HOME/Documents/PARA/Resource/promptbox}"

section() { printf '\n== %s\n' "$1"; }
h() { git hash-object "$1" 2>/dev/null || echo missing; }

section "operating contract (AGENTS.md × 4)"
a=$(h "$LIVE"); b=$(h "$PRIV/AGENTS.md"); c=$(h "$PUB/AGENTS.md")
printf '  %-8s %s  %s\n' live "$a" "$LIVE"
printf '  %-8s %s  %s\n' private "$b" "$PRIV/AGENTS.md"
printf '  %-8s %s  %s\n' public "$c" "$PUB/AGENTS.md"
if [ "$a" = "$b" ] && [ "$b" = "$c" ] && [ "$a" != missing ]; then
  echo "  local copies: MATCH"
else
  echo "  local copies: DRIFT"
fi
if command -v gh >/dev/null 2>&1; then
  while read -r repo path; do
    sha=$(gh api "repos/$repo/contents/$path" --jq .sha 2>/dev/null || echo unreachable)
    if [ "$sha" = "$a" ]; then st=match; else st="DRIFT ($sha)"; fi
    printf '  remote %-26s %s\n' "$repo" "$st"
  done <<'EOF'
cskwork/pi-setup AGENTS.md
cskwork/pi-setup-public AGENTS.md
cskwork/prime-agent-sync agents/AGENTS.md
EOF
else
  echo "  (gh unavailable: remote blob SHAs unchecked)"
fi

section "skills: pi-setup vs pi-setup-public (common subset)"
out=$(diff -rq --exclude=.git --exclude=.verify --exclude=__pycache__ \
  "$PRIV/skills" "$PUB/skills" 2>/dev/null | grep -v "^Only in $PRIV/skills")
if [ -n "$out" ]; then echo "$out" | sed 's/^/  /'; else echo "  MATCH"; fi
echo "  (paths only in private are expected: work-IP never goes public)"

section "sdlc-kit: canonical vs pi-setup mirror"
out=$(diff -rq -x .git -x .gitignore -x .gitattributes -x LICENSE -x README.md \
  -x docs -x .pi -x .verify -x .impeccable "$SDLC" "$PRIV/skills/sdlc-kit" 2>/dev/null)
if [ -n "$out" ]; then echo "$out" | sed 's/^/  /'; else echo "  MATCH"; fi
echo "  (verify skill: canonical is cskwork/verify-skill — compare per file, no local checkout)"

section "onboarding (promptbox)"
if [ -d "$PBOX" ]; then
  if (cd "$PBOX" && npm run -s check:prompt >/dev/null 2>&1); then
    echo "  check:prompt PASS (txt == fence)"
  else
    echo "  check:prompt FAIL — regenerate the fence from src/data/pi-setup-prompt.txt"
  fi
  grep -n "operating contract" "$PBOX/src/data/pi-setup-prompt.txt" | sed 's/^/  txt /'
  echo "  ^ this summary must name the ACTUAL steps in AGENTS.md — compare by eye"
else
  echo "  promptbox not found at $PBOX"
fi
