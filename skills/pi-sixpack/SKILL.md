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

Six user agents — `specifier`, `coder`, `cleaner`, `sw-architect`,
`hardender`, `qa` — run as a gated pipeline through `workflowScript`. The
parent session orchestrates and decides at every gate.

No tmux, no per-role worktrees, no commit handoffs. One checkout, one writer
at a time, read-only gates in parallel. Roles hand off through files.

## Step 1 — Classify and choose the pack

- **Greenfield** — no tracked code at the target. No baseline; specifier works
  from the brief.
- **Brownfield** — existing repo. Needs clean-enough git state, a verify
  command, and a baseline before the coder runs.

Recommend one pack with a one-sentence reason, then ask:

| Pack | Pipeline | Use when |
|---|---|---|
| 2 | coder → qa | localized, clear, low-risk, one subsystem |
| 4 | specifier → coder → sw-architect → qa | moderate cross-layer work |
| 6 | specifier → coder → cleaner → sw-architect ∥ hardender → fix loop → qa | major, security-sensitive, migration, public-API, high-regression-risk |

Default to pack 2 only on explicit delegation, and say so. Silence is not
consent.

## Step 2 — Set up the run

The parent, before launching anything:

1. **Run id** — `YYYYMMDD-HHMM-<slug>`. Create `.sixpack/<run-id>/`. Every
   wave script opens with `const RUN = ".sixpack/<run-id>";`.
2. **Ignore scratch** — local-only, so the user's tracked files are untouched:
   ```bash
   grep -qxF '.sixpack/' "$(git rev-parse --git-dir)/info/exclude" 2>/dev/null ||
     echo '.sixpack/' >> "$(git rev-parse --git-dir)/info/exclude"
   ```
   Use `.gitignore` only if the user wants it shared — ask first. Non-git: skip.
3. **Verify command** — read the seams, derive the repo's real harness
   (tests / build / typecheck).
4. **Baseline** — run it on the unmodified tree, write command + exit code +
   passes/failures/skips to `<RUN>/00-baseline.md`. Greenfield still writes
   the file, recording that no baseline existed and why.

### Artifacts

Numbered in pipeline order, so `ls` reads as the timeline:

| File | Written by | Pack |
|---|---|---|
| `00-baseline.md` | parent | all |
| `10-spec.md` | specifier | 4/6 |
| `20-coder.md` | coder | all |
| `25-cleaner.md` | cleaner | 6 |
| `30-arch.md` | sw-architect | 4/6 |
| `31-harden.md` | hardender | 6 |
| `40-fix-n.md` / `41-recheck-n.md` | fix coder / re-check | 6 |
| `50-qa.md` | qa | all |
| `99-report.md` | parent | all |

Gaps are deliberate — a wave can gain a step without renumbering. Parallel
gates share a tens digit (`30`/`31`), so order never implies dependency.

## Step 3 — Run the waves

Each wave is its own async `workflowScript`. **Read the results before
launching the next** — the parent synthesizes between waves; one mega-script
cannot pause for judgment.

Every launch item carries the same envelope, omitted from the waves below
only where shown:

```typescript
{ context: "fresh", outputMode: "file-only", output: RUN + "/<file>" }
```

`context: "fresh"` is not a cost choice — it is why the gates are independent.
An architect that inherited the coder's reasoning would review intent, not
code. Fill each `task` as a role contract: goal · target + seams · authority ·
evidence (spec path, baseline, verify command) · success criteria · output ·
stop rules.

**Bulk rule — every gate.** Screenshots, probe logs, traces, profiler output,
and large command dumps are evidence to read, not artifacts to keep. Write
them under `<RUN>/scratch/`, read them, quote the deciding lines in the gate's
report, then delete the file. The gate's `.md` is the record. Add this to any
task whose gate may produce bulk:

```
Bulk output (logs, traces, captures, screenshots) goes to <RUN>/scratch/,
gets read, gets quoted in your report, then gets deleted. Cite the evidence,
do not carry it.
```

**Wave 1 — Specify** (pack 4/6).

```typescript
subagent({
  async: true,
  workflowScript: `
    const RUN = ".sixpack/<run-id>";
    return runs.run("spec", {
      agent: "specifier", context: "fresh",
      output: RUN + "/10-spec.md", outputMode: "file-only",
      task: "<BROWNFIELD: AS-IS/TO-BE from repo evidence. GREENFIELD: the brief. Name target repo/cwd, seams, verify command, constraints. Read-only; write only your output file.>"
    });
  `
})
```

Gate: read the spec. Product/scope "open decisions" go to the user before
coding. Missing or vague acceptance oracle → resume the specifier.

**Wave 2 — Build** (all packs). Coder is the sole writer; cleaner follows
sequentially in pack 6.

```typescript
subagent({
  async: true,
  workflowScript: `
    const RUN = ".sixpack/<run-id>";
    const build = await runs.run("coder", {
      agent: "coder", context: "fresh",
      output: RUN + "/20-coder.md", outputMode: "file-only",
      task: "<Implement the accepted spec at " + RUN + "/10-spec.md. Target/seams, baseline, verify command, authority, stop rules.>"
    });
    const clean = await runs.run("cleaner", {          // pack 6 only
      agent: "cleaner", context: "fresh",
      output: RUN + "/25-cleaner.md", outputMode: "file-only",
      task: "Behavior-preserving cleanup of the coder's diff. Coder handoff: " + build.output + ". Baseline stays green: <verify command>."
    });
    return { build: build.output, clean: clean.output };
  `
})
```

Gate: `blocked` or `partial` → fix or re-scope before the review gates. The
parent personally reviews the diff.

**Wave 3 — Review gates** (pack 4: architect only; pack 6: both, parallel).
Read-only, distinct angles. The hardener runs probes, so its task carries the
bulk rule.

```typescript
subagent({
  async: true,
  workflowScript: `
    const RUN = ".sixpack/<run-id>";
    return await runs.all([
      { key: "arch", agent: "sw-architect", context: "fresh",
        output: RUN + "/30-arch.md", outputMode: "file-only",
        task: "Review invariants, boundaries, dependency direction, data-shape flow of the diff: <changed files>. Read-only." },
      { key: "harden", agent: "hardender", context: "fresh",   // pack 6 only
        output: RUN + "/31-harden.md", outputMode: "file-only",
        task: "Derive adversarial checks from the changed risk in: <changed files>. Run them. No source edits. Baseline: <verify command>. Probe logs and traces go to " + RUN + "/scratch/, get read, get quoted in your report, then get deleted." }
    ]);
  `
})
```

**Wave 4 — Fix loop** (only on BLOCK or P1 findings worth doing now). The
parent triages first and puts both halves of the decision in the task —
accepted findings and declined ones with reasons. Declined is a record, not
an omission.

```typescript
subagent({
  async: true,
  workflowScript: `
    const RUN = ".sixpack/<run-id>";
    const fix = await runs.run("fix", {
      agent: "coder", context: "fresh",
      output: RUN + "/40-fix-1.md", outputMode: "file-only",
      task: "Apply ONLY these accepted findings: <verbatim finding + file:line>. Declined, do not touch: <finding + reason>. Baseline stays green: <verify command>. No scope beyond the named findings."
    });
    const recheck = await runs.run("recheck", {
      agent: "hardender", context: "fresh",        // or sw-architect — whoever raised them
      output: RUN + "/41-recheck-1.md", outputMode: "file-only",
      task: "Two questions only. (1) Is each named finding resolved: <list>? (2) Any new defect inside the fix blast radius: " + fix.output + ". Read-only."
    });
    return { fix: fix.output, recheck: recheck.output };
  `
})
```

Max 3 rounds; round 2 uses `42-fix-2.md` / `43-recheck-2.md`. Unapproved
scope changes go to the user, not the fix coder.

**Wave 5 — QA** (all packs). Independent verification against the spec.

UI deliverables: **save the screenshot to a file, then `read` that file.** A
snapshot held in memory is never seen — `glm-vision` hooks the `read` tool, so
an unsaved capture yields no description and QA would be reporting from DOM
text. Then the bulk rule applies: cite what the image showed, delete the file.

Vision applies to `zai` children only — the extension gates on the child's
provider. It is ambient, so **do not** add an `extensions` list to the qa
agent or any profile; an explicit list disables ambient loading and silently
strips it. Anthropic and openai-codex models are natively multimodal.

```typescript
subagent({
  async: true,
  workflowScript: `
    const RUN = ".sixpack/<run-id>";
    return runs.run("qa", {
      agent: "qa", context: "fresh",
      output: RUN + "/50-qa.md", outputMode: "file-only",
      task: "Independently verify through the real public surface. Oracle: " + RUN + "/10-spec.md. Baseline: " + RUN + "/00-baseline.md. Verify command: <cmd>. Read-only on source. UI: save each screenshot under " + RUN + "/scratch/, read the file, record what it showed, then delete it — keep the observation, not the image."
    });
  `
})
```

## Step 4 — Report

Report in order: context · what changed (behavior, not file names) · what
stayed untouched · status, separating passes, regressions, pre-existing
failures, skipped checks, environment limits · the QA verdict line
(`integration: verified` / `not verified`) · the one open question that
changes the next decision.

Write the same thing to `<RUN>/99-report.md`, ending with the manifest:
artifacts produced, each gate's verdict, the model each gate ran on.

### Plain language

The reader is a teammate six months later, or a non-engineer.

- One idea per sentence. Short sentences. Active voice.
- Behavior, not file names — "users of one tenant can no longer read another
  tenant's invoices", not "patched `InvoiceRepo.findAll`".
- No pipeline vocabulary. "Gate", "pack 6", "hardender", "P1" are our words,
  not the reader's. The manifest may name them; the summary may not.
- Say what is **not** done: unverified, declined, still needs a human.
- Facts only. No adjectives about the work's quality.

## Step 5 — Commit code and report together

`.sixpack/` is ignored scratch and disappears. The report is the one artifact
worth keeping, so it lands on a tracked path — **in the same commit as the
code it describes**. They are one change: a reviewer gets the explanation
beside the diff, and a revert takes both.

```bash
find .sixpack/<run-id>/scratch -type f -delete 2>/dev/null || true   # sweep leftover bulk; absent is normal
mkdir -p docs/changes
cp .sixpack/<run-id>/99-report.md docs/changes/<run-id>.md

git add <files the coder changed> docs/changes/<run-id>.md
git status                            # confirm the staged set — no strays
```

**Stop here. Show the user the staged file list and the commit message, and
wait.** The user gives the final check. Do not commit on assumed approval.

```bash
git commit -m "<type>: <what changed, in plain words>"
git push
```

Stage named paths only. Never `git add -A` or `git add .` — a run leaves
scratch that must not be swept in.

Subject takes the **code** change's type, not `docs:` — the report is a
passenger. Imperative, under ~70 chars. Good: `fix: stop one tenant from
reading another tenant's invoices`. Bad: `docs: add 99-report.md for run
20260824-2140`. Body: three or four plain sentences, then
`Report: docs/changes/<run-id>.md`.

Pushing a shared or protected branch needs its own approval, separate from the
commit check. Non-git: skip.

## Model profiles

Loadable from `profiles/pi-subagents/` via `/subagents-load-profile <name>`.
Loading replaces `settings.subagents` wholesale.

| Gate | codex-only | claude-only | mix | glm-max |
|---|---|---|---|---|
| specifier | sol · high | sonnet-5 · high | opus-5 · high | glm-5.3 · max |
| coder | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| cleaner | luna · xhigh · fast | haiku-4-5 · med | luna · xhigh · fast | glm-5.3 · max |
| sw-architect | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| hardender | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| qa | luna · xhigh · fast | sonnet-5 · med | glm-5.3 · med | glm-5.3 · max |

The hardener always gets a top model. It is the only gate that invents its own
checks rather than reading a given artifact, its failure mode is a silent
`PASS` no later gate catches, and it holds BLOCK authority.

`mix` spends its Anthropic budget upstream: opus-5 writes the spec, codex sol
builds and reviews against it, glm-5.3 verifies. The cross-provider check sits
between the spec and the code, not between the code and its review.

`fast: true` is the openai-codex priority tier; a no-op elsewhere. `glm-max`
QA gets vision from the ambient `glm-vision` extension — see Wave 5.

## Constraints

- One writer per checkout, always. Parallel lanes are read-only.
- Children never run subagents and never decide loop outcomes or scope.
- Every wave that changes the tree or a verdict leaves a numbered artifact,
  including each fix round. A run is reconstructable from disk alone.
- Brownfield needs the baseline before wave 2. Never present a QA pass
  without the baseline diff.
- Greenfield non-git: git optional, but the coder leaves a runnable scaffold
  the verify command can execute.
- User-owned decisions: pack choice, spec open decisions, unapproved scope
  changes, merge/publish boundaries. The commit needs the user's final check
  on the staged list and message — never assume approval.
- Keep observations, not bulk. Any gate producing screenshots, logs, traces,
  or large dumps writes them to `<RUN>/scratch/`, reads them, quotes the
  deciding lines in its report, then deletes them. Step 5 sweeps the rest.
