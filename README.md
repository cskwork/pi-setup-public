# pi-setup

My [pi coding agent](https://github.com/badlogic/pi-mono) configuration — skills, extensions, agents, and a friendly permission policy. Restore on any machine in one command.

**Landing page:** https://cskwork.github.io/pi-setup/ · **한국어:** [README.ko.md](README.ko.md)

## Quick start

```bash
git clone https://github.com/cskwork/pi-setup.git ~/pi-setup
~/pi-setup/install.sh
pi auth   # log in to your providers
# restart pi
```

`install.sh` symlinks `~/.pi/agent/{AGENTS.md, settings.json, extensions, agents, skills}` into this repo, installs every package below, and deploys the default permission config. Existing files are backed up, never overwritten.

Keep drift in sync afterwards with `~/pi-setup/sync.sh`.

## What's inside

### Skills (12)

| Skill | What it does | Source |
|---|---|---|
| `agent-browser` | Browser automation CLI for agents | [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) |
| `impeccable` | Frontend design review & polish | [oddxinformatics/impeccable](https://github.com/oddxinformatics/impeccable) |
| `gpt-image-2` | Image generation via Codex CLI + ChatGPT plan | local |
| `improve-codebase-architecture` | Refactor for navigability under green tests | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `handoff` | Session handoff summaries | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `call-agent` | Route a task to the best peer AI CLI | [cskwork/call-agent](https://github.com/cskwork/call-agent) |
| `clean-code` | Behavior-preserving legacy refactors | [cskwork/clean-code](https://github.com/cskwork/clean-code) |
| `verify-skill` | 5-gate verification; refuses "green build = verified" | [cskwork/verify-skill](https://github.com/cskwork/verify-skill) |
| `ego-browser` | Agent-friendly browser sharing logged-in state | [citrolabs/ego-lite](https://github.com/citrolabs/ego-lite) |
| `promptbox` | One-shot catalog adds to the promptbox collection | [cskwork/promptbox](https://github.com/cskwork/promptbox) |
| `pi-sixpack` | SwarmForge-style 6-role gated pipeline (specifier→coder→cleaner→architect∥hardender→QA, packs 2/4/6) via pi subagents | port of [cskwork/aidt-swarmforge-harness](https://github.com/cskwork/aidt-swarmforge-harness) |
| `browser-qa` | Browser QA on anything — YAML DAG scenarios, engine choice, API evidence, `superqa` runtime | [cskwork/browser-qa](https://github.com/cskwork/browser-qa) |

### Extensions

Installed via `pi install` (see `settings.json`):

| Package | Purpose |
|---|---|
| `npm:@gotgenes/pi-permission-system` | Pattern-based permissions (see below) |
| `npm:@narumitw/pi-goal` | Session goals — pi keeps working to completion |
| `npm:@narumitw/pi-usage` | Usage/cost tracking |
| `npm:pi-subagents` | Subagent orchestration |
| `npm:pi-lens` | Real-time code feedback — LSP, linters, formatters, type-checks |
| `npm:pi-background-tasks` | Named background shell tasks |
| `npm:context-mode` | Keep big tool outputs out of your context |
| `npm:pi-memory` (`@samfp/`) | Persistent learned preferences |
| `npm:pi-mcp-adapter` | MCP servers without context bloat |
| `npm:pi-web-access` | Web search/fetch |
| `npm:pi-simplify` | Code simplification |
| `npm:pi-markdown-preview` | Rendered markdown previews |
| `npm:pi-powerline-footer` | Status footer |
| `npm:glm-vision` | GLM-4.6V vision |
| `npm:@juicesharp/rpiv-todo` | Todo management |
| `npm:@juicesharp/rpiv-ask-user-question` | Structured questions |

Plus local extensions in `extensions/`: `permission-gate.ts` (dangerous-command confirm), `dirty-repo-guard.ts` (uncommitted-change guard on session switch), `herdr-agent-state.ts`, `superset-hooks.ts`, `ai-memory-pi.ts`.

### Subagent model profiles (4)

`profiles/pi-subagents/*.json` — swap per-gate models for the six-pack pipeline with
`/subagents-load-profile <codex-only|claude-only|mix|glm-max>`:

| Gate | `codex-only` | `claude-only` | `mix` | `glm-max` |
|---|---|---|---|---|
| specifier | sol · high | sonnet-5 · high | opus-5 · high | glm-5.3 · max |
| coder | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| cleaner | luna · xhigh · fast | haiku-4-5 · med | luna · xhigh · fast | glm-5.3 · max |
| sw-architect | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| hardender | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| qa | luna · xhigh · fast | sonnet-5 · med | glm-5.3 · med | glm-5.3 · max |

The hardender always gets a top model: it is the only gate that invents its own
checks instead of reading a given artifact, its failure mode is a silent `PASS`
no later gate catches, and it holds BLOCK authority.

### Permission policy (default)

`configs/permissions.json` deploys as `extensions/pi-permission-system/config.json`. It feels like stock pi — reads, file tools, skills, ctx tools, and normal shell commands all flow without prompts — with rails only where it matters:

- `.env*` and `~/.ssh/*` unreadable by every tool (`path` deny, cross-cutting)
- `rm -rf` denied; any other `rm`/`sudo` asks
- everything else allowed

Your live config is **yours**: it's gitignored here, and edits via pi's permission modal stay local. The repo copy stays a clean, friendly default for fresh installs.

## Layout

```
AGENTS.md            operating instructions (symlinked to ~/.pi/agent)
settings.json        provider + packages
configs/             permission default (public)
skills/              12 curated skills
agents/              subagent role prompts
extensions/          local TS extensions
install.sh           fresh-machine bootstrap
sync.sh              save drift back to GitHub
```

## Backup

`sync.sh` commits and pushes local drift. Memory and session data live outside this repo by design.
