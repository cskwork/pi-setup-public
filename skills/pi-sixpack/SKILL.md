---
name: pi-sixpack
description: |
  SwarmForge-style six-role gated coding pipeline run with pi subagents:
  specifier → coder → cleaner → sw-architect ∥ hardender → qa, with adaptive
  packs (2/4/6) and separate greenfield and brownfield entries. Use when the
  user asks for the six-pack, a pack run, swarm-style or SwarmForge-style
  development, or gated multi-role coding for a greenfield build or a
  brownfield change (feature, fix, refactor) in an existing repo.
---

# Pi Six-Pack

A pi-native port of the SwarmForge Six-Pack. Six role agents (installed as
user agents: `specifier`, `coder`, `cleaner`, `sw-architect`, `hardender`,
`qa`) run as a gated pipeline through `workflowScript`. The parent session is
the orchestrator and final decision-maker at every gate.

No tmux, no per-role worktrees, no commit handoffs — pi children run headless
and the pipeline is serial where it writes. One checkout, one writer at a
time, read-only gates in parallel. Roles hand off through managed output
artifacts, not git commits.

**Run directory.** Every artifact of one run lands in `.sixpack/<run-id>/`,
where `<run-id>` is `YYYYMMDD-HHMM-<slug>` (e.g. `20260824-2140-tenant-filter`).
The leading dot keeps it out of listings and globs; the run id keeps two runs
on one checkout from overwriting each other. Files are numbered in pipeline
order so `ls` reads as the timeline:

```
.sixpack/20260824-2140-tenant-filter/
  00-baseline.md      parent: verify command + unmodified-tree result
  10-spec.md          specifier
  20-coder.md         coder
  25-cleaner.md       cleaner            (pack 6)
  30-arch.md          sw-architect
  31-harden.md        hardender          (pack 6)
  40-fix-1.md         fix coder, round 1 (pack 6)
  41-recheck-1.md     targeted re-check, round 1
  50-qa.md            qa
  99-report.md        parent: final synthesis
```

Gaps in the numbering are deliberate — a wave can gain a step without
renumbering the ones after it. Parallel gates in one wave share a tens digit
(`30`/`31`), so ordering never implies a dependency that does not exist.

**Ignore it before wave 1.** `.sixpack/` is scratch, and it must never reach a
commit or a reviewer's diff. Prefer the local-only path so the user's repo is
not modified:

```bash
git rev-parse --git-dir >/dev/null 2>&1 &&
  grep -qxF '.sixpack/' "$(git rev-parse --git-dir)/info/exclude" 2>/dev/null ||
  echo '.sixpack/' >> "$(git rev-parse --git-dir)/info/exclude"
```

Use `.gitignore` instead only when the user wants the rule shared with the
team — that is a tracked-file change, so ask first. Non-git greenfield: skip.

## Step 1 — Classify and choose the pack

Classify the task first:

- **Greenfield** — no existing tracked code at the target; building from a
  brief or empty/new directory. Skip baselines; specifier works from the brief.
- **Brownfield** — existing repo with tracked code. Requires: clean-enough git
  state, a known verify command, and a captured baseline before the coder runs.

Then recommend one pack with a one-sentence reason and ask the user to choose:

| Pack | Pipeline | Use when |
|------|----------|----------|
| 2 | coder → qa | localized, clear, low-risk task in one subsystem |
| 4 | specifier → coder → sw-architect → qa | moderate cross-layer work; specification and architectural review add value |
| 6 | specifier → coder → cleaner → sw-architect ∥ hardender → fix loop → qa | major, security-sensitive, migration, public-API, or high-regression-risk work |

Default to pack 2 only when the user explicitly delegates the choice, gives
no preference, or input is unavailable — and say so. Do not treat silence as
consent.

## Step 2 — Orient and capture the baseline (brownfield)

Before launching anything, the parent itself:

1. Picks the **run id** (`YYYYMMDD-HHMM-<slug>`), creates `.sixpack/<run-id>/`,
   and adds `.sixpack/` to `.git/info/exclude` if it is not already ignored.
   Every wave script below opens with `const RUN = ".sixpack/<run-id>";`.
2. Reads the target seams the task touches and derives the **verify command**
   (test suite / build / typecheck — the repo's real harness).
3. Runs it once on the unmodified tree and writes the **baseline result**
   (command, exit code, passes, failures, skips) to `<RUN>/00-baseline.md`.
   Wave 2 and wave 5 both cite this file rather than a pasted blob.
4. Greenfield: pick the target directory and intended stack with the user if
   not already fixed; no baseline exists — the scaffold becomes it. Still
   write `00-baseline.md` recording that there was none, and why.

## Step 3 — Run the waves

Launch each wave as its own async `workflowScript` (stable keys, managed
relative outputs). Read each wave's results before launching the next — the
parent synthesizes between waves; a single mega-script cannot pause for
judgment. Fill each task text as a role-specific contract: goal, target +
seams, authority, context/evidence (spec path, baseline, verify command),
success criteria, validation, output, stop rules. `context: "fresh"` for every
role — each agent file carries its own role contract.

**Wave 1 — Specify** (pack 4/6). Brownfield includes recon in the specifier's
own read-only pass; greenfield works from the brief.

```typescript
subagent({
  async: true,
  workflowScript: `
    const RUN = ".sixpack/<run-id>";
    return runs.run("spec", {
      agent: "specifier",
      context: "fresh",
      output: RUN + "/10-spec.md",
      outputMode: "file-only",
      task: "<BROWNFIELD: describe AS-IS/TO-BE from repo evidence; GREENFIELD: paste the brief. Name the target repo/cwd, the seams, the verify command, and any known constraints. Read-only; write only your output file.>"
    });
  `
})
```

Gate: read the spec. Any "Open decisions" that are product/scope calls go to
the user before coding. Acceptance oracle missing or vague → resume the
specifier, do not proceed.

**Wave 2 — Build** (all packs). Coder alone (pack 2/4), or coder then cleaner
(pack 6). The coder is the sole writer of the active worktree.

```typescript
subagent({
  async: true,
  workflowScript: `
    const RUN = ".sixpack/<run-id>";
    const build = await runs.run("coder", {
      agent: "coder",
      context: "fresh",
      output: RUN + "/20-coder.md",
      outputMode: "file-only",
      task: "<Implement the accepted spec at " + RUN + "/10-spec.md. Target/seams, baseline result, verify command, authority boundaries, and stop rules go here.>"
    });
    const clean = await runs.run("cleaner", {          // pack 6 only
      agent: "cleaner",
      context: "fresh",
      output: RUN + "/25-cleaner.md",
      outputMode: "file-only",
      task: "Behavior-preserving cleanup of the coder's diff. Start from the coder handoff: " + build.output + ". Baseline must stay green: <verify command>."
    });
    return { build: build.output, clean: clean.output };
  `
})
```

Gate: read the handoff. Result `blocked` or `partial` with a blocking cause →
fix or re-scope before gates. Parent personally reviews the diff.

**Wave 3 — Review gates** (pack 4: architect only; pack 6: both in parallel).
Read-only, fresh context, distinct angles.

```typescript
subagent({
  async: true,
  context: "fresh",
  workflowScript: `
    const RUN = ".sixpack/<run-id>";
    return await runs.all([
      { key: "arch", agent: "sw-architect", output: RUN + "/30-arch.md", outputMode: "file-only",
        task: "Review invariants, boundaries, dependency direction, data-shape flow of the current diff: <changed files / diff summary>. Read-only." },
      { key: "harden", agent: "hardender", output: RUN + "/31-harden.md", outputMode: "file-only",   // pack 6 only
        task: "Derive adversarial checks from the changed risk in: <changed files>. Run them. No source edits. Baseline: <verify command>." }
    ]);
  `
})
```

**Wave 4 — Fix loop** (only when gates return BLOCK or P1 findings worth
doing now). Round `n` writes two artifacts, so the loop is reconstructable
from disk instead of living only in the parent's head.

The parent first writes its triage decision into the fix coder's task: which
findings are accepted, which are declined, and why. Declined findings are a
record, not an omission.

```typescript
subagent({
  async: true,
  workflowScript: `
    const RUN = ".sixpack/<run-id>";
    const fix = await runs.run("fix", {
      agent: "coder",
      context: "fresh",
      output: RUN + "/40-fix-1.md",
      outputMode: "file-only",
      task: "Apply ONLY these accepted findings: <verbatim finding text + file:line for each>. Declined, do not touch: <finding + one-line reason>. Baseline must stay green: <verify command>. No scope beyond the named findings."
    });
    const recheck = await runs.run("recheck", {
      agent: "hardender",                              // or sw-architect — whichever raised them
      context: "fresh",
      output: RUN + "/41-recheck-1.md",
      outputMode: "file-only",
      task: "Two questions only. (1) Is each named finding resolved: <finding list>? (2) Any new defect inside the fix blast radius: " + fix.output + ". Read-only. Do not re-review unrelated code."
    });
    return { fix: fix.output, recheck: recheck.output };
  `
})
```

Max 3 rounds by default; round 2 uses `42-fix-2.md` / `43-recheck-2.md`.
Unapproved product/scope changes surfaced by reviewers go to the user, not
the fix coder.

**Wave 5 — QA** (all packs). Final independent verification.

Visual-surface rule: when the deliverable has a UI, QA must capture real
screenshots (browser-qa / agent-browser) and read them as evidence — never
claim visual verification from DOM text alone. Vision wiring: every zai
model is text-only in the registry; the `npm:glm-vision` extension gives any
zai-model child image understanding automatically via ambient package
discovery. Do NOT add an `extensions` override to the qa agent or the glm
profile,
because any explicit extensions list disables ambient loading and silently
strips glm-vision (plus model-provider extensions). anthropic/openai-codex
models are natively multimodal and need nothing.

```typescript
subagent({
  async: true,
  workflowScript: `
    const RUN = ".sixpack/<run-id>";
    return runs.run("qa", {
      agent: "qa",
      context: "fresh",
      output: RUN + "/50-qa.md",
      outputMode: "file-only",
      task: "Independently verify through the real public surface. Acceptance oracle: " + RUN + "/10-spec.md. Baseline: " + RUN + "/00-baseline.md. Verify command: <cmd>. Coder handoff: <reference>. Read-only on source."
    });
  `
})
```

## Step 4 — Report

The parent reports, in order: context · what changed (behavior, not file
names) · what stayed untouched · status — verified vs unverified, separating
passes, regressions, pre-existing failures, skipped checks, and environment
limits · the QA verdict line (`integration: verified` / `not verified`) · the
one open question that changes the next decision, if any.

Write the same report to `<RUN>/99-report.md` and end it with the run
manifest — every artifact produced, each gate's verdict, and the model each
gate actually ran on. That file plus the numbered artifacts beside it are the
full record of the run; the chat transcript is not.

## Step 5 — Commit the code and the report together

`.sixpack/` is ignored scratch and disappears. The report is the one artifact
worth keeping, so it lands on a **tracked** path:

```
docs/changes/<run-id>.md
```

**One commit.** The report ships with the code it describes. They are the same
change, so they stay atomic — a reviewer reading the diff gets the plain-language
explanation in the same place, and a revert takes both.

```bash
mkdir -p docs/changes
cp .sixpack/<run-id>/99-report.md docs/changes/<run-id>.md

git add <the files the coder actually changed> docs/changes/<run-id>.md
git status                                # confirm staged set — no strays
git commit -m "<type>: <what changed, in plain words>"
git push
```

Stage named paths only. Never `git add -A` or `git add .` — a sixpack run
leaves scratch and stray files, and the staged set must be exactly the
coder's diff plus the report.

Show the user the staged file list and the commit message before committing.
Stop and ask before pushing if the branch is shared, protected, or unclear.
Skip the whole step in a non-git directory.

### Write it in plain language

Someone who did not follow the run must understand it. That includes a
teammate six months later and a non-engineer.

- One idea per sentence. Short sentences. Active voice.
- Describe **behavior**, not file names. "Users of one tenant can no longer
  read another tenant's invoices" — not "patched `InvoiceRepo.findAll`".
- Gloss any term the reader may not share, once, on first use.
- No pipeline vocabulary. "Gate", "pack 6", "hardender", and "P1 finding" are
  our words, not the reader's. The manifest section may name them; the
  summary may not.
- Say plainly what is **not** done: what stayed unverified, what was declined,
  what a human must still check.
- No praise, no adjectives about the work's quality. Facts only.

Commit subject: the type of the **code** change, not `docs:` — the report is
a passenger, not the point. Plain words, imperative, under ~70 characters.
Good — `fix: stop one tenant from reading another tenant's invoices`.
Bad — `docs: add 99-report.md for run 20260824-2140`.

Commit body: three or four plain sentences on what changed and what was
verified, then `Report: docs/changes/<run-id>.md`.

The committed report keeps the same section order as the chat report, then
the manifest last.

## Model profiles (per-gate model routing)

Four loadable profiles live in `profiles/pi-subagents/` and are switched
with `/subagents-load-profile <name>` (or `subagent({ action: "load-profile" })`
if exposed). Loading replaces `settings.subagents` wholesale:

| Profile | Routing |
|---|---|
| `codex-only` | all gates on `openai-codex` — sol (high) for spec/coder/arch/harden, luna (xhigh, `fast: true`) for cleaner and QA |
| `claude-only` | all gates on `anthropic` — opus-5 (high) for coder/arch/harden, sonnet-5 (medium) spec/QA, haiku-4-5 (low) cleaner |
| `mix` | coder + architect + hardender = codex sol (high), specifier = sonnet-5, cleaner = codex luna (xhigh, `fast: true`), QA = glm-5.3 |
| `glm-max` | all gates on `zai/glm-5.3`, thinking max; QA gets vision via the ambient `glm-vision` extension (no vision model exists to pin — see Wave 5) |

Reviewers deliberately never share the coder's provider in `mix` —
cross-provider review catches what a same-family model misses. When the
active profile routes a gate to `openai-codex/*`, pass `fast: true` on that
wave's launch item for the priority tier; the flag is a no-op on other
providers.

## Constraints

- One writer per checkout at all times; never launch two write-capable roles
  concurrently. Parallel lanes are read-only (architect ∥ hardender, re-checks).
- Children never run subagents and never decide loop outcomes or scope — the
  parent synthesizes every wave.
- All scratch outputs stay under one run directory (`.sixpack/<run-id>/...`);
  nothing lands in the repo root. Add `.sixpack/` to `.git/info/exclude`
  before wave 1. The report is the only artifact copied to a tracked path.
- The commit contains the coder's diff plus `docs/changes/<run-id>.md`, staged
  by name. Never `git add -A` or `git add .` — a run leaves scratch that must
  not be swept in. Show the staged list and message to the user before
  committing; pushing a shared or protected branch needs explicit approval.
- Every wave that changes the tree or a verdict leaves a numbered artifact —
  including each fix round. A run must be reconstructable from disk alone.
- Brownfield requires the baseline before wave 2. Never present a QA pass
  without the baseline diff.
- Greenfield in a non-git directory: git is optional (no worktree handoffs),
  but the coder must leave a runnable scaffold the verify command can execute.
- Preserve user-owned decisions: pack choice, spec open decisions, unapproved
  scope changes, and merge/publish boundaries all go to the user.
