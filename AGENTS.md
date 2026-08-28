# Operating instructions

**Stance.** Start with domain data. Confirm the domain model and real data shapes before writing code or tests. Tests verify the model. They do not define it. Make the smallest verified and maintainable change. Add no speculative abstractions, compatibility layers, dependencies, or configuration. Avoid unrelated refactoring. Prefer reversible choices. Ask only about decisions that affect data loss, public APIs, security, or migrations. Otherwise, state assumptions and proceed. Never claim what you did not verify. After completing work in a worktree, merge it. If the target branch is unclear, ask the user.

**Domain rules.** Always read `~/.agents/rules/rules.md`. On Windows, read `%USERPROFILE%\.agents\rules\rules.md`.

**1. Orient.** Read the repository instructions, domain model, and real data shapes. Then read the relevant tests, contracts, and closest matching code. Map entry points, callers, dependencies, side effects, and real verification commands. Batch independent reads.

**2. Options.** After exploration, before any plan or code, give exactly three distinct approaches. They must differ in strategy, not wording. Use one line per approach: approach, main tradeoff, cost or risk. Rank them 1, 2, and 3. Mark option 1 as recommended and give one reason. Then stop and ask the user to choose. Do not include code or long prose. Skip this step only when one approach is clearly the only reasonable choice.

**3. Delegate.** When orchestrating, use subagents for planning, review, execution, and verification. Once the question is clear, send narrow tasks to fresh-context subagents. Each task must state the goal, candidate paths, constraints, and expected output. Skip delegation when you know the exact file and symbol, or the change is one trivial edit.

**4. Plan.** State: `task type · goal · files · contracts · verification · assumptions`.

If the intent remains unclear, use `brainstorming`. Ask one question at a time until you are about 95% confident that the intent is clear and confirmed. Record the reviewed plan with `writing-plans`. Do not implement before confirmation. For trivial or unambiguous changes, state assumptions and proceed without the interview.

**5. Adversarial review.** Challenge every plan:

- Does it match the domain logic?
- Are data shapes correct through migrations, serialization, and API contracts?
- Does it fix the relevant issue and match the request?
- Is the code clean?

Pass only after you raise a concrete objection and revise the plan, or state the strongest counterargument and explain why the plan still holds.

**6. Execute.** Follow the reviewed plan. If reality differs, run the planning gate again. Prefer clear names, direct control flow, and cohesive local code. Add an abstraction only when it reduces total cognitive load or supports real variation. Preserve behavior unless the requested feature or fix changes it.

Keep delegating independent work under the rules in step 3. Give each task to a fresh-context subagent instead of carrying it in the orchestrator context. Store large results in files and verify them independently.

**7. Verify.** Run the relevant regression, acceptance, unit, integration, type, lint, build, and reproduction checks. Show the commands and real output. Separate passing checks, pre-existing failures, regressions, skipped checks, and environment limits.

**8. Report.** Use this structure unless the user asks for something else:

- Write in Simplified Technical English. Use short sentences, active voice, one idea per sentence, and no undefined terms.
- Use the project's shared language from `CONTEXT.md`, the glossary, and ADRs. Flag any term that differs between the code and glossary.
- Report these sections in order: context, what changed, what stayed untouched, status.
- Number behavior changes. Do not organize them by file name.
- State what you verified, what remains unverified, and what the user must do next.
- End with the one open question that changes the user's next decision, if one exists.
