#!/usr/bin/env bash
# Report (default) or sever (--fix) links that leak pi-setup skills into the shared
# ~/.agents/skills hub. Only settings.json, memory, and skills/ should tie pi to pi-setup.
set -euo pipefail

REPO="${PI_SETUP_REPO:-$HOME/pi-setup}"
AGENTS_ROOT="${AGENTS_ROOT:-$HOME/.agents}"
HUB="${AGENTS_HUB:-$AGENTS_ROOT/skills}"
FIX=0
[ "${1:-}" = "--fix" ] && FIX=1

leaks=0
for link in "$HUB"/*; do
  [ -L "$link" ] || continue
  target=$(readlink "$link")
  case "$target" in
    "$REPO"/*)
      leaks=$((leaks + 1))
      name=$(basename "$link")
      if [ "$FIX" = 1 ]; then
        # Keep the skill working for other agents: replace the link with a real copy.
        rm "$link"
        cp -R "$target" "$link"
        echo "severed  $name (copied to hub)"
      else
        echo "leak     $name -> $target"
      fi
      ;;
  esac
done

# Stale backup directories beside ~/.agents/skills can be discovered as agent
# bundles. Their agents/*.md may shadow current agents and pin dead model aliases.
shadow_bundles=0
for dir in "$AGENTS_ROOT"/skills-*; do
  [ -d "$dir" ] || continue
  if find "$dir" -type f -path '*/agents/*.md' -print -quit 2>/dev/null | grep -q .; then
    shadow_bundles=$((shadow_bundles + 1))
    if [ "$FIX" = 1 ]; then
      dest="$AGENTS_ROOT/.backups/skills/$(basename "$dir")-$(date +%Y%m%d-%H%M%S)"
      mkdir -p "$(dirname "$dest")"
      mv "$dir" "$dest"
      echo "moved     $(basename "$dir") -> $dest (no longer discoverable)"
    else
      echo "shadow   $dir contains agents/*.md and may override current agents"
    fi
  fi
done

echo "---"
if [ "$leaks" = 0 ]; then
  echo "clean: no hub skill links back into $REPO"
elif [ "$FIX" = 1 ]; then
  echo "severed $leaks link(s); pi-setup skills are now pi-only"
else
  echo "$leaks leak(s); rerun with --fix to sever"
fi
if [ "$shadow_bundles" = 0 ]; then
  echo "clean: no discoverable skills-* backup contains agent prompts"
elif [ "$FIX" = 1 ]; then
  echo "moved $shadow_bundles shadow bundle(s) under .agents/.backups/"
else
  echo "$shadow_bundles shadow bundle(s); rerun with --fix to move safely"
fi

# The exclusion is what actually keeps pi off the hub — verify it is still set.
python3 - "$REPO/settings.json" "$HUB" <<'PY'
import json, os, sys
s = json.load(open(sys.argv[1])).get("skills", [])
hub = os.path.realpath(sys.argv[2])
print("settings.skills:", s or "(unset)")

# The pattern is matched against real absolute paths with no ~ or $HOME
# expansion, so a literal home dir baked in on another machine silently
# excludes nothing. Only accept patterns that can match THIS hub.
def reaches_hub(p):
    body = p[1:]
    if "/Users/" in body or body.startswith("~") or "\\Users\\" in body:
        return hub.rstrip("/").startswith(body.split("**")[0].rstrip("/"))
    return ".agents/skills" in body

excludes = [p for p in s if p.startswith("!") and ".agents/skills" in p]
live = [p for p in excludes if reaches_hub(p)]
print("hub excluded:", bool(live))
for p in excludes:
    if p not in live:
        print(f"  !! dead pattern (does not match {hub}): {p}")
PY
