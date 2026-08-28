#!/usr/bin/env bash
# Restore this pi setup on any machine.
# Symlinks ~/.pi/agent items to this repo, then installs pi packages.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_DIR="${PI_DIR:-$HOME/.pi/agent}"
BACKUP="$PI_DIR.backup.$(date +%Y%m%d-%H%M%S)"
PYTHON="$(command -v python3 || command -v python || true)"
[ -n "$PYTHON" ] || { echo "Python 3 is required." >&2; exit 1; }
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

shell_profiles() {
  local shell_name="${SHELL##*/}"
  case "$shell_name" in
    zsh) printf '%s\n' "$HOME/.zshrc" ;;
    bash)
      printf '%s\n' "$HOME/.bashrc"
      case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*) printf '%s\n' "$HOME/.bash_profile" ;;
      esac
      ;;
  esac
}

# write_profile_block <profile> <wrapper> <start-marker> <end-marker>
write_profile_block() {
  "$PYTHON" - "$1" "$2" "$3" "$4" <<'PY'
import os
import shlex
import sys
from pathlib import Path

start = sys.argv[3]
end = sys.argv[4]
path = Path(sys.argv[1]).expanduser()
write_path = path.resolve() if path.is_symlink() else path
source_line = f". {shlex.quote(sys.argv[2])}"
block = f"{start}\n{source_line}\n{end}"
write_path.parent.mkdir(parents=True, exist_ok=True)
text = write_path.read_text(encoding="utf-8") if write_path.exists() else ""

if text.count(start) != text.count(end) or text.count(start) > 1:
    raise SystemExit(f"refusing to edit malformed managed block in {path}")

if start in text:
    before, rest = text.split(start, 1)
    _, after = rest.split(end, 1)
    pieces = [part for part in (before.rstrip(), block, after.lstrip()) if part]
    updated = "\n\n".join(pieces) + "\n"
else:
    updated = text.rstrip()
    if updated:
        updated += "\n\n"
    updated += block + "\n"

if updated == text:
    print("unchanged")
else:
    temp = write_path.with_name(write_path.name + ".pi-setup.tmp")
    temp.write_text(updated, encoding="utf-8")
    os.replace(temp, write_path)
    print("updated")
PY
}

# install_profile_wrapper <wrapper-path> <start-marker> <end-marker> <label>
install_profile_wrapper() {
  local wrapper="$1" start="$2" end="$3" label="$4" profile result
  local profiles=()
  while IFS= read -r profile; do
    [ -n "$profile" ] && profiles+=("$profile")
  done < <(shell_profiles)

  if [ "${#profiles[@]}" -eq 0 ]; then
    echo "  ⚠ unsupported login shell '${SHELL##*/}' — source $wrapper manually"
    return
  fi

  for profile in "${profiles[@]}"; do
    result="$(write_profile_block "$profile" "$wrapper" "$start" "$end")"
    echo "  ✓ $profile ($label: $result)"
  done
}

# Create ~/.pi-setup.env from the tracked template, owner-readable only.
# The live secret file stays outside the repo so it can never be committed.
install_env_file() {
  local env_file="${PI_SETUP_ENV_FILE:-$HOME/.pi-setup.env}"
  if [ -e "$env_file" ]; then
    chmod 600 "$env_file" 2>/dev/null || true
    echo "  ✓ $env_file (already present, left untouched)"
  else
    cp "$REPO/.env.example" "$env_file"
    chmod 600 "$env_file" 2>/dev/null || true
    echo "  + $env_file created from .env.example — add your provider keys"
  fi
}

# Warn about providers settings.json routes to that have no credential here.
# An unregistered provider makes every subagent launch print
# "[pi-subagents] Skipping fallback model ... unavailable in this environment".
check_provider_credentials() {
  # shellcheck source=scripts/pi-env.sh
  . "$REPO/scripts/pi-env.sh"
  "$PYTHON" - "$REPO/settings.json" <<'PY'
import json
import os
import sys

# provider id -> environment variable documented in Pi's docs/providers.md
ENV_BY_PROVIDER = {
    "zai": "ZAI_API_KEY",
    "zai-coding-cn": "ZAI_CODING_CN_API_KEY",
    "google": "GEMINI_API_KEY",
    "openai": "OPENAI_API_KEY",
    "xai": "XAI_API_KEY",
    "openrouter": "OPENROUTER_API_KEY",
    "deepseek": "DEEPSEEK_API_KEY",
    "groq": "GROQ_API_KEY",
    "mistral": "MISTRAL_API_KEY",
    "kimi-coding": "KIMI_API_KEY",
}
# These authenticate through `pi auth` (auth.json), not an env var.
OAUTH_PROVIDERS = {"anthropic", "openai-codex", "amazon-bedrock"}

settings = json.load(open(sys.argv[1], encoding="utf-8"))
referenced = set()
for override in settings.get("subagents", {}).get("agentOverrides", {}).values():
    models = [override.get("model")] + list(override.get("fallbackModels", []))
    for model in models:
        if isinstance(model, str) and "/" in model:
            referenced.add(model.split("/", 1)[0])

# scripts/pi-env.sh exports this for providers with no key. It silences the
# per-launch warning but is not a credential, so report it as missing.
PLACEHOLDER = "unset-placeholder"


def credential(provider):
    value = os.environ.get(ENV_BY_PROVIDER[provider], "")
    return "" if value == PLACEHOLDER else value


missing = sorted(
    provider
    for provider in referenced - OAUTH_PROVIDERS
    if provider in ENV_BY_PROVIDER and not credential(provider)
)
for provider in missing:
    print(f"  \u2139 provider '{provider}' is routed in settings.json but "
          f"{ENV_BY_PROVIDER[provider]} is unset.")
    print("    That is fine: those roles fall through to the next model in "
          "their fallback chain, and the startup warning stays suppressed.")
    print(f"    To actually use it, add {ENV_BY_PROVIDER[provider]} to "
          f"{os.environ.get('PI_SETUP_ENV_FILE') or '~/.pi-setup.env'}.")
unknown = sorted(referenced - OAUTH_PROVIDERS - set(ENV_BY_PROVIDER))
for provider in unknown:
    print(f"  \u26a0 provider '{provider}' is routed in settings.json but this "
          "installer does not know its credential variable — verify manually.")
if not missing and not unknown:
    print("  \u2713 every provider routed in settings.json has a credential")
PY
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

echo "==> Creating machine-local secret file"
install_env_file

echo "==> Installing shell profile wrappers"
install_profile_wrapper "$REPO/scripts/pi-node-heap.sh" \
  "# >>> pi-setup Pi-only Node heap >>>" \
  "# <<< pi-setup Pi-only Node heap <<<" \
  "Node heap"
install_profile_wrapper "$REPO/scripts/pi-env.sh" \
  "# >>> pi-setup provider env >>>" \
  "# <<< pi-setup provider env <<<" \
  "provider env"
# shellcheck source=scripts/pi-node-heap.sh
. "$REPO/scripts/pi-node-heap.sh"

echo "==> Checking provider credentials"
check_provider_credentials

echo "==> Installing pi packages (list comes from settings.json)"
PACKAGES="$("$PYTHON" -c "import json,sys;print('\n'.join(json.load(sys.stdin)['packages']))" < "$REPO/settings.json")"
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
echo "  1. pi auth        # OAuth providers (anthropic, openai-codex, amazon-bedrock)"
echo "  2. add API-key providers to ~/.pi-setup.env  # e.g. ZAI_API_KEY=..."
echo "  3. restart your shell, then restart pi"
echo "  4. optional: verify browser tooling — npx pi-agent-browser-doctor"
