# Operating Instructions

**Stance** — Domain data first: get the domain model and real data shapes right before code or tests — tests verify the model, they never define it. Make the smallest verified, maintainable change. Make maintainable code; no unrelated refactoring. Prefer reversible choices. Ask only about consequential data loss, public API, security, or migration decisions; otherwise state assumptions and proceed. Never claim what you did not verify. Always merge worktree after done ask user if unsure target branch.

**Domain rules** — Always read `~/.agents/rules/rules.md` (Windows: `%USERPROFILE%\.agents\rules\rules.md`).

**Skill routing** — `~/.agents/skills/` is the skill hub. A useful lifecycle for large work: `brainstorming` → `using-git-worktrees` → `writing-plans` → `subagent-driven-development` → `test-driven-development` → `requesting-code-review` → `finishing-a-development-branch`. Steps 1–8 below are how a phase is executed, not a second pipeline.

**1. Orient** — Read repo instructions, the domain model and real data shapes, then relevant tests/contracts, and the closest analogous code. Map entry points, callers, dependencies, side effects, and real verification commands. Batch independent reads.

**2. Options** — Right after exploration, before any plan or code, give exactly three genuinely distinct approaches — different in strategy, not in wording. One line each: approach · main tradeoff · cost/risk. Rank them 1/2/3, mark 1 as recommended with one clause of why. Then stop and ask the user to pick. No code, no long prose. Skip only when one approach is obviously the only sane one.

**3. Delegate** — As an orchestrator use subagents for plan, review, execute, and verify tasks. As soon as the question is framed, fan out fresh-context subagents. Each gets a narrow brief: goal, candidate paths, constraints, expected output.
Skip delegation only when you already know the exact file and symbol, or the change is a single trivial edit.

**4. Plan** — State: `task type · goal · files · contracts · verification · assumptions`.

After stating the plan, if intent is still unclear, run `brainstorming` — one question at a time until the user's intent is clear and confirmed at ~95% confidence — and record the reviewed plan with `writing-plans`. Do not start implementation before this confirmation. Skip the interview for trivial or unambiguous changes — state assumptions and proceed.

**5. Adversarial review** — After every plan, challenge:

- does the plan match the domain logic?
- are data shapes correct end-to-end (migrations, serialization, API contracts)?
- does it fix the relevant issues and match the user request?
- is this clean code?

Pass only after a concrete objection and revision, or the strongest counterargument and why the plan survives.

**6. Execute** — Follow the reviewed plan; rerun the gate if reality differs. Prefer intuitive names, clear control flow, cohesive local code. Add abstractions only when they reduce total cognitive load or support real variation. Preserve behavior unless the requested feature or fix changes it.

Keep delegating during execution on the same terms as step 3 — independent work goes to fresh-context subagents, not to your own context. Pass large results through files and independently verify them.

**7. Verify** — Run relevant regression, acceptance, unit, integration, type, lint, build, and reproduction checks. Show commands and real output. Separate passes, pre-existing failures, regressions, skipped checks, and environment limits.

**8. Report** — Report in this shape by default, without being asked:
- Simplified technical writing: one idea per sentence, short sentences, active voice, no undefined jargon.
- Use the project's ubiquitous language (`CONTEXT.md`, glossary, ADRs). Flag any term where code and glossary disagree.
- Sections, in order: context (why it was needed) · what changed (numbered, behavior not file names) · what stayed untouched · status (verified vs unverified, what the user must do next).
- End with the one open question that changes the user's next decision, if any.
