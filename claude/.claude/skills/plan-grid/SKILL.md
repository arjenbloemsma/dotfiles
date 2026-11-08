---
name: plan-grid
description: Generate a Cal Newport time-block grid for the day. Use when user says "plan grid", "time blocks", "block the day", "grid", or similar.
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep
---

# Plan Grid

Generate a text-based Cal Newport time-block grid that the user can transfer to
pen and paper. See [Cal Newport Time-Block Planning](~/notes-vault/1770972640-cal-newport-time-block-planning.md)
for the method.

## Steps

1. **Read today's daily note** at `~/notes-vault/dailies/{today}.md`
   - Extract The Three
   - Extract todo items

2. **Ask user for**:
   - Work hours (default: 8:00 to 16:30)
   - Fixed commitments (meetings, calls, appointments, with times)
   - Any personal blocks (run, errand, etc.)
   - Energy preference: when is deep focus best? (default: morning)

3. **Build the grid** following these principles:
   - Block The Three first, with a 90+ min deep work block for each
   - Place deep work in the user's peak energy window
   - Shade fixed commitments (`░░░`)
   - Batch shallow tasks (email, Teams, admin) into 1-2 dedicated blocks
   - Include transitions (5-10 min) between blocks
   - Schedule breaks explicitly
   - Add overflow conditionals where duration is uncertain
   - Leave a notes/collection column on the right

4. **Output the grid** in monospace text format:

```
       SCHEDULE              NOTES / COLLECTION
       ──────────────       ──────────────────────
 8:00 │ Deep work:    │    │
      │ [task]        │    │
 9:00 │               │    │
      ├──────────────┤    │
 9:30 │ Break         │    │
      ├──────────────┤    │
10:00 │░░░░░░░░░░░░░░│    │
      │░ [meeting]  ░░│    │
10:30 │░░░░░░░░░░░░░░│    │
      ├──────────────┤    │
...
```

5. **Present to user**: ask if adjustments are needed before they draw it

## Important

- This is a *starting point* for pen and paper. Keep it clean and simple
- Don't overcrowd; leave room for re-blocking columns
- Every minute gets assigned, no unplanned gaps
- Be realistic about duration and err on the generous side
- Never drop a task from the daily note without asking. If it won't fit,
  ask whether to defer, shorten, or swap. Surface trade-offs; don't decide
