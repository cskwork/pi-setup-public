# Changelog

## Unreleased

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
