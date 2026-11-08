---
name: prd
description: Create, update, or complete a Product Requirements Document in docs/backlog/. Use when user says "create prd", "new prd", "write prd", "update prd", "amend prd", "complete prd", or wants to define a feature before implementation.
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion
---

# PRD

Manage PRDs through their lifecycle: create, amend, complete.

## Before starting

Read the source-of-truth process:

1. `~/notes-vault/1775216770-prd-lifecycle-management.md` for lifecycle, statuses, readiness, grilling, amendments vs deviations
2. `~/notes-vault/templates/product-requirements-document-template.md` for the template

## Determine the action

- **"create/new/write"** → Create mode
- **"update/amend"** → Amend mode
- **"complete/close/finish"** → Complete mode
- Ambiguous → ask

## Writing rules

These apply to every mode: PRD bodies, amendment rows, deviation notes, and the
drafts presented for approval.

- **Plain English.** Short sentences, ordinary words. Say the thing directly.
- **Concise.** Cut anything that does not change what the reader understands.
- **No em-dashes.** Use a period, comma, colon, or parentheses. Avoid en-dashes
  in ranges too (write "1 to 3", not a dash).

---

## Create mode

1. Read the vault notes above.
2. Understand the feature: relevant code, existing PRDs in `docs/backlog/`, user context.
3. Draft the PRD from the template. Search the codebase to populate the Changes table with real paths. Make goals measurable. Populate Open Questions. Be explicit about Out of Scope. Set Mode (supervised or unattended; ask if unclear). Write one acceptance criterion per goal, each with the command that proves it.
4. Present the full draft as text in the response. **STOP, end the turn.** Do not write any file yet.
5. Only after the user explicitly approves, save to `docs/backlog/<feature-name>.md`. If they request changes, revise and re-present. Still no file until approval.
6. Suggest `/grill-me` before implementation.

### Create rules

- One deliverable per PRD. Split and link via Depends on / Blocks.
- Kebab-case filename, no `-prd` suffix.
- Status starts as `Draft`.
- Check existing PRDs for dependency links.
- **No code blocks in the body.** PRDs capture *what* and *why*. Describe types as field tables, not code. Exception: a tiny inline literal (e.g. `YYYY-MM-DD`) is fine.
- **State the chosen design, not what was rejected.** Each Design Decision is a positive statement. No considered-and-rejected alternatives.
- **No phantom Out of Scope / Open Questions.** List only items raised or genuinely adjacent; never items the user already declined.
- **Every acceptance criterion carries a command.** "WHEN [event] THE SYSTEM SHALL [observable behaviour]", plus the test, request or query that proves it. A vague quality ("fast") gets a threshold or stops being a criterion.
- **Keep the template's line** saying named tests may not be edited, weakened or deleted.
- **Build the Changes table by searching, not by recall.** For every file it
  names, search for everything that calls, reads, applies or ships that file,
  and list them all. A table written from reasoning looks exactly like one
  written from a search, and nobody downstream can tell them apart.

---

## Amend mode

1. Find the PRD in `docs/backlog/` (ask if multiple match).
2. Read it.
3. Ask what changed and why (if not explained).
4. Append a row to the Amendments table. Create it if missing:

   | Date | Change | Reason |
   |------|--------|--------|
   | YYYY-MM-DD | What changed | Why |

5. Update status if needed (e.g., `Draft` → `In Progress`).
6. Update the `Updated` date.

### Amend rules

- Don't edit existing sections, only append to Amendments.
- If the change needs design thinking, suggest a new PRD instead.
- On an unattended PRD, an amendment means the grilling missed something. Say so when appending. Mid-run questions belong in Blocked, not here.

---

## Complete mode

1. Find the PRD.
2. Read it.
3. Compare plan vs result. Goals met? Design changed?
4. Set status to `Complete` with `Completed: YYYY-MM-DD`.
5. Add a Deviations section only if implementation diverged significantly.
6. Move to `docs/backlog/archive/` (the archive holds all closed PRDs:
   Complete, Superseded, Abandoned; the Status field says which).
7. Confirm changes before writing.

### Complete rules

- Don't edit the body, only Deviations and status.
- Deviations are for architectural pivots, not implementation details.

---

## Unattended runs

Mode unattended means nobody is available to ask. The PRD carries the standing
instruction: anything undecided that blocks a criterion stops the work and goes
under `## Blocked`. Never improvise.

## Readiness checklist

1. Can it be built without further questions? (Open Questions and Not yet specified both empty)
2. Are all steps and flows defined?
3. Are failure cases and edge cases covered?
4. Does every acceptance criterion have a command that proves it?
5. Are goals measurable?
6. Is Mode set, and for unattended: is every failure path decided?

### Enumeration

Designs get grilled well. What slips through is counting. Answer each of these
by searching the repo, not by reasoning about it.

7. Is every caller of every file in the Changes table listed, found by search?
   That includes pipelines and scripts, not just application code.
8. For each config value the design adds or reads, are all of its states
   covered, including what its delivery mechanism produces when it fails?
9. For each rule that applies to some environments only, is the thing that
   decides the environment named, and does that thing actually control the
   outcome?
10. Does every claim that the change has no effect somewhere have a check
    proving it?

If any fail, the PRD is not ready to leave Draft.
