#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORIGINAL_PATH="$PATH"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_contains() { case "$1" in *"$2"*) ;; *) fail "expected '$2' in '$1'" ;; esac; }
assert_eq() { [ "$1" = "$2" ] || fail "expected '$2', got '$1'"; }

make_fake_pi() {
  local directory="$1" label="$2"
  mkdir -p "$directory"
  cat > "$directory/pi" <<EOF
#!/usr/bin/env bash
printf 'label=%s\n' '$label'
printf 'node_options=%s\n' "\${NODE_OPTIONS-}"
printf 'args='
printf '<%s>' "\$@"
printf '\n'
exit "\${PI_FAKE_EXIT:-0}"
EOF
  chmod +x "$directory/pi"
}

make_fake_pi "$TMP/a" A
make_fake_pi "$TMP/b" B
# shellcheck source=../scripts/pi-node-heap.sh
. "$ROOT/scripts/pi-node-heap.sh"

export NODE_OPTIONS="--trace-warnings"
PATH="$TMP/a:$ORIGINAL_PATH"
output="$(pi "two words" --flag)"
assert_contains "$output" "label=A"
assert_contains "$output" "node_options=--trace-warnings --max-old-space-size=8192"
assert_contains "$output" "args=<two words><--flag>"
assert_eq "$NODE_OPTIONS" "--trace-warnings"

PATH="$TMP/b:$ORIGINAL_PATH"
output="$(pi switch)"
assert_contains "$output" "label=B"

set +e
PI_FAKE_EXIT=37 pi failure >/dev/null 2>&1
status=$?
set -e
assert_eq "$status" "37"
unset PI_FAKE_EXIT

mkdir -p "$TMP/node-probe"
cat > "$TMP/node-probe/pi" <<'EOF'
#!/usr/bin/env bash
exec node -e 'const v8=require("v8");console.log(Math.round(v8.getHeapStatistics().heap_size_limit/1048576))'
EOF
chmod +x "$TMP/node-probe/pi"
PATH="$TMP/node-probe:$ORIGINAL_PATH"
export NODE_OPTIONS="--max-old-space-size=128"
heap_limit="$(pi)"
[ "$heap_limit" -ge 8000 ] || fail "Pi heap limit stayed below 8 GiB: $heap_limit MiB"
assert_eq "$NODE_OPTIONS" "--max-old-space-size=128"

fake_tools="$TMP/tools"
mkdir -p "$fake_tools" "$TMP/home/dotfiles"
profile_symlink=0
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    login_shell=/bin/bash
    profile="$TMP/home/.bashrc"
    expected_wrapper="$(cygpath -m "$ROOT/scripts/pi-node-heap.sh")"
    printf '# existing profile\n' > "$profile"
    ;;
  *)
    login_shell=/bin/zsh
    profile="$TMP/home/.zshrc"
    expected_wrapper="$ROOT/scripts/pi-node-heap.sh"
    printf '# existing profile\n' > "$TMP/home/dotfiles/zshrc"
    if ln -s "dotfiles/zshrc" "$profile" 2>/dev/null && [ -L "$profile" ]; then
      profile_symlink=1
    else
      rm -f "$profile"
      cp "$TMP/home/dotfiles/zshrc" "$profile"
    fi
    ;;
esac
cat > "$fake_tools/pi" <<'EOF'
#!/usr/bin/env bash
printf '%s|%s\n' "${NODE_OPTIONS-}" "$*" >> "$PI_FAKE_LOG"
EOF
cat > "$fake_tools/agent-browser" <<'EOF'
#!/usr/bin/env bash
[ "${1-}" = "--version" ] && echo "test"
EOF
cat > "$fake_tools/superqa" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "$fake_tools/npm" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$fake_tools"/*

export PI_FAKE_LOG="$TMP/pi.log"
for run in 1 2; do
  HOME="$TMP/home" \
  PI_DIR="$TMP/home/.pi/agent" \
  SHELL="$login_shell" \
  NODE_OPTIONS="--trace-warnings" \
  PATH="$fake_tools:$ORIGINAL_PATH" \
    bash "$ROOT/install.sh" >/dev/null

done
if [ "$profile_symlink" -eq 1 ]; then
  [ -L "$profile" ] || fail "installer replaced the profile symlink"
fi
assert_eq "$(grep -c '^# >>> pi-setup Pi-only Node heap >>>$' "$profile")" "1"
assert_eq "$(grep -c '^# <<< pi-setup Pi-only Node heap <<<$' "$profile")" "1"
assert_contains "$(cat "$profile")" "$expected_wrapper"
[ "$(grep -c -- '--max-old-space-size=8192' "$PI_FAKE_LOG")" -gt 0 ] ||
  fail "installer did not run Pi with the 8 GiB wrapper"

printf 'PASS: Pi-only shell heap wrapper and installer profile block\n'
