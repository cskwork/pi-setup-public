---
name: sync-agent-prompt
description: Sync agreed operating-contract and skill changes across pi-setup, its public subset, and onboarding copies, preserving private-only content and existing authorization.
---

# sync-agent-prompt

Keep every copy of the agent operating contract and the essential skills
consistent within their intended scope. Show the per-file direction and preserve private/public differences. Reuse approval already given for that exact change; publication or a newly exposed private path needs its own authorization.

## Topology (verified 2026-08-29; re-verify paths that fail)

(`<private>` is the private pi-setup mirror checkout; this public copy never
names its path.)

**Operating contract — four copies, one content:**

| copy | path | role |
|---|---|---|
| live | `~/.agents/AGENTS.md` | what local agents load; `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` symlink to it |
| private | `<private>/AGENTS.md` | canonical edit point, repo `cskwork/pi-setup` |
| public | `~/pi-setup-public/AGENTS.md` | repo `cskwork/pi-setup-public` — **the default install source**: fresh machines clone this and symlink their CLAUDE.md/AGENTS.md to it |
| mirror | `agents/AGENTS.md` in `cskwork/prime-agent-sync` | no local checkout — read/write via `gh api repos/cskwork/prime-agent-sync/contents/agents/AGENTS.md` |

**Essential skills:** `<private>/skills/*` → `~/pi-setup-public/skills/*`.
The public set is a subset; paths only in private are work-IP and must NEVER
go public. Two skills have external canonicals:

- `sdlc-kit` ← `~/Documents/Git/sdlc-kit` (repo `cskwork/sdlc-kit`). Mirror
  the shared subset with rsync, excluding
  `.git .gitignore .gitattributes LICENSE README.md docs .pi .verify .impeccable`.
- `verify` ← repo `cskwork/verify-skill` (no local checkout). Drift is
  BIDIRECTIONAL: never wholesale-copy; diff each file and review its relevant history and behavior on both sides. Timestamps alone do not establish which content should win.

**Onboarding:** promptbox (`~/Documents/PARA/Resource/promptbox`, repo
`cskwork/promptbox`). The 정본 is `src/data/pi-setup-prompt.txt`; its step-7
summary of the operating contract must name the ACTUAL steps in AGENTS.md.
The ```` ```text ```` fence in `src/content/prompts/agents-quick-onboarding.md`
is a byte copy of the txt — regenerate it after any txt edit and prove it with
`npm run check:prompt`. Do not edit `src/data/onboarding.ts`; it imports the
txt with `?raw` and holds no body.

## Procedure

1. **Status (read-only).** Run `sync-status.sh` from this directory. It
   compares the four contract copies (local hashes + remote blob SHAs), diffs
   the skill trees, and checks the onboarding fence.
2. **Direction per file.** Compare both contents, relevant history, and the behavior they describe. Timestamps alone do not resolve divergent edits. Preserve private/public adaptations; ask only when evidence leaves a material conflict unresolved.
3. **Ask.** Present one line per file: `path · as-is → to-be · direction ·
   why`. Continue when that scope is already approved; ask only for an unresolved direction, private/public exposure, or publication decision.
4. **Apply.** Copy files; rsync `sdlc-kit` with the exclude list; regenerate
   the onboarding fence (replace the `/```text\n[\s\S]*?\n```/` block with the
   txt content); run `npm run check:prompt` in promptbox. Commit each repo
   with a real message and push only when delivery is authorized. When authorized, update `prime-agent-sync` via
   `gh api -X PUT` with the current blob `sha`.
5. **Verify.** `git hash-object <local>` must equal
   `gh api repos/<repo>/contents/<path> --jq .sha` for every remote copy.
   GitHub code search lags pushes — trust blob SHAs, not search. Report the
   matches, the commits pushed, and anything skipped.

## Public-leg safety

`pi-setup-public` is public and permanent. Prefer
`<private>/scripts/sync-public.sh` (stages only; the human reviews
`git diff --cached` and pushes). It refuses to run without the gitignored
`<private>/.sync-keywords` leak filter; while that file is missing, copy only
individually reviewed framework files, never `git add -A`, and never move a
private-only path into the public tree.

## Gotchas

- `.verify/` and `__pycache__/` are gitignored scratch; they survive
  `git rm` and sneak into the next blanket `git add`.
- Keep shell scripts LF-only; a CRLF copy breaks Git Bash consumers.
- `~/.agents/skills/<name>` entries are per-skill symlinks into
  `<private>/skills/<name>` — a new shared skill needs its symlink created
  once (`ln -sfn <private>/skills/<name> ~/.agents/skills/<name>`).
