---
name: pi-settings
description: Configure pi's own settings.json and audit skill-link leakage - skill isolation from the shared ~/.agents/skills hub, subagent model routing and fallbacks, memory location, packages, and extensions. Use when the user wants pi to keep its skills separate from Claude Code/Codex, says "pi should not load synced skills", asks to check or remove skill symlinks, asks to change subagent models or fallbacks, or edits ~/.pi/agent/settings.json.
---

# pi-settings

## Always run the audit first

```bash
~/pi-setup-public/skills/pi-settings/audit-links.sh          # report
~/pi-setup-public/skills/pi-settings/audit-links.sh --fix    # sever leaks into copies
```

It lists every `~/.agents/skills` entry that symlinks back into `pi-setup` and
confirms the hub exclusion is still in `settings.json`. Report before fixing;
`--fix` replaces links with real copies, which makes Claude Code and Codex drift
from pi-setup on every later edit. Ask before running it.

## Layout

`pi-setup-public` is the public repo (github.com/cskwork/pi-setup-public). pi points at
it through symlinks, so a `git pull` updates a live install:

| pi path | → | repo path |
|---|---|---|
| `~/.pi/agent/settings.json` | → | `pi-setup/settings.json` |
| `~/.pi/agent/skills` | → | `pi-setup/skills` |
Memory (`MEMORY.md`, `daily/`) stays in `~/.pi/agent/memory` and is NEVER
synced to this public repo. If you fork with private content, make your fork
private and keep `.gitignore` excluding anything confidential.

Back up before every settings write:
`cp settings.json settings.json.bak-$(date +%Y%m%d-%H%M%S)`, then validate with
`python3 -c "import json;json.load(open('settings.json'))"`.

## Skill isolation (pi separate from the shared hub)

pi auto-discovers skills from four roots (`package-manager.js:1960-2019`):

| root | shared with other agents? |
|---|---|
| `~/.pi/agent/skills/` | no — pi-only |
| `~/.agents/skills/` | **yes** — sync-skill's canonical hub |
| `.pi/skills/` (project) | no |
| `.agents/skills/` (project, trusted) | yes |

`sync-skill` symlinks every skill into `~/.agents/skills`, so pi inherits all of
them. To keep pi on its own set, exclude the hub in settings:

```json
{ "skills": ["!~/.agents/skills/**"] }
```

`!` excludes, `+path` force-includes one back, `-path` force-excludes
(`isEnabledByOverrides`, package-manager.js:519). Force-include beats exclude;
force-exclude beats everything.

Keep one hub skill:
```json
{ "skills": ["!~/.agents/skills/**", "+~/.agents/skills/<one-shared-skill>"] }
```

Verify the count actually changed — never assume:
```bash
cd /tmp && pi -p --no-session "reply with only the number of skills listed in your available_skills block"
```

Skills that should stay pi-only (this one included) go in `~/.pi/agent/skills/`
and must **not** be symlinked into `~/.agents/skills` by sync-skill.

## Subagent model routing

`subagents.agentOverrides.<name>`: `model`, `thinking`, `fallbackModels`,
`skills`, `tools`. Fallback fires only on provider failures — rate limit,
overload, auth, unavailable — not on ordinary task failure.

```json
{ "subagents": { "agentOverrides": {
  "coder": { "model": "openai-codex/gpt-5.6-luna", "thinking": "max",
             "fallbackModels": ["anthropic/claude-opus-5"] } } } }
```

Get exact ids from `subagent({action:"models"})`; bare ids resolve only when unique.

`fast: true` (OpenAI priority tier) validates the **whole** candidate list
against an allowlist of `openai-codex/gpt-5.6-luna` and `openai-codex/gpt-5.6-sol`
(`pi-subagents/src/runs/shared/pi-args.ts:269`). One non-codex fallback and
preflight throws. Fast mode and cross-provider fallback are mutually exclusive.

## Other keys

`packages` (npm resources), `extensions` (local paths, same `!/+/-` patterns),
`defaultModel`, `defaultThinkingLevel`, `theme`, `tuiMode`, `defaultProjectTrust`.
Interactive editor: `pi config` (`-l` for project scope).

Runtime overrides, no config edit: `--no-skills`, `--skill <path>`,
`--no-extensions`, `--no-context-files`.
