# pi-setup

My [pi coding agent](https://github.com/badlogic/pi-mono) configuration: skills, extensions, agents, and a permission policy that only stops the commands that can destroy something. One command restores it on a new machine.

**Landing page:** https://cskwork.github.io/pi-setup-public/ (public repo) · **한국어:** [README.ko.md](README.ko.md)

## Quick start

### macOS, Linux, or Git Bash

```bash
git clone https://github.com/cskwork/pi-setup-public.git ~/pi-setup-public
~/pi-setup-public/install.sh
pi auth                      # OAuth providers (anthropic, openai-codex, amazon-bedrock)
$EDITOR ~/.pi-setup.env      # API-key providers, e.g. ZAI_API_KEY=...
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
pi auth                      # OAuth providers (anthropic, openai-codex, amazon-bedrock)
notepad $HOME\.pi-setup.env  # API-key providers, e.g. ZAI_API_KEY=...
# reopen PowerShell, then restart pi
```

The installers link `~/.pi/agent/{AGENTS.md, settings.json, extensions, agents, skills}` into this repo, install every package below, and deploy the default permission config. They back up existing files instead of overwriting them. On macOS, `install.sh` also watches `settings.json` and `~/.pi/acp.json`: it copies valid live changes into this repo and restores the symlinks if Pi replaces them during an atomic write.

They also add a managed shell-profile block that gives only Pi an 8 GiB V8 heap. Other Node processes keep their defaults, the block preserves any `NODE_OPTIONS` you already set, and it resolves the active NVM/npm Pi executable on every call. Re-run the installer after moving the checkout. Remove the block between the `pi-setup Pi-only Node heap` markers to uninstall it. If you use both Windows PowerShell 5.1 and PowerShell 7, run `install.ps1` once in each. Organization-enforced policies can still block PowerShell profiles; those require an administrator policy change.

### Provider credentials

Pi registers a provider only when that provider's documented environment variable is set. A model routed in `settings.json` whose provider never registers makes every subagent launch print `[pi-subagents] Skipping fallback model '<id>' because it is unavailable in this environment.`

So the installers create `~/.pi-setup.env` (mode `600`) from the tracked `.env.example`, and add a second managed profile block that sources `scripts/pi-env.sh` before Pi runs. That loader:

- reads `~/.pi-setup.env` as **defaults only**. An already-exported variable always wins, so `ZAI_API_KEY=... pi ...` and CI secrets still override it;
- mirrors `ZAI_API_KEY` and `Z_AI_API_KEY` in both directions, because Pi reads the first name and the Z.ai Vision MCP server reads the second. Store the key once under either name.

The live secret file sits **outside** the repository, so it cannot be committed or reach the public mirror. Override its path with `PI_SETUP_ENV_FILE`.

**A missing key is not an error.** pi-subagents warns once per launch for every model whose provider is not registered, and it has no setting to mute that. So for a provider routed in `settings.json` with no key, the loader exports an `unset-placeholder` value. That registers the provider and silences the warning; the credential is then wrong, but that path is already quiet. Pi tries the model and the call fails with a clear provider error; pi-subagents no longer switches models inside a launch. A real key always overrides the placeholder, including when you re-source the profile in the same shell. Set `PI_SETUP_NO_PLACEHOLDER=1` to opt out and see the warnings.

**Project settings can break pi-subagents too.** A project-level `.pi/settings.json` with its own `agentOverrides` is read as well, and one `fallbackModels` entry there stops the extension from loading in that directory. Run `scripts/check-removed-fields.sh /path/to/project/.pi/settings.json` to check a project; the installer and CI check this repo's files automatically.

**Anthropic requests must not hang.** The loader also defaults `PI_BG_FEATURES` to `process,delegate,fusion,attested`, leaving out pi-background-tasks' `attribution` feature. Version 2.6.2 of that package replaces Pi's Anthropic provider, and its message converter loops forever on the system messages Pi 0.86+ keeps in the transcript, so every Claude request sat at 100% CPU with no output. Pi's built-in provider handles subscription OAuth on its own. Export your own `PI_BG_FEATURES` to override, and add `attribution` back once the package is fixed.

At the end of a run the installer lists every provider routed in `settings.json` that has no credential. That list is information, not a problem. Remove the block between the `pi-setup provider env` markers to uninstall the loader.

The default model is `openai-codex/gpt-6.1-sol` at thinking `high`, with Fast mode. Backend, simple work, browser automation, and QA use Sol high/Fast. UI, frontend, document writing, architecture, and difficult debugging use Opus 5.5 at medium reasoning. Model substitutions require owner approval. Explicit GLM roles remain available.

The macOS watcher keeps Pi's mutable JSON config in the local checkout. Run `~/pi-setup-public/sync.sh` when you want to commit and push the checkout.

## What's inside

### Skills (23)

| Skill | What it does | Source |
|---|---|---|
| `agent-browser` | Browser automation CLI for agents | [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) |
| `api-and-interface-design` | Stable API/interface design: contract-first, Hyrum's Law, idempotency-key claiming, consistent error shapes | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) |
| `browser-qa` | Browser QA on anything: YAML DAG scenarios, engine choice (native `agent_browser` tool first), API evidence, `superqa` runtime; Playwright E2E patterns in `reference/e2e-patterns.md` | [cskwork/browser-qa](https://github.com/cskwork/browser-qa) |
| `db-intelligence` | One DB skill, four engines: PostgreSQL, MySQL, SQLite, MongoDB. Credential-safe, read-first, schema-before-SQL; outputs a domain evidence artifact (entity graph + ubiquitous language + data shapes) | local |
| `playwright-cli` | Drive a browser directly; inspect or author Playwright tests | local |
| `verify` | 5-gate verification; refuses "green build = verified" | [cskwork/verify-skill](https://github.com/cskwork/verify-skill) |
| `create-verification-skill` | Generate a project-local skill that drives the real app and captures proof | [cursor/plugins](https://github.com/cursor/plugins/tree/main/pstack/skills/create-verification-skill) |
| `verification-before-completion` | Evidence before assertions. Never call unverified work done | [obra/superpowers](https://github.com/obra/superpowers) |
| `pi-settings` | Audit and configure pi's own settings.json: skill isolation, subagent routing, packages | local |
| `sync-agent-prompt` | Sync the AGENTS.md operating contract and essential skills across pi-setup, pi-setup-public, and the promptbox onboarding prompt; compares per-file changes and preserves approved scope and private/public boundaries | local |
| `diagnosing-bugs` | Diagnosis loop for hard bugs and performance regressions: reproduce → minimise → hypothesise → instrument → fix → regression-test | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `tdd` | Test-driven development: red-green-refactor, integration tests, mocking patterns | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `humanizer` | Default prose editor; preserve facts and remove AI writing patterns | [blader/humanizer](https://github.com/blader/humanizer) |
| `code-review` | Review changes since a fixed point along Standards and Spec axes, in parallel sub-agents | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `implement` | Implement a piece of work based on a spec or tickets | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `research` | Investigate against high-trust primary sources, capture findings as Markdown | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `domain-modeling` | Build and sharpen a project's domain model in CONTEXT.md and ADRs | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `resolving-merge-conflicts` | Resolve an in-progress git merge/rebase conflict | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `grilling` | Stress-tests a plan or decision until it breaks or holds | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `teach` | Teach a skill or concept within the workspace | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `find-skills` | Discover and install new agent skills on demand | local |
| `ego-browser` | Agent-friendly browser sharing logged-in state | [citrolabs/ego-lite](https://github.com/citrolabs/ego-lite) |
| `sdlc-kit` | Four-phase SDLC (intent → plan → build → evidence) with human gates, fresh-context review, and scored, routed proof | [cskwork/sdlc-kit](https://github.com/cskwork/sdlc-kit) |


**Plus [cskwork/skills](https://github.com/cskwork/skills) as a Pi package** (`git:github.com/cskwork/skills` in `settings.json`): call-agent, bughunt, quality-loop, verify-app, retro, prototype, improve-codebase-architecture, design skills (impeccable, diagram-design, gpt-image-2, image-first-ui, mobile-ui-ux, motion-graphics), simless, swiftui-pro, jk, sql-walkthrough, handoff, ponytail, wait-what, and writing-for-agents. `pi update` pulls the latest; `db-intelligence` and `sdlc-kit` load from `skills/` here instead.

### Extensions

Installed via `pi install` (see `settings.json`):

| Package | Purpose |
|---|---|
| `npm:@gotgenes/pi-permission-system` | Pattern-based permissions (see below) |
| `npm:@narumitw/pi-goal` | Session goals, so pi keeps working to completion |
| `npm:@narumitw/pi-usage` | Usage/cost tracking |
| `npm:pi-subagents` | Subagent orchestration |
| `npm:billion-context-pi` | Model-driven context compression; its delegate is disabled, while pi-subagents agents receive ACP tools |
| `npm:pi-lens` | Code feedback while the agent edits: LSP, linters, formatters, type-checks |
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
| `npm:pi-ponytail` | Lazy-senior-dev mode (YAGNI ladder). Skills wired to coder/cleaner; default mode `off`, opt in with `/ponytail` |
| `npm:pi-agent-browser-native` | agent-browser as a native `agent_browser` tool. First pick in browser-qa's engine cascade (requires the upstream `agent-browser` CLI on PATH) |

Plus local extensions in `extensions/`: `dirty-repo-guard.ts` (uncommitted-change guard on session switch) and `herdr-agent-state.ts`. `@gotgenes/pi-permission-system` owns every Bash permission; nothing else writes them.

**Hindsight memory.** `git:github.com/cskwork/pi-hindsight-memory` loads Hindsight's official Pi adapter when [hindsight-agent-setup](https://github.com/cskwork/hindsight-agent-setup) is installed: it recalls past decisions before each turn, saves the conversation after it, and adds the `hindsight_*` tools, sharing one memory with Claude Code and Codex. Without Hindsight it only shows a warning.

### Subagent model profiles (4)

The profiles live in `profiles/pi-subagents/*.json`. Swap model routing for the
shared agent set with `/subagents-load-profile <codex-only|claude-only|mix|glm-max>`:

| Gate | `codex-only` | `claude-only` | `mix` | `glm-max` |
|---|---|---|---|---|
| specifier | sol · high | sonnet-5 · high | opus-5 · high | glm-5.3 · max |
| coder | sol · medium | opus-5 · high | codex sol · high | glm-5.3 · max |
| cleaner | sol · medium | haiku-4-5 · high | sol · medium | glm-5.3 · max |
| sw-architect | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| hardender | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| qa | sol · medium | sonnet-5 · high | glm-5.3-flash · max | glm-5.3-flash · max |

The hardender always gets a top model. It is the only gate that invents its own
checks instead of reading a given artifact, it holds BLOCK authority, and when it
fails it emits a silent `PASS` that no later gate catches.

**Utility agents.** Every profile also routes the non-gate agents on two tiers.
`planner` and `security` get the profile's deep model, because they decide what to
build rather than carry out a plan someone else wrote. `refactorer`,
`doc-writer`, `git-ops`, `javascript-pro`, `typescript-pro`, `delegate`, `scout`,
`researcher`, `reviewer`, `worker`, `tester`, `debugger` get the cheap, fast one.

**No `model:` in agent frontmatter.** pi-subagents resolves frontmatter `model:`
*before* `agentOverrides`, so an agent that pins a model in its `.md` silently
ignores every profile. All `agents/*.md` here ship without a `model:` line on
purpose, and profiles are the one place routing gets decided. Add a pin back only
when an agent must never follow the profile.

This also applies to agents registered by external skills or extensions. If a
startup fails with `Unknown subagent model 'opus'` (or `sonnet`), fix the
external agent prompt: remove its `model:` line or use an exact provider/model
ID. A settings override cannot rescue a frontmatter pin because frontmatter
wins first.

### Skills by default

Every profile sets `agentOverrides.<agent>.skills`, so domain skills load with the
agent instead of per-call wiring:

- **QA/browser tier.** `qa`, `qa-tester`, `qa-auditor`, `agent-browser` get `browser-qa` (+ `agent-browser`, `playwright-cli` where relevant)
- **Persona tier.** `customer-agent`, `persona-product-tester` get `browser-qa` + `agent-browser`
- **Verify/TDD/debug tier.** `verify`, `tester`, `hardender`, `debugger`, `coder` get the verify / tdd / diagnosing-bugs skills
- **Domain-data tier.** `specifier`, `hardender`, `qa` get `db-intelligence` (domain data before code, integrity probes, read-only DB evidence)
- **Minimalism tier.** `coder` gets `ponytail`, `cleaner`/`refactorer` get `ponytail-review`
- **Architecture tier.** `sw-architect` gets `api-and-interface-design` (vendored in `skills/`, so a fresh clone has it). The agent prompt says *what* to review; the skill supplies the reference material: Hyrum's Law, idempotency-key claiming and its TOCTOU trap, error-shape consistency, additive-change rules.

### Permission policy (default)

`configs/permissions.json` deploys as `extensions/pi-permission-system/config.json`. Reads, file tools, skills, ctx tools, and ordinary shell commands run without a prompt, the same as stock pi. Here is the whole policy:

- secret-bearing files (`.env*`, credentials, private keys, application configs, `~/.ssh/*`) denied across tools
- recursive deletion, privilege escalation, disk writes, and destructive Git operations ask
- filesystem-root deletion and disk formatting deny
- normal commands and external directories allow

Your live config is **yours**. It is gitignored here, and edits through pi's permission modal stay local. The repo copy stays the default a fresh install gets.

## Layout

```
AGENTS.md            operating instructions (symlinked to ~/.pi/agent)
settings.json        provider + packages
acp.json             billion-context-pi config
configs/             permission default (public)
skills/              23 agent skills
agents/              subagent role prompts
extensions/          local TS extensions
scripts/             check-docs.py: CI guard for doc/config drift
                     pi-node-heap.sh/.ps1: Pi-only 8 GiB launchers
                     pi-env.sh/.ps1: provider credential loader + key aliasing
                     prune-sessions.sh: session transcript retention
                     sync-live-config.sh: live JSON mirror + symlink repair
                     sync-sdlc-kit-mirror.sh: push skills/sdlc-kit when the clone moves
.env.example         template for ~/.pi-setup.env (the live secret file
                     lives outside this repo and is never committed)
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
before the first prune here). It is local only and never committed to any repo.

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
