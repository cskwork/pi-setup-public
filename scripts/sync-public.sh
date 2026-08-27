#!/usr/bin/env bash
# One-way publish: private pi-setup -> public pi-setup-public.
#
# Stages only. It never commits and never pushes: a mistake here is public and
# permanent, so a human reviews `git diff --cached` and pushes by hand.
#
# The core invariant is DOMAIN CONTENT NEVER GOES PUBLIC, enforced structurally
# rather than by filtering:
#   - the file set comes from `git ls-files`, so every gitignored path (all
#     work-IP skills, every .env, the db-intelligence domain pack) is
#     unreachable by construction - it is never a candidate to begin with;
#   - `.sync-public` then removes private-but-tracked files (memory);
#   - a domain-identifier assertion runs over the resulting file set and the
#     staged diff, and aborts on any hit;
#   - unclassified-but-suspicious paths abort rather than defaulting to sync.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBLIC="${PI_SETUP_PUBLIC:-$HOME/pi-setup-public}"
POLICY="$REPO/.sync-public"

die() {
  printf '\n⛔ %s\n' "$*" >&2
  exit 1
}
note() { printf '   %s\n' "$*"; }

# Identifiers that must never appear in the public repo.
#
# The list itself is sensitive - publishing it would disclose the very
# employer/project names it exists to hide - so it lives in a gitignored
# sidecar, never in this (publishable) script. One regex per line; blank
# lines and # comments ignored. The optional second file allowlists terms
# that legitimately appear in public (e.g. a public repo whose name
# contains a domain word).
KEYWORDS="${PI_SYNC_KEYWORDS:-$REPO/.sync-keywords}"
ALLOWLIST="${PI_SYNC_ALLOWLIST:-$REPO/.sync-allowlist}"

[ -f "$KEYWORDS" ] || die "missing keyword file: $KEYWORDS
   Create it (gitignored) with one identifier regex per line, e.g.
     my-employer
     internal-project
   Refusing to publish without a configured leak filter."

read_list() { sed 's/#.*//' "$1" 2>/dev/null | grep -v '^[[:space:]]*$' | paste -sd'|' -; }
DOMAIN_RE=$(read_list "$KEYWORDS")
[ -n "$DOMAIN_RE" ] || die "$KEYWORDS is empty; refusing to publish with no leak filter."
ALLOW_RE=$(read_list "$ALLOWLIST")
ALLOW_RE=${ALLOW_RE:-$'\0no-allowlist-sentinel'}

[ -f "$POLICY" ] || die "missing policy file: $POLICY"
[ -d "$PUBLIC/.git" ] || die "public checkout not found at $PUBLIC
   clone it first:  git clone https://github.com/cskwork/pi-setup-public.git $PUBLIC
   or set PI_SETUP_PUBLIC to its path."

cd "$REPO"
[ -z "$(git status --porcelain)" ] || die "private repo has uncommitted changes.
   Commit them first so the published state matches a real commit."

# ---------- read policy ----------
never=()
keep=()
publiconly=()
while read -r policy glob; do
  case "${policy:-}" in
  '' | '#'*) continue ;;
  never) never+=("$glob") ;;
  keep-public) keep+=("$glob") ;;
  public-only) publiconly+=("$glob") ;;
  *) die "unknown policy '$policy' in $POLICY" ;;
  esac
done < <(sed 's/#.*//' "$POLICY" | grep -v '^[[:space:]]*$')

# Match a path against policy globs.
#
# Only two forms are honoured, both anchored at the repo root:
#   dir/**      prefix match on 'dir/'
#   exact/path  byte-for-byte equality
#
# Equality is deliberate rather than `[[ $path == $g ]]`: an unquoted RHS is
# treated as a GLOB, so a rule like configs/com.cskwork.pi-memory-sync.plist
# matched configs/permissions.json ('.' is not special and '*' crosses '/').
# That silently classified a to-be-published file as 'never' and pruned it
# from the public repo. Literal comparison cannot misfire that way.
matches() { # matches <path> <glob...>
  local path=$1
  shift
  local g prefix
  for g in "$@"; do
    # Detect the '/**' SUFFIX by string surgery, never by `case $g in */**)`.
    # In bash, the pattern `*/**` collapses to `*/*` and therefore matches any
    # path containing a slash - so a plain rule like
    # configs/com.cskwork.pi-memory-sync.plist was read as a directory rule,
    # stripped to the prefix 'configs/', and silently swallowed
    # configs/permissions.json, pruning it from the public repo.
    if [ "${g%/\*\*}" != "$g" ]; then
      prefix="${g%/\*\*}/"
      case $path in
      "$prefix"*) return 0 ;;
      esac
    elif [ "$path" = "$g" ]; then
      return 0
    fi
  done
  return 1
}

echo "==> Classifying tracked files"
sync_files=()
skipped_never=()
skipped_keep=()
while IFS= read -r f; do
  if matches "$f" "${never[@]}"; then
    skipped_never+=("$f")
    continue
  fi
  if matches "$f" "${keep[@]}"; then
    skipped_keep+=("$f")
    continue
  fi
  sync_files+=("$f")
done < <(git ls-files)

note "sync:        ${#sync_files[@]} files"
note "never:       ${#skipped_never[@]} files (private only)"
note "keep-public: ${#skipped_keep[@]} files (public version wins)"

# ---------- assertion 1: no domain identifiers in what we are about to copy ----------
echo "==> Asserting no domain content in the sync set"
leaks=""
for f in "${sync_files[@]}"; do
  if grep -lIiE "$DOMAIN_RE" "$REPO/$f" 2>/dev/null | grep -q .; then
    # A file qualifies only if a matching line survives the allowlist.
    if grep -hIiE "$DOMAIN_RE" "$REPO/$f" 2>/dev/null | grep -ivq "$ALLOW_RE"; then
      leaks+="   $f"$'\n'
      leaks+="$(grep -hnIiE "$DOMAIN_RE" "$REPO/$f" | grep -iv "$ALLOW_RE" | head -3 | sed 's/^/       /')"$'\n'
    fi
  fi
done
[ -z "$leaks" ] || die "domain identifiers found in files staged for PUBLIC:
$leaks
   Move the content to a gitignored domain pack, or add a 'never' rule
   in .sync-public. Nothing was copied."
note "clean"

# ---------- copy ----------
echo "==> Copying into $PUBLIC"
for f in "${sync_files[@]}"; do
  mkdir -p "$PUBLIC/$(dirname "$f")"
  cp "$REPO/$f" "$PUBLIC/$f"
done

# Delete public files that are no longer tracked privately, except the ones
# public owns or keeps. Without this, a file renamed privately lingers publicly.
echo "==> Pruning public files that no longer exist privately"
pruned=0
while IFS= read -r f; do
  matches "$f" "${publiconly[@]}" && continue
  matches "$f" "${keep[@]}" && continue
  if ! printf '%s\n' "${sync_files[@]}" | grep -qxF "$f"; then
    note "prune $f"
    rm -- "$PUBLIC/$f"
    pruned=$((pruned + 1))
  fi
done < <(cd "$PUBLIC" && git ls-files)
note "$pruned pruned"

# ---------- stage + assertion 2: the staged diff itself ----------
cd "$PUBLIC"
git add -A

if git diff --cached --quiet; then
  echo
  echo "Already in sync ✅  nothing staged."
  exit 0
fi

echo "==> Asserting no domain content in the staged diff"
staged_leaks=$(git diff --cached | grep -E '^\+[^+]' | grep -iv "$ALLOW_RE" |
  grep -inE "$DOMAIN_RE" || true)
if [ -n "$staged_leaks" ]; then
  git reset --quiet
  die "domain identifiers in staged additions (unstaged, nothing committed):
$(echo "$staged_leaks" | head -10)"
fi
note "clean"

# ---------- report ----------
echo
echo "==> Staged in $PUBLIC"
git diff --cached --stat | tail -20
cat <<EOF

Review, then publish by hand:

  cd $PUBLIC
  git diff --cached
  git commit -m "sync: <what changed>"
  git push

Nothing has been committed or pushed. ✅
EOF
