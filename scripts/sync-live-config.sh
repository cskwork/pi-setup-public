#!/usr/bin/env bash
# Mirror Pi's mutable config back to pi-setup and restore canonical symlinks.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PI_AGENT_DIR="${PI_DIR:-$HOME/.pi/agent}"
MODE="${1:-}"
PYTHON="$(command -v python3 || command -v python || true)"
[ -n "$PYTHON" ] || { echo "Python 3 is required." >&2; exit 1; }

validate_json() {
  "$PYTHON" -c 'import json,sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$1"
}

sync_one() { # sync_one <live> <canonical>
  local live="$1" canonical="$2" tmp stamp backup
  mkdir -p "$(dirname "$live")" "$(dirname "$canonical")"

  if [ "$MODE" != "--prefer-repo" ] && [ -f "$live" ] && [ ! -L "$live" ]; then
    validate_json "$live"
    tmp="${canonical}.tmp-$$"
    cp "$live" "$tmp"
    validate_json "$tmp"
    if [ ! -f "$canonical" ] || ! cmp -s "$tmp" "$canonical"; then
      if [ -f "$canonical" ]; then
        stamp="$(date +%Y%m%d-%H%M%S)"
        backup="${canonical}.bak-${stamp}-$$"
        cp "$canonical" "$backup"
      fi
      mv "$tmp" "$canonical"
    else
      rm -f "$tmp"
    fi
  fi

  [ -f "$canonical" ] || { echo "missing canonical config: $canonical" >&2; exit 1; }
  validate_json "$canonical"

  if [ -L "$live" ] && [ "$(readlink "$live")" = "$canonical" ]; then
    return
  fi

  if [ -e "$live" ] || [ -L "$live" ]; then
    if [ "$MODE" != "--prefer-repo" ] && ! cmp -s "$live" "$canonical"; then
      echo "live config changed during sync; retrying later: $live" >&2
      exit 1
    fi
    rm -f "$live"
  fi
  ln -s "$canonical" "$live"
}

sync_one "$PI_AGENT_DIR/settings.json" "$REPO/settings.json"
sync_one "$HOME/.pi/acp.json" "$REPO/acp.json"

echo "Pi config synced to $REPO"
