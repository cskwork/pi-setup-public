#!/usr/bin/env bash
# Restore this pi setup on any machine.
# Symlinks ~/.pi/agent items to this repo, then installs pi packages.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_DIR="${PI_DIR:-$HOME/.pi/agent}"
BACKUP="$PI_DIR.backup.$(date +%Y%m%d-%H%M%S)"
# ponytail: on Windows (no Developer Mode/admin) symlinks fail — fall back to
# copying. Copies drift instead of tracking the repo; re-run install.sh to refresh.

link() { # link <repo-item> <dest-name>
  local src="$REPO/$1" dst="$PI_DIR/$2"
  mkdir -p "$PI_DIR"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "  ✓ $2 (already linked)"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$BACKUP"
    mv "$dst" "$BACKUP/"
    echo "  ↩ existing $2 backed up to $BACKUP/"
  fi
  if ln -s "$src" "$dst" 2>/dev/null; then
    echo "  🔗 $2 → $src"
  else
    cp -R "$src" "$dst"
    echo "  📄 $2 copied (symlinks unavailable — enable Windows Developer Mode for live links)"
  fi
}

echo "==> Linking pi setup into $PI_DIR"
link AGENTS.md     AGENTS.md
link settings.json settings.json
link models.json   models.json
link extensions    extensions
link agents        agents
link skills        skills
link profiles      profiles

# Deploy permission config into the runtime extension dir
mkdir -p "$REPO/extensions/pi-permission-system"
cp -f "$REPO/configs/permissions.json" "$REPO/extensions/pi-permission-system/config.json"

echo "==> Installing pi packages (list comes from settings.json)"
PACKAGES="$("$(command -v python3 || command -v python)" -c "import json;print('\n'.join(json.load(open('$REPO/settings.json'))['packages']))")"
while IFS= read -r pkg; do
  [ -z "$pkg" ] && continue
  case "$pkg" in
    npm:*) pi install "$pkg" >/dev/null 2>&1 && echo "  ✓ $pkg" || echo "  ⚠ failed: $pkg — run: pi install $pkg" ;;
    *)     echo "  ⏭ skipped non-npm entry: $pkg" ;;
  esac
done <<< "$PACKAGES"

echo "==> External CLI dependencies"
# pi-agent-browser-native deliberately does not bundle the upstream CLI.
if command -v agent-browser >/dev/null 2>&1; then
  echo "  ✓ agent-browser ($(agent-browser --version 2>/dev/null))"
else
  if npm install -g agent-browser >/dev/null 2>&1; then
    echo "  ✓ agent-browser (installed globally via npm)"
  else
    echo "  ⚠ agent-browser CLI missing — pi-agent-browser-native will fail its doctor."
    echo "    Run: npm install -g agent-browser"
  fi
fi
# browser-qa's deterministic replay runtime is optional but recommended.
if ! command -v superqa >/dev/null 2>&1; then
  echo "  ⚠ superqa not on PATH — browser-qa scenario replay unavailable."
  echo "    Interactive exploration still works via the agent_browser tool."
  echo "    Install: https://github.com/cskwork/browser-qa"
fi

echo
echo "Done. Next steps:"
echo "  1. pi auth        # log in to your providers (zai, anthropic, openai-codex)"
echo "  2. restart pi"
echo "  3. optional: verify browser tooling — npx pi-agent-browser-doctor"
