# Changelog

## Unreleased

## v0.5.1 — 2026-08-28

Hardens setup and publishing while keeping Pi's model routing, shell launchers,
and public documentation reproducible across supported platforms.

### Added

- **Pi-only 8 GiB V8 launchers** for bash, zsh, Git Bash, Windows PowerShell
  5.1, and PowerShell 7. They preserve existing `NODE_OPTIONS`, resolve the
  active NVM/npm Pi executable on every call, and leave other Node processes
  unchanged.
- **Native Windows PowerShell installation** plus cross-platform launcher CI for
  argument forwarding, exit codes, profile idempotence, and heap size.
- **Provider-specific low-cost roles** — `architect-glm` and `tester-glm` keep
  GLM-5.3-Flash as their primary route while using settings-owned fallback
  chains. `pi-oracle` adds isolated ChatGPT Pro/Grok web jobs.
- **Guarded private-to-public sync** with an explicit file policy, domain leak
  checks, staged review, and public-link CI.
- **Maintenance tools and skills** — 90-day session transcript pruning with a
  reversible backup, and the vendored `api-and-interface-design` skill.

### Changed

- **GPT-first routing** — the session default is
  `openai-codex/gpt-5.6-sol` at `xhigh`; subagents use role-specific Sol/Luna
  tiers with Anthropic and Z.ai fallbacks. GLM-5.3-Flash remains registered for
  native text and image input.
- **One Bash permission authority** — `@gotgenes/pi-permission-system` now owns
  command approval without a second local prompt layer.
- **Normal work prompts less often** while recursive deletion, privilege
  escalation, disk writes, and destructive Git commands remain guarded.
- **Over-engineering is explicitly rejected** in `AGENTS.md` unless a current
  requirement justifies the abstraction, dependency, or configurability.

### Fixed

- **Recursive deletion guard bypasses** — uppercase and reordered recursive
  `rm` flags now ask for approval; commands targeting filesystem root are
  denied after the broader rule is evaluated.
- **Subagent routing CI** — GLM role files no longer pin frontmatter models, and
  both roles now have explicit `settings.json` routes and fallback chains.
- **Session backup privacy and empty-prune behavior** — transcript archives are
  mode `0600`, the sessions root survives when every old file is removed, and
  size calculation works on macOS and Linux.
- **Stale configuration documentation** — README default-model text, skill
  tables, layout counts, profile tables, and public setup links now match the
  files users actually install.
- **Git Bash launcher edge cases** — path conversion, symbolic-link emulation,
  and platform-specific profile selection are covered by regression tests.

### Verification

`check-docs`, public-link checks, recursive-permission cases, session-pruning
regressions, POSIX launchers, Git Bash, Windows PowerShell 5.1, and PowerShell 7
are release gates.

## v0.5.0 — 2026-08-27

Makes subagent model profiles actually authoritative. Every agent now follows
the loaded profile, and the profiles cover the utility agents too.

### Fixed

- **Agent frontmatter silently overrode every profile** — pi-subagents
  resolves a `.md` file's `model:` field *before* `agentOverrides`, so the 9
  agents that pinned one (`planner`, `security`, `refactorer`, `doc-writer`,
  `git-ops`, `javascript-pro`, `typescript-pro`, `reviewer`, `tester`,
  `debugger`) ignored `/subagents-load-profile` entirely. The `model:` line is
  removed from all 19 `agents/*.md`; profiles are now the single source of
  truth for routing.

### Added

- **Utility agents routed in every profile** — `planner`, `security`,
  `refactorer`, `doc-writer`, `git-ops`, `javascript-pro`, `typescript-pro`,
  and `delegate` gained entries in all 6 profiles plus `settings.json`, on a
  two-tier scheme: `planner` and `security` take the profile's deep model
  (they decide what to build), the rest take the cheap/fast one. Previously
  these agents had no override at all — no fallback chain, so a single dead
  provider failed the launch outright.
- **Frontmatter gotcha documented** — README (EN/KO) and the landing page now
  state the `model:`-beats-`agentOverrides` precedence rule, so the bug does
  not get reintroduced.

### Changed

- **`README.ko.md` profile table corrected** — the `codex-only` coder cell
  read `sol · high`; the profile has always been `luna · max`. All 24 gate
  cells re-verified against the JSON.

### Verification

`grep -l '^model:' agents/*.md` returns nothing in both repos. Every profile
resolves `planner` to its tier model (claude-only → opus-5, codex-only → sol,
mix → opus-5, glm/four/two-pack → glm-5.3, settings.json → glm-5.3-flash).
Uncovered agents remain only where a pack deliberately excludes the role.

## v0.4.0 — 2026-08-27

Routes every subagent to Z.ai's new GLM-5.3-Flash, swaps in Matt Pocock's
skill set, and makes `install.sh` Windows-tolerant.

### Changed

- **All 18 subagents now run `zai/glm-5.3-flash` at thinking `max`** —
  settings.json agentOverrides plus every agent frontmatter file. The default
  session model is untouched (`anthropic/claude-opus-5`); only delegated
  roles moved to Flash.
- **`glm-5.3-flash` registered as a custom model in `models.json`** (zai
  provider) — mirrors the built-in glm-5.3 entry: 1M context, 131072 max
  output, zai thinking format, coding-plan endpoint. pi's registry doesn't
  know the id yet; without the registration subagent preflight rejects it.
- **Skill set swap (26 skills)** — obra's systematic-debugging and
  test-driven-development replaced by Matt Pocock's `diagnosing-bugs` and
  `tdd` (MIT); added code-review, implement, research, domain-modeling,
  improve-codebase-architecture, resolving-merge-conflicts, grilling,
  wait-what, writing-for-agents, handoff, teach.
- **Landing page moved to pi-setup-public** — private repos can't serve
  GitHub Pages; `docs/` now lives only in the public replica.
- **`install.sh` cross-platform hardening** — symlink failure (Windows
  without Developer Mode) falls back to copying, and `python3` falls back to
  `python` where only the latter exists.

### Fixed

- **Agent frontmatter pinned the dead `sonnet` alias** — pi-subagents
  precedence is frontmatter > agentOverrides, so the stale pins silently
  outranked settings and broke launches with "Unknown subagent model".
  Frontmatter now pins `zai/glm-5.3-flash` directly.

### Verification

- Fresh `pi -p` run: `reviewer` subagent returned `SUB-FLASH-OK` on
  flash/max; direct `--model zai/glm-5.3-flash --thinking max` runs clean
  with no custom-model warning.

## v0.3.0 — 2026-08-26

Swaps pi's memory for the first-party `pi-memory` extension, stops forcing a
skill on every turn, and puts the memory backup on a daily schedule.

### Added

- **`db-intelligence` skill** — one consolidated database skill for
  PostgreSQL, MySQL, SQLite, and MongoDB: engine detection, credential-safe
  connect, schema-before-SQL, read-first writes with approval, and a domain
  evidence artifact (entity-relationship graph slice + ubiquitous language +
  data shapes). Per-engine references under `reference/`; private per-project
  routing lives in gitignored `reference/domain/` packs.
- **Six-pack Wave 0 — parallel explore fanout** — before specification, the
  parent fetches Jira requirements (atlassian-cli) while read-only DAG nodes
  run in parallel: code graph (scout), DB evidence (scout + db-intelligence),
  browser as-is (qa). Artifacts `01`–`04` become the edges the spec must cite;
  a merge gate requires the code/entity/UI graphs to agree.
- **`npm:pi-ponytail`** — lazy-senior-dev (YAGNI) mode; `ponytail` skill wired
  to the coder, `ponytail-review` to cleaner/refactorer. Default mode `off`.
- **`npm:pi-agent-browser-native`** — agent-browser as a native `agent_browser`
  tool; now rank 0 in browser-qa's engine cascade (CLI stays as fallback).
- **Skill wiring across all profiles** — specifier/hardender/qa get
  `db-intelligence`, sw-architect gets `api-and-interface-design`; synced
  through settings.json and all six profiles so a wholesale load strips
  nothing.

- **Pack profiles `two-pack` and `four-pack`** (`profiles/pi-subagents/`) —
  load a decided pack's gate set with `/subagents-load-profile two-pack |
  four-pack`. Both pin the `glm-max` models and keep utility agents' skill
  lists.
- **Four-pack follows upstream SwarmForge's role order** — the pipeline is now
  `specifier → coder → refactorer → sw-architect → qa`: the refactorer runs
  as the behavior-preserving cleanup gate (artifact `25-refactorer.md`),
  matching upstream's four-pack branch. The independent QA gate stays in
  every pack.
- **Daily memory backup** — the `com.cskwork.pi-memory-sync` LaunchAgent runs
  `sync-memory.sh` at 21:00 (plist checked in under `configs/`). Logs land in
  `~/Library/Logs/pi-memory-sync.*.log`.

### Changed

- **Memory is now `npm:pi-memory`** (<https://pi.dev/packages/pi-memory>),
  replacing `@samfp/pi-memory` and the `ai-memory` server wiring. Memory lives
  as plain markdown under `~/.pi/agent/memory/` — no server, no port, no
  autostart. The five facts held in the old SQLite store were migrated into
  `MEMORY.md` with their original timestamps.
- **Skill routing is no longer mandatory.** `AGENTS.md` dropped the
  "route through `using-superpowers`" directive from the routing line and from
  step 1, and the step 4 interview is now conditional on intent still being
  unclear. The router skill stays installed and model-invokable; it is simply
  not commanded every turn.
- **`sync-memory.sh` backs up the markdown store** instead of the retired
  SQLite database, and refuses to push when the remote is not private.

### Removed

- **`extensions/ai-memory-pi.ts`** — the generated ai-memory lifecycle hooks.
  The ai-memory server and its wiring for other agents are untouched.
- **`extensions/superset-hooks.ts`** — Superset lifecycle notifications.

## v0.2.0 — 2026-08-24

First tagged release. Adds real-time code feedback, retunes the subagent model
profiles against current model pricing, and makes the six-pack pipeline keep
evidence instead of bulk.

### Added

- **`pi-lens`** — real-time code feedback while the agent edits: LSP
  diagnostics, linters, formatters, type-checking, and structural rules.
  Note: it ships a git-guard that holds commit and push while findings are
  unresolved.
- **`README.ko.md`** — Korean README, kept in step with the English one.

### Changed

- **Cleaner and QA moved to `gpt-5.6-luna` in `codex-only`**, at `xhigh`
  thinking with the priority tier on. The models they replaced were dominated:
  `codex-spark` cost roughly nine times more than luna with half the context
  and no tool search, and `gpt-5.4` cost more than terra while doing less.
- **`mix` spends its Anthropic budget upstream.** `opus-5` now writes the
  spec; codex sol builds and reviews against it; glm-5.3 verifies. Three
  providers, with the cross-provider check between spec and code.
- **`claude-only` specifier raised to `high` thinking.** A vague spec is the
  one defect no later gate repairs, because every gate checks against it.
- **Codex fallback chains step down through `gpt-5.6-terra`** before `gpt-5.5`,
  which is cheaper and more capable than the model it precedes.
- **Six-pack runs now leave a reconstructable record.** Artifacts live in
  `.sixpack/<run-id>/`, numbered in pipeline order, with the directory ignored
  through `.git/info/exclude` so no tracked file changes.
- **The fix loop writes artifacts.** Each round produces a fix report and a
  targeted re-check report; accepted and declined findings are both recorded.
- **Bulk stays out of the repo.** Every gate writes screenshots, probe logs,
  and traces to `<RUN>/scratch/`, reads them, quotes the deciding lines, then
  deletes them.
- **QA must save a screenshot before reading it.** `glm-vision` hooks the read
  tool, so an in-memory capture is never described — without this, QA would
  report from page text while appearing to check the screen.
- **The run report ships with the code it describes**, in one commit, at
  `docs/changes/<run-id>.md`, written in plain language.
- **The commit step stops for the user.** The staged list and message are shown
  and approval is required; the previous wording let an agent print and
  continue.

### Fixed

- The scratch sweep in the commit step is guarded, so it no longer fails when
  gates cleaned up properly and the directory is absent.
- The README subagent table described retired models (`codex-spark`,
  `gpt-5.4`); it now shows per-gate routing that matches the profile files.
- The skills count said 10 while 12 were listed.
