# Changelog

Public replica of the private `pi-setup` repo. Same skills, extensions, agents,
and configs — minus everything private (memory, domain packs, backup machinery).

## 2026-08-26 — initial public snapshot

- 26 skills (browser-qa, verify, diagnosing-bugs, tdd, code-review, implement,
  research, domain-modeling, improve-codebase-architecture, resolving-merge-conflicts,
  grilling, wait-what, writing-for-agents, handoff, teach, …)
- pi-permission-system friendly default, six-pack subagent profiles, GSD-style
  agent library, docs landing page.
- Memory and private sync scripts intentionally excluded.

## Unreleased

### Fixed

- **README skill tables were stale** — header said 16, table had 25 rows,
  `skills/` has 26 (the `pi-settings` row was missing). The Layout block
  repeated the wrong 16 too. Both READMEs, both languages.
- **`api-and-interface-design` was referenced but never installed** — wired into
  `sw-architect` in 5 profiles plus `settings.json` since 2026-08-25, but present
  in neither `skills/` nor `~/.agents/skills`. Traced to
  [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT) and
  installed for real rather than dropped: vendored into `skills/` (real copy, so
  a fresh clone works) and symlinked into `~/.agents/skills` from
  `sources/addyosmani/agent-skills` for Claude Code and Codex. pi excludes the
  hub, so both roots are required. `ponytail`/`ponytail-review` need no copy —
  they ship inside the `pi-ponytail` package and resolve at runtime.

### Added

- **`scripts/prune-sessions.sh` — session transcript retention.** `~/.pi/agent/sessions/`
  keeps every user prompt verbatim in JSONL and nothing prunes it; it had reached
  72 MB across 385 files. The script defaults to a 90-day retention, dry-runs
  unless given `--apply`, and tars what it deletes to
  `sessions.prune-backup-<timestamp>.tar.gz` so a prune is reversible. Retention
  is tunable with `DAYS=` or `--days=`. First run removed 26 files / 2.1 MB
  (everything from before 2026-06-14).

- **`scripts/check-docs.py` + `check-docs` workflow** — CI guard for the drift
  class above. Six assertions: README skill header/rows match `skills/`, the
  Layout block count matches, no `agents/*.md` pins `model:` in frontmatter,
  every profile-referenced skill resolves (in `skills/` or an installed
  package), every agent has a `settings.json` override, and every README
  profile-table cell matches the profile JSON. Each assertion was verified to
  fail on its own bug before being kept.

## v0.5.0 — 2026-08-27

Makes subagent model profiles actually authoritative.

- **Fixed: agent frontmatter silently overrode every profile** — v0.4.0 fixed one
  stale pin but left the mechanism in place. pi-subagents resolves a `.md` file's
  `model:` *before* `agentOverrides`, so the 9 agents that pinned one (`planner`,
  `security`, `refactorer`, `doc-writer`, `git-ops`, `javascript-pro`,
  `typescript-pro`, `reviewer`, `tester`, `debugger`) ignored
  `/subagents-load-profile` entirely. `model:` is now removed from all 19
  `agents/*.md`; profiles are the single source of truth for routing.
- **Utility agents routed in every profile** — `planner`, `security`,
  `refactorer`, `doc-writer`, `git-ops`, `javascript-pro`, `typescript-pro`,
  `delegate` gained entries in all 6 profiles plus `settings.json`, two-tier:
  `planner`/`security` take the profile's deep model, the rest the cheap/fast
  one. Previously they had no override and no fallback chain, so one dead
  provider failed the launch outright.
- **Docs** — README (EN/KO) and the landing page now state the
  `model:`-beats-`agentOverrides` precedence rule. Corrected the KO profile
  table's `codex-only` coder cell (`sol · high` → `luna · max`); all 24 gate
  cells re-verified against the JSON.

Verified: `grep -l '^model:' agents/*.md` returns nothing; every profile
resolves `planner` to its tier model.

## v0.4.0 — 2026-08-27

- **All subagents now run `zai/glm-5.3-flash` at thinking `max`** — settings.json
  agentOverrides plus agent frontmatter. Default session model unchanged.
- **`glm-5.3-flash` registered in `models.json`** (zai provider) — 1M context,
  131072 max output, zai thinking format. Needed until pi's built-in registry
  learns the id.
- **Fixed: agent frontmatter pinned a dead `sonnet` alias** — pi-subagents
  precedence is frontmatter > agentOverrides, so stale pins silently broke
  launches with "Unknown subagent model".
- **`install.sh` cross-platform hardening** — symlink failures (Windows without
  Developer Mode) fall back to copying; `python3` falls back to `python`.

Verified: fresh `pi -p` run launched the `reviewer` subagent on flash/max and
returned its sentinel output; direct `--model zai/glm-5.3-flash --thinking max`
runs clean with no custom-model warning.
