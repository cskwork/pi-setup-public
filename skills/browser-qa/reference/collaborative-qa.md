# Collaborative QA

Use when the user wants to inspect a product together against a ticket, Figma,
other specification, or real data. Follow the user's selected browser and tools;
reuse browser/domain/DB skills instead of duplicating their setup instructions.
Browser data migration is a separate task, not a QA prerequisite.

## Working agreement

The user may navigate while the agent observes and explains. Inspect the current
screen before asking the user to describe it. Re-observe after user actions;
never infer the active account, environment, filter, or tab from an earlier turn.
Do not compete with user input. Respect tool control interruptions and handoffs.
Ask only for missing context that changes the work and cannot be observed.

## Loop

1. Read the ticket and relevant specification sections. Cover every applicable
   view (such as overall and chapter), annotations, tooltips, exception rules,
   exports, and units. Record source links/node IDs and observed revision/date.
   Mockup numbers are examples, not expected values for the live account.
2. Confirm the visible environment, account/role, course or equivalent scope,
   filter, build label, and data update time. Identify useful existing test data
   with read-only queries when needed. Verify DB environment using the domain
   skill; do not create or change fixtures without authorization.
3. Maintain a requirement matrix: source, rule, expected behavior, observed
   behavior, evidence, and status. Include null versus zero, rounding boundaries,
   unit conversion, all-empty values, completed versus assigned counts, filtered
   scope versus current page, and export behavior when applicable.
4. Observe the live screen; change one meaningful condition and compare both
   summary and details. For suspect numbers, trace UI -> API when available ->
   aggregate data -> source results. Record independent calculations and timestamps.
   A correct mean of stale inputs does not establish correct results. Multiple
   sessions, redeployment, deletion, and completion rules must be resolved before
   selecting a source result. Do not run refresh batches merely to erase a symptom.
5. Classify each finding: **confirmed bug**, **specification conflict/question**,
   **data discrepancy requiring investigation**, or **unverified**. Separate
   observations from causes and conditional expectations. Never resolve conflicting
   specification sections silently; continue independent checks while clarification
   remains pending.
6. Update one Markdown report immediately as findings evolve. Correct superseded
   expectations and stale status in place; retain a short dated correction note
   when it explains the change. Do not leave contradictory verdicts in appendices.
7. When asked “where?” or “show me”, open the exact source node/section in the
   selected app, zoom and pan until the passage is visibly readable, then stop.
   A link or accessibility text alone does not satisfy a request to show the screen.
8. Finish the agreed scope or identify the concrete handoff/blocker. Report new
   findings, remaining coverage, and the report path. Do not imply continued
   background work after ending a turn.

## Evidence and boundaries

Keep credentials, tokens, and real student/customer personal data out of reusable
skills and shared reports. Keep account bindings in local site configuration;
use minimal synthetic test identifiers in evidence only when needed. Distinguish
source event time, aggregate row time, screen update label, build and deployment.
Record missing API bodies or screenshots explicitly; never fabricate them.
Code inspection and reading tests are not runtime verification or test execution.
Do not modify product code/data, publish comments, or deploy under a QA-only task.

## Report template

```markdown
# <ticket or feature> collaborative QA

## Current findings
| ID | Finding | Classification | Requested next action |
|---|---|---|---|

## Scope and evidence
- Date/time and environment verification:
- Screen and minimal test context:
- Specification links/revision:
- Build/data timestamps; unknowns:

## Findings
### <stable ID and title>
- Reproduction:
- Specification and expected behavior:
- Observed behavior:
- UI/API/DB evidence and independent calculation:
- Confirmed facts versus unresolved cause/policy:
- Verification after correction:

## Coverage
| Rule | Source | Expected | Observed | Evidence | Status |
|---|---|---|---|---|---|

## Unverified checks and handoffs

## Corrections
```

Use the project evidence directory when defined; otherwise use a local report
folder. A reviewable Markdown report is the deliverable for this mode. SuperQA
YAML, a replay run, and HTML are optional follow-up work, not prerequisites for
observing a screen together. Existing automated modes retain their contracts.
