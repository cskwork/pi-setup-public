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

1. Reads the target seams the task touches and derives the **verify command**
   (test suite / build / typecheck — the repo's real harness).
2. Runs it once on the unmodified tree and records the **baseline result**
   (passes, failures, skips). This feeds the coder and QA tasks.
3. Greenfield: pick the target directory and intended stack with the user if
   not already fixed; no baseline exists — the scaffold becomes it.

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
    return runs.run("spec", {
      agent: "specifier",
      context: "fresh",
      output: "sixpack/spec.md",
      outputMode: "file-only",
      task: "<BROWNFIELD: describe AS-IS/TO-BE from repo evidence; GREENFIELD: paste the brief. Name the target repo/cwd, the seams, the verify command, and any known constraints. Read-only; write only sixpack/spec.md.>"
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
    const build = await runs.run("coder", {
      agent: "coder",
      context: "fresh",
      output: "sixpack/coder.md",
      outputMode: "file-only",
      task: "<Implement the accepted spec at sixpack/spec.md. Target/seams, baseline result, verify command, authority boundaries, and stop rules go here.>"
    });
    const clean = await runs.run("cleaner", {          // pack 6 only
      agent: "cleaner",
      context: "fresh",
      output: "sixpack/cleaner.md",
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
    return await runs.all([
      { key: "arch", agent: "sw-architect", output: "sixpack/arch.md", outputMode: "file-only",
        task: "Review invariants, boundaries, dependency direction, data-shape flow of the current diff: <changed files / diff summary>. Read-only." },
      { key: "harden", agent: "hardender", output: "sixpack/harden.md", outputMode: "file-only",   // pack 6 only
        task: "Derive adversarial checks from the changed risk in: <changed files>. Run them. No source edits. Baseline: <verify command>." }
    ]);
  `
})
```

**Wave 4 — Fix loop** (only when gates return BLOCK or P1 findings worth
doing now). One fix coder applies the synthesized accepted fixes; then a
focused re-check of only the affected angles (targeted follow-up: "was the
named finding resolved, any new defect in the fix blast radius"). Max 3 review
rounds by default. Unapproved product/scope changes surfaced by reviewers go
to the user, not the fix coder.

**Wave 5 — QA** (all packs). Final independent verification.

```typescript
subagent({
  async: true,
  workflowScript: `
    return runs.run("qa", {
      agent: "qa",
      context: "fresh",
      output: "sixpack/qa.md",
      outputMode: "file-only",
      task: "Independently verify through the real public surface. Acceptance oracle: sixpack/spec.md. Baseline: <paste>. Verify command: <cmd>. Coder handoff: <reference>. Read-only on source."
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

## Constraints

- One writer per checkout at all times; never launch two write-capable roles
  concurrently. Parallel lanes are read-only (architect ∥ hardender, re-checks).
- Children never run subagents and never decide loop outcomes or scope — the
  parent synthesizes every wave.
- All scratch outputs stay under managed relative paths (`sixpack/...`);
  nothing lands in the repo root. Copy only final evidence to durable places.
- Brownfield requires the baseline before wave 2. Never present a QA pass
  without the baseline diff.
- Greenfield in a non-git directory: git is optional (no worktree handoffs),
  but the coder must leave a runnable scaffold the verify command can execute.
- Preserve user-owned decisions: pack choice, spec open decisions, unapproved
  scope changes, and merge/publish boundaries all go to the user.
