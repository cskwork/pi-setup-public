#!/usr/bin/env bash
# Fail when public tracked files point users at the private setup repository.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

private_repo='https://github\.com/cskwork/pi-'
private_repo+='setup([^[:alnum:]_-]|$)'
private_checkout='~/pi-'
private_checkout+='setup([^[:alnum:]_-]|$)'
pattern="$private_repo|$private_checkout"

matches=$(git grep -nE "$pattern" -- . || true)
if [ -n "$matches" ]; then
  printf 'Private pi-setup references found; use pi-setup-public:\n%s\n' "$matches" >&2
  exit 1
fi

printf '✓ public setup links use pi-setup-public\n'
