# pi-setup

My [pi coding agent](https://github.com/earendil-works/pi-coding-agent) setup, kept simple.
One repo = the whole setup. Clone, run `install.sh`, done.

## What's in here

| Path | What it is |
|---|---|
| `settings.json` | Default model **zai / glm-5.3** (thinking: max), theme, installed packages |
| `AGENTS.md` | My operating instructions (domain-first, options gate, 8-step flow) |
| `extensions/` | Local TypeScript extensions |
| `agents/` | 13 custom subagents (planner, researcher, reviewer, tester, …) |
| `skills/` | 47 skills (tdd, review, security-review, frontend-design, worktree, …) |
| `install.sh` | Restores everything on a new machine |
| `sync.sh` | Commits + pushes any drift |

### Installed pi packages (auto-installed by `install.sh`)

| Package | What it gives |
|---|---|
| `pi-subagents` | subagent spawning & workflows |
| `pi-web-access` | web search & fetch |
| `@juicesharp/rpiv-ask-user-question` | structured user questions |
| `@juicesharp/rpiv-todo` | todo tool |
| `context-mode` | context-saving sandbox (ctx_execute / ctx_search) |
| `pi-mcp-adapter` | MCP server support (`/mcp` command, imports `.mcp.json`) |
| `pi-background-tasks` | background task management |
| `@gotgenes/pi-permission-system` | permission gates — config in `extensions/pi-permission-system/config.json` |
| `pi-simplify` | code simplification skill |
| `pi-markdown-preview` | render Markdown → PDF/HTML/PNG |
| `pi-powerline-footer` | status footer |
| `@samfp/pi-memory` (ai-memory) | wiki memory, session handoffs |
| `glm-vision` | image reading via GLM-4.6V |

### Local extensions (`extensions/`)

`ai-memory-pi.ts` · `dirty-repo-guard.ts` · `herdr-agent-state.ts` · `permission-gate.ts` · `superset-hooks.ts`

## New machine

```bash
git clone https://github.com/cskwork/pi-setup.git ~/pi-setup
cd ~/pi-setup && ./install.sh
pi auth        # zai / anthropic / openai-codex — secrets never leave the machine
# restart pi
```

## How syncing works

`install.sh` **symlinks** `~/.pi/agent/{AGENTS.md, settings.json, extensions, agents, skills}`
to this repo, so the repo is the single source of truth.

- Changed something in pi (settings, a skill, an agent)? → `./sync.sh`
- New machine? → clone + `./install.sh`
- `pi install <pkg>` edits `settings.json` → flows into the repo → `./sync.sh`

## Not synced (on purpose)

- `auth.json` — provider tokens. Run `pi auth` per machine.
- `sessions/`, `run-history.jsonl`, `npm/` — machine-local state.
- ai-memory wiki — per-project, lives inside each project.
- `~/.agents/skills/` — the 198-skill shared hub for all agents; separate concern.
