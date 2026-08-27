#!/usr/bin/env bash
# Report (default) or sever (--fix) links that leak pi-setup skills into the shared
# ~/.agents/skills hub. Only settings.json, memory, and skills/ should tie pi to pi-setup.
set -euo pipefail

REPO="${PI_SETUP_REPO:-$HOME/pi-setup}"
HUB="${AGENTS_HUB:-$HOME/.agents/skills}"
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

echo "---"
if [ "$leaks" = 0 ]; then
  echo "clean: no hub skill links back into $REPO"
elif [ "$FIX" = 1 ]; then
  echo "severed $leaks link(s); pi-setup skills are now pi-only"
else
  echo "$leaks leak(s); rerun with --fix to sever"
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
