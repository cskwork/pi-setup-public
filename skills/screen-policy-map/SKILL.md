---
name: screen-policy-map
description: Build an evidence-backed screen policy map as a single self-contained HTML explorer with a left menu tree and a right detail pane. Use when a user asks to document, compare, or explain what a UI screen shows, which API each module calls, and whether that data is live or batch. Triggers include "화면 정책 정리", "screen policy", "메뉴별 API 정리", "이 화면 어디서 데이터 오는지", comparing two roles' screens (teacher vs student, admin vs user), or auditing which modules exist on one screen but not another.
---

# Screen policy map

Turn a running screen into a policy document that a reviewer can trust: every module
named, every API traced, every data source classified live or batch, every claim
carrying a `file:line`.

The output is one self-contained HTML file. Left is a menu tree that mirrors the real
navigation. Right is the detail. Clicking a tree node lights its target on the right.

## When to use

Use when someone needs to know **what a screen shows and where that data comes from**:

- documenting an existing screen's modules and their APIs
- comparing the same feature across two roles (teacher vs student, admin vs user)
- finding which modules exist for one role but not another, and why
- auditing whether a value is real-time or a nightly snapshot
- explaining a data-freshness bug to people who did not write the code

Do not use for: designing a new screen (that is a design task), pure API reference
docs with no screen, or a one-paragraph answer.

## Non-negotiable rule

**Every factual claim carries a `file:line`. No claim survives without one.**

A screen policy map is only worth building if a reviewer can check it. If you cannot
find the evidence, write "미확인" and say what you did not check. Never infer an API
from a name, never guess a table from a DTO field, never assume two similar screens
share a query.

Label inference explicitly as `추정` and say what would confirm it.

## Process

### 1. Anchor on the real screen

Get the URL or the route. Find the root component. From the root, read outward:
child components, the API module it imports, the router entry.

Do not start from the API layer. Starting from the backend makes you document
endpoints that no screen calls.

### 2. Extract the module list from the template

Read the template, not the script. Section comments and visible labels are the
module names your reader will recognize. Quote them verbatim.

Record for each module: its label, its component, and any `v-if` / conditional that
decides whether it renders.

### 3. Trace each module to its API

For each module, follow: component → API function → endpoint path → controller →
service → mapper/query.

Record the endpoint string exactly as written in the API module. A module often
calls **more than one** endpoint, and the parts of one visual section can come from
different endpoints. That split is usually the most valuable finding in the document.

### 4. Classify each data source

For every endpoint, answer one question: **does this read live tables or a
precomputed snapshot?**

Grep the mapper for the snapshot table name. Zero references is a finding worth
stating outright. If a snapshot exists, find:

- which batch job writes it, and its ID
- whether a fallback to live aggregation exists, and its exact trigger condition
- what happens when the batch stops but stale rows remain

That last case is the classic silent failure: a fallback that only fires on zero
rows will serve stale data forever without a signal.

### 5. Identify the driving table

For each query, name the `FROM` clause's driving table and the join direction.

This single fact explains most "missing rows" bugs. A query driven by a snapshot
table loses rows for any subject the batch skipped. The same query driven by the
canonical entity table keeps the rows and merely leaves the metrics null.

When two roles' screens differ, compare their driving tables first.

### 6. Build the role comparison

Put every module in one table with a column per role. Mark each as shared,
role-A-only, or role-B-only.

For every asymmetric module, find the code reason. Acceptable reasons are:
a permission check, a missing endpoint, a privacy boundary, a conditional render.
"Probably not needed" is not a reason; keep looking or mark it 미확인.

### 7. Render

Copy `assets/template.html` and fill it. See `reference/build-html.md` for the
structure, the theming contract, and the interaction rules.

### 8. Verify before claiming done

Serve the file over HTTP and check it in a browser. `file://` is blocked in some
sandboxes; `python3 -m http.server` avoids that.

Confirm, in one batched round:

- every tree link resolves to a real element id
- no horizontal overflow at wide and narrow widths
- both themes render, and body text color is identical in lit and unlit regions
- the highlight fires for section-level and row-level targets

`reference/verify.md` carries the probe snippets.

## Output shape

One HTML file. Sections in this order:

1. **개요** — where each screen lives, module comparison table, data-origin diagram
2. **역할별 상세** — one section per role, one subsection per module
3. **기반** — batch jobs, legacy remnants, empty-response conditions
4. **확인 / 미확인** — what you verified and what you did not

Put the module comparison table early. It is the fastest thing a reviewer wants.

## Language

Write for the reader who did not write the code.

- One idea per sentence. Short sentences. Active voice.
- Use the project's own terms. If code and glossary disagree, flag it.
- Name behavior, not file names, in headings.
- Numbers need their measurement: "4,412 pair out of 64,035" beats "many".

## Domain packs

Project-specific conventions live in `reference/domain/<project>.md` and stay local.
Read one when the target project has a pack. Never commit domain packs.
