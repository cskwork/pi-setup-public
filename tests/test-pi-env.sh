#!/usr/bin/env bash
# Regression test for the provider-credential loader.
#
# The bug this guards: Pi registers a provider only when that provider's
# documented env var is set. When settings.json routes to `zai` but only the
# non-Pi alias Z_AI_API_KEY is exported, `zai` never registers and every
# subagent launch prints
#   [pi-subagents] Skipping fallback model 'zai/glm-5.3-flash' ...
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORIGINAL_PATH="$PATH"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_eq() { [ "$1" = "$2" ] || fail "${3:-value}: expected '$2', got '$1'"; }
assert_contains() { case "$1" in *"$2"*) ;; *) fail "expected '$2' in '$1'" ;; esac; }

# Shells that must be able to source the loader. It is installed into .zshrc on
# macOS and .bashrc on Git Bash, and bash-only syntax such as ${!name} makes
# zsh abort the block with "bad substitution" while setting nothing.
SHELLS=(bash)
command -v zsh >/dev/null 2>&1 && SHELLS+=(zsh)

# Run the loader in a clean subshell with a given env file, echo one variable.
# $CURRENT_SHELL selects the interpreter so every case runs under each shell.
CURRENT_SHELL=bash
probe() { # probe <env-file> <var-to-print> [PRESET=value ...]
  local env_file="$1" var="$2"; shift 2
  env -i HOME="$TMP/home" PATH="$ORIGINAL_PATH" PI_SETUP_ENV_FILE="$env_file" "$@" \
    "$CURRENT_SHELL" -c '. "$1" >/dev/null 2>&1; eval "printf %s \"\${$2-}\""' \
    _ "$ROOT/scripts/pi-env.sh" "$var"
}

# The loader must not emit diagnostics (a shell-incompatible expansion shows up
# here as "bad substitution" even when the resulting value looks plausible).
probe_stderr() { # probe_stderr <env-file>
  env -i HOME="$TMP/home" PATH="$ORIGINAL_PATH" PI_SETUP_ENV_FILE="$1" \
    "$CURRENT_SHELL" -c '. "$1" >/dev/null' _ "$ROOT/scripts/pi-env.sh" 2>&1 >/dev/null
}

mkdir -p "$TMP/home"

cat > "$TMP/plain.env" <<'EOF'
# comment line
ZAI_API_KEY=key-from-file
EOF
printf 'Z_AI_API_KEY=legacy-name\n' > "$TMP/legacy.env"
cat > "$TMP/messy.env" <<'EOF'

  export ZAI_API_KEY="quoted-value"
  GEMINI_API_KEY='single-quoted'
not-an-assignment
BAD NAME=ignored
EOF

for CURRENT_SHELL in "${SHELLS[@]}"; do
  # 0. Sourcing is silent. Catches bash-only syntax that zsh rejects.
  assert_eq "$(probe_stderr "$TMP/plain.env")" "" "$CURRENT_SHELL: silent source"

  # 1. The Pi-facing name is populated from the file.
  assert_eq "$(probe "$TMP/plain.env" ZAI_API_KEY)" "key-from-file" \
    "$CURRENT_SHELL: file value"

  # 2. Alias normalization both ways — Pi reads ZAI_API_KEY, the Z.ai Vision MCP
  #    server reads Z_AI_API_KEY, and one stored secret must satisfy both.
  assert_eq "$(probe "$TMP/legacy.env" ZAI_API_KEY)" "legacy-name" \
    "$CURRENT_SHELL: legacy -> pi name"
  assert_eq "$(probe "$TMP/plain.env" Z_AI_API_KEY)" "key-from-file" \
    "$CURRENT_SHELL: pi name -> legacy"

  # 3. Already-exported environment wins, so `ZAI_API_KEY=x pi ...` still works.
  assert_eq "$(probe "$TMP/plain.env" ZAI_API_KEY ZAI_API_KEY=from-shell)" \
    "from-shell" "$CURRENT_SHELL: exported env precedence"

  # 4. Quoting, `export ` prefix, blank lines and indentation are tolerated.
  assert_eq "$(probe "$TMP/messy.env" ZAI_API_KEY)" "quoted-value" \
    "$CURRENT_SHELL: quoted+export"
  assert_eq "$(probe "$TMP/messy.env" GEMINI_API_KEY)" "single-quoted" \
    "$CURRENT_SHELL: single quotes"

  # 5. With no key anywhere, the loader still exports a placeholder so
  #    pi-subagents does not warn "unavailable in this environment" on every
  #    launch. Any non-empty value registers the provider; the wrong-credential
  #    path is already silent and falls through the chain.
  assert_eq "$(probe "$TMP/does-not-exist.env" ZAI_API_KEY)" "unset-placeholder" \
    "$CURRENT_SHELL: placeholder when no key"

  # 6. PI_SETUP_NO_PLACEHOLDER=1 opts out and leaves the variable unset.
  assert_eq "$(probe "$TMP/does-not-exist.env" ZAI_API_KEY PI_SETUP_NO_PLACEHOLDER=1)" "" \
    "$CURRENT_SHELL: placeholder opt-out"

  # 7. A real key always beats the placeholder, including when a stale
  #    placeholder is already exported (re-sourcing the profile in one shell).
  assert_eq "$(probe "$TMP/plain.env" ZAI_API_KEY ZAI_API_KEY=unset-placeholder)" \
    "key-from-file" "$CURRENT_SHELL: file key beats stale placeholder"
  assert_eq "$(probe "$TMP/does-not-exist.env" ZAI_API_KEY ZAI_API_KEY=real-key)" \
    "real-key" "$CURRENT_SHELL: exported key beats placeholder"

  # 8. The placeholder must not be mirrored onto the alias as if it were a key.
  assert_eq "$(probe "$TMP/legacy.env" ZAI_API_KEY ZAI_API_KEY=unset-placeholder)" \
    "legacy-name" "$CURRENT_SHELL: legacy key beats stale placeholder"
done
CURRENT_SHELL=bash

# 6. Installer: creates ~/.pi-setup.env from the template, mode 600, and never
#    overwrites an existing one.
fake_tools="$TMP/tools"
mkdir -p "$fake_tools" "$TMP/inst-home"
for tool in pi agent-browser superqa npm; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$fake_tools/$tool"
done
printf '#!/usr/bin/env bash\n[ "${1-}" = "--version" ] && echo test\nexit 0\n' \
  > "$fake_tools/agent-browser"
chmod +x "$fake_tools"/*

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) login_shell=/bin/bash; profile="$TMP/inst-home/.bashrc" ;;
  *)                    login_shell=/bin/zsh;  profile="$TMP/inst-home/.zshrc"  ;;
esac
inst_env="$TMP/inst-home/.pi-setup.env"

run_installer() {
  HOME="$TMP/inst-home" \
  PI_DIR="$TMP/inst-home/.pi/agent" \
  PI_SETUP_ENV_FILE="$inst_env" \
  SHELL="$login_shell" \
  PATH="$fake_tools:$ORIGINAL_PATH" \
    bash "$ROOT/install.sh"
}

first_run="$(run_installer)"
[ -f "$inst_env" ] || fail "installer did not create $inst_env"
assert_contains "$first_run" "created from .env.example"

if [ "$(uname -s)" != "MINGW"* ] 2>/dev/null || true; then
  mode="$(ls -l "$inst_env" | cut -c1-10)"
  case "$mode" in
    -rw-------) ;;
    *) echo "WARN: $inst_env mode is $mode, expected -rw------- (filesystem may not support it)" >&2 ;;
  esac
fi

# The installer must not clobber a key the user already pasted in.
printf 'ZAI_API_KEY=user-edited\n' > "$inst_env"
second_run="$(run_installer)"
assert_contains "$second_run" "already present, left untouched"
assert_eq "$(cat "$inst_env")" "ZAI_API_KEY=user-edited" "existing env file preserved"

# 7. Both managed profile blocks land exactly once and survive a re-run.
assert_eq "$(grep -c '^# >>> pi-setup Pi-only Node heap >>>$' "$profile")" "1" "heap block"
assert_eq "$(grep -c '^# >>> pi-setup provider env >>>$' "$profile")" "1" "env block"
assert_eq "$(grep -c '^# <<< pi-setup provider env <<<$' "$profile")" "1" "env end marker"
assert_contains "$(cat "$profile")" "scripts/pi-env.sh"

# 8. The credential check names a routed-but-unauthenticated provider. This is
#    the exact condition that produced the glm-5.3-flash fallback warning.
# Both names must be cleared: the loader mirrors one into the other, so an
# ambient Z_AI_API_KEY would legitimately satisfy the check and mask the case.
warn_run="$(env -u ZAI_API_KEY -u Z_AI_API_KEY \
  HOME="$TMP/inst-home" PI_DIR="$TMP/inst-home/.pi/agent" \
  PI_SETUP_ENV_FILE="$TMP/does-not-exist.env" SHELL="$login_shell" \
  PATH="$fake_tools:$ORIGINAL_PATH" bash "$ROOT/install.sh")"
if grep -q '"zai/' "$ROOT/settings.json"; then
  assert_contains "$warn_run" "provider 'zai' is routed in settings.json"
  assert_contains "$warn_run" "ZAI_API_KEY is unset"
  # A missing key is reported as informational, not as a problem to fix.
  assert_contains "$warn_run" "That is fine"
fi

# 9. The installer must survive a legacy single-byte console. Windows Git Bash
#    runs Python with the cp1252 codepage, where a non-ASCII status glyph raises
#    UnicodeEncodeError and aborts the install. Forcing that encoding here
#    reproduces the Windows-only failure on any machine.
cp1252_run="$(env -u ZAI_API_KEY -u Z_AI_API_KEY PYTHONIOENCODING=cp1252 \
  HOME="$TMP/inst-home" PI_DIR="$TMP/inst-home/.pi/agent" \
  PI_SETUP_ENV_FILE="$TMP/does-not-exist.env" SHELL="$login_shell" \
  PATH="$fake_tools:$ORIGINAL_PATH" bash "$ROOT/install.sh" 2>&1)" \
  || fail "installer aborted under a cp1252 console: $(printf '%s' "$cp1252_run" | tail -3)"
case "$cp1252_run" in
  *UnicodeEncodeError*) fail "installer emitted non-ASCII text a cp1252 console cannot encode" ;;
esac
assert_contains "$cp1252_run" "Checking provider credentials"

printf 'PASS: provider env loader, alias normalization, and installer secret file\n'
