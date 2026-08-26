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
