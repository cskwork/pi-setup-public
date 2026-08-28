# pi-setup

My [pi coding agent](https://github.com/badlogic/pi-mono) configuration — skills, extensions, agents, and a friendly permission policy. Restore on any machine in one command.

**Landing page:** <https://cskwork.github.io/pi-setup-public/> (public repo) · **한국어:** [README.ko.md](README.ko.md)

## Quick start

### macOS, Linux, or Git Bash

```bash
git clone https://github.com/cskwork/pi-setup-public.git ~/pi-setup-public
~/pi-setup-public/install.sh
pi auth   # log in to your providers
# restart your shell, then restart pi
```

### Windows PowerShell

```powershell
git clone https://github.com/cskwork/pi-setup-public.git "$HOME\pi-setup-public"
Set-Location "$HOME\pi-setup-public"
if ((Get-ExecutionPolicy) -eq 'Restricted') {
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
}
.\install.ps1
pi auth   # log in to your providers
# reopen PowerShell, then restart pi
```

The installers link `~/.pi/agent/{AGENTS.md, settings.json, extensions, agents, skills}` into this repo, install every package below, and deploy the default permission config. Existing files are backed up, never overwritten.

They also add a managed shell-profile block that gives only Pi an 8 GiB V8 heap. Other Node processes keep their defaults, existing `NODE_OPTIONS` values are preserved, and the active NVM/npm Pi executable is resolved on every call. Re-run the installer after moving the checkout. Remove the block between the `pi-setup Pi-only Node heap` markers to uninstall it. If you use both Windows PowerShell 5.1 and PowerShell 7, run `install.ps1` once in each. Organization-enforced policies can still block PowerShell profiles; those require an administrator policy change.

The default model is `zai/glm-5.3-flash` at thinking `max`; `models.json` declares native text and image input with a 1M context window.

Keep drift in sync afterwards with `~/pi-setup-public/sync.sh`.

## What's inside

### Skills (27)

| Skill | What it does | Source |
| --- | --- | --- |
| `agent-browser` | Browser automation CLI for agents | [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) |
| `api-and-interface-design` | Stable API/interface design — contract-first, Hyrum's Law, idempotency-key claiming, consistent error shapes | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) |
| `browser-qa` | Browser QA on anything — YAML DAG scenarios, engine choice (native `agent_browser` tool first), API evidence, `superqa` runtime; Playwright E2E patterns in `reference/e2e-patterns.md` | [cskwork/browser-qa](https://github.com/cskwork/browser-qa) |
| `db-intelligence` | One DB skill, four engines — PostgreSQL, MySQL, SQLite, MongoDB. Credential-safe, read-first, schema-before-SQL; outputs a domain evidence artifact (entity graph + ubiquitous language + data shapes) | local |
| `playwright-cli` | Drive a browser directly; inspect or author Playwright tests | local |
| `call-agent` | Route a task to the best peer AI CLI | [cskwork/call-agent](https://github.com/cskwork/call-agent) |
| `verify` | 5-gate verification; refuses "green build = verified" | [cskwork/verify-skill](https://github.com/cskwork/verify-skill) |
| `verification-before-completion` | Evidence before assertions — never claim unverified work done | [obra/superpowers](https://github.com/obra/superpowers) |
| `pi-settings` | Audit and configure pi's own settings.json — skill isolation, subagent routing, packages | local |
| `diagnosing-bugs` | Diagnosis loop for hard bugs and performance regressions — reproduce → minimise → hypothesise → instrument → fix → regression-test | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `tdd` | Test-driven development — red-green-refactor, integration tests, mocking patterns | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `code-review` | Review changes since a fixed point along Standards and Spec axes, in parallel sub-agents | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `implement` | Implement a piece of work based on a spec or tickets | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `research` | Investigate against high-trust primary sources, capture findings as Markdown | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `domain-modeling` | Build and sharpen a project's domain model — CONTEXT.md, ADRs | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `improve-codebase-architecture` | Scan for deepening opportunities, visual HTML report, then grill through the pick | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `resolving-merge-conflicts` | Resolve an in-progress git merge/rebase conflict | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `grilling` | Relentlessly stress-test a plan, decision, or idea | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `wait-what` | Stop — that last message did not land, re-pitch it | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `writing-for-agents` | Writing documents for agents — skills, AGENTS.md, CLAUDE.md | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `handoff` | Compact the conversation into a handoff doc for the next agent | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `teach` | Teach a skill or concept within the workspace | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `find-skills` | Discover and install new agent skills on demand | local |
| `gpt-image-2` | Image generation via Codex CLI + ChatGPT plan | local |
| `impeccable` | Frontend design review & polish | [oddxinformatics/impeccable](https://github.com/oddxinformatics/impeccable) |
| `ego-browser` | Agent-friendly browser sharing logged-in state | [citrolabs/ego-lite](https://github.com/citrolabs/ego-lite) |
| `pi-sixpack` | SwarmForge-style 6-role gated pipeline (Wave 0 parallel explore → specifier→coder→cleaner→architect∥hardender→QA, packs 2/4/6) via pi subagents | port of [cskwork/aidt-swarmforge-harness](https://github.com/cskwork/aidt-swarmforge-harness) |

### Extensions

Installed via `pi install` (see `settings.json`):

| Package | Purpose |
| --- | --- |
| `npm:@gotgenes/pi-permission-system` | Pattern-based permissions (see below) |
| `npm:@narumitw/pi-goal` | Session goals — pi keeps working to completion |
| `npm:@narumitw/pi-usage` | Usage/cost tracking |
| `npm:pi-subagents` | Subagent orchestration |
| `npm:pi-lens` | Real-time code feedback — LSP, linters, formatters, type-checks |
| `npm:pi-background-tasks` | Named background shell tasks |
| `npm:context-mode` | Keep big tool outputs out of your context |
| `npm:pi-memory` (`@samfp/`) | Persistent learned preferences |
| `npm:pi-oracle` | Async ChatGPT Pro/Grok web jobs with isolated one-time browser auth |
| `npm:pi-mcp-adapter` | MCP servers without context bloat |
| `npm:pi-web-access` | Web search/fetch |
| `npm:pi-simplify` | Code simplification |
| `npm:pi-markdown-preview` | Rendered markdown previews |
| `npm:pi-powerline-footer` | Status footer |
| `npm:@juicesharp/rpiv-todo` | Todo management |
| `npm:@juicesharp/rpiv-ask-user-question` | Structured questions |
| `npm:pi-ponytail` | Lazy-senior-dev mode (YAGNI ladder) — skills wired to coder/cleaner; default mode `off`, opt in with `/ponytail` |
| `npm:pi-agent-browser-native` | agent-browser as a native `agent_browser` tool — first pick in browser-qa's engine cascade (requires upstream `agent-browser` CLI on PATH) |

Plus local extensions in `extensions/`: `dirty-repo-guard.ts` (uncommitted-change guard on session switch) and `herdr-agent-state.ts`. Bash permissions are owned solely by `@gotgenes/pi-permission-system`.

### Subagent model profiles (6)

`profiles/pi-subagents/*.json` — swap per-gate models for the six-pack pipeline with
`/subagents-load-profile <codex-only|claude-only|mix|glm-max>`:

| Gate | `codex-only` | `claude-only` | `mix` | `glm-max` |
| --- | --- | --- | --- | --- |
| specifier | sol · high | sonnet-5 · high | opus-5 · high | glm-5.3 · max |
| coder | luna · max | opus-5 · high | codex sol · high | glm-5.3 · max |
| cleaner | luna · xhigh · fast | haiku-4-5 · med | luna · xhigh · fast | glm-5.3 · max |
| sw-architect | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| hardender | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| qa | luna · xhigh · fast | sonnet-5 · med | glm-5.3 · med | glm-5.3 · max |

The hardender always gets a top model: it is the only gate that invents its own
checks instead of reading a given artifact, its failure mode is a silent `PASS`
no later gate catches, and it holds BLOCK authority.

**Utility agents** — every profile also routes the non-gate agents on a two-tier
scheme: `planner` and `security` get the profile's deep model (they reason about
what to build, not just execute), while `refactorer`, `doc-writer`, `git-ops`,
`javascript-pro`, `typescript-pro`, `delegate`, `scout`, `researcher`,
`reviewer`, `worker`, `tester`, `debugger` get the cheap/fast one.

**Gotcha — no `model:` in agent frontmatter.** pi-subagents resolves frontmatter
`model:` *before* `agentOverrides`, so an agent that pins a model in its `.md`
silently ignores every profile. All `agents/*.md` here ship without a `model:`
line on purpose; profiles are the single source of truth for routing. Add one
back only when an agent must never follow the profile.

**Pack profiles** — `two-pack` and `four-pack` pin the `glm-max` models to only the
gates that pack runs (two-pack: coder → qa; four-pack: specifier → coder →
refactorer → sw-architect → qa). Role orders mirror the upstream SwarmForge
branches, with the pi pipeline's independent QA gate kept in every pack. Load one
when the pack is already decided; they keep the utility agents' skill lists so a
wholesale load strips nothing. Pack 6 uses any model profile directly.

### Skills by default

Every profile sets `agentOverrides.<agent>.skills`, so domain skills load with the
agent instead of per-call wiring:

- **QA/browser tier** — `qa`, `qa-tester`, `qa-auditor`, `agent-browser` get `browser-qa` (+ `agent-browser`, `playwright-cli` where relevant)
- **Persona tier** — `customer-agent`, `persona-product-tester` get `browser-qa` + `agent-browser`
- **Verify/TDD/debug tier** — `verify`, `tester`, `hardender`, `debugger`, `coder` get the verify / tdd / diagnosing-bugs skills
- **Domain-data tier** — `specifier`, `hardender`, `qa` get `db-intelligence` (domain data before code, integrity probes, read-only DB evidence)
- **Minimalism tier** — `coder` gets `ponytail`, `cleaner`/`refactorer` get `ponytail-review`
- **Architecture tier** — `sw-architect` gets `api-and-interface-design` (vendored in `skills/`, so a fresh clone has it). The agent prompt says *what* to review; the skill supplies the reference material — Hyrum's Law, idempotency-key claiming and its TOCTOU trap, error-shape consistency, additive-change rules.

The six-pack's **Wave 0** fans these out in parallel before specification: Jira
requirements (atlassian-cli, when present) ∥ code graph ∥ DB evidence ∥ browser
as-is — read-only nodes of a dependency DAG whose artifacts the spec must cite.

### Permission policy (default)

`configs/permissions.json` deploys as `extensions/pi-permission-system/config.json`. It feels like stock pi — reads, file tools, skills, ctx tools, and normal shell commands all flow without prompts — with rails only where it matters:

- secret-bearing files (`.env*`, credentials, private keys, application configs, `~/.ssh/*`) denied across tools
- recursive deletion, privilege escalation, disk writes, and destructive Git operations ask
- filesystem-root deletion and disk formatting deny
- normal commands and external directories allow

Your live config is **yours**: it's gitignored here, and edits via pi's permission modal stay local. The repo copy stays a clean, friendly default for fresh installs.

## Layout

```
AGENTS.md            operating instructions (symlinked to ~/.pi/agent)
settings.json        provider + packages
configs/             permission default (public)
skills/              27 curated skills
agents/              subagent role prompts
extensions/          local TS extensions
scripts/             check-docs.py — CI guard for doc/config drift
                     pi-node-heap.sh/.ps1 — Pi-only 8 GiB launchers
                     prune-sessions.sh — session transcript retention
tests/               shell and PowerShell launcher regression checks
install.sh           macOS/Linux/Git Bash bootstrap
install.ps1          native Windows PowerShell bootstrap
sync.sh              save drift back to GitHub
```

## Backup

`sync.sh` commits and pushes local drift. Memory and session data live outside this repo by design.

### Session retention

`~/.pi/agent/sessions/` stores every session as JSONL, and **every user prompt is
kept verbatim**. Nothing prunes it, so it grows without bound (72 MB / 385 files
before the first prune here). It is local only — never committed to any repo.

```bash
scripts/prune-sessions.sh              # dry run, 90-day retention
scripts/prune-sessions.sh --apply      # delete, tar.gz backup first
DAYS=30 scripts/prune-sessions.sh --apply
scripts/prune-sessions.sh --apply --no-backup
```

Deleted files are archived to `sessions.prune-backup-<timestamp>.tar.gz` next to
the sessions directory unless `--no-backup` is passed, so a prune is reversible.

### Memory backup

`sync-memory.sh` mirrors `~/.pi/agent/memory` (pi-memory's markdown store) to the private
`cskwork/pi-memory-backup` repo, and aborts if that remote is not private. A LaunchAgent
(`com.cskwork.pi-memory-sync`) runs it daily at 21:00; logs land in `~/Library/Logs/pi-memory-sync.*.log`.
