---
name: end-day
description: Full Cal Newport shutdown ritual. Review tasks, process loose ends, carry forward, sketch tomorrow, close the day. Use when user says "end day", "shutdown", "wrap up the day", "close the day", or similar.
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent
---

# End Day: Shutdown Ritual

Full end-of-day process based on Cal Newport's shutdown ritual and the
[Daily Note Processing Workflow](~/notes-vault/1770971587-daily-note-processing-workflow.md).

## Steps

1. **Read today's note** at `~/notes-vault/dailies/{today}.md`

2. **Review task list**: present a status summary
   - How many tasks done `[x]`, ongoing `[>]`, pending `[ ]`, blocked `[!]`, needs attention `[~]`
   - Highlight anything still `[ ]` pending and ask the user to update its status (done? ongoing? blocked?)

3. **Process loose ends**:
   - Check for any notes/observations in today's note that need action
   - Ask if there are items from the paper grid's collection column to capture

4. **Check upcoming calendar**: remind the user to scan the next 2-3 days for anything needing prep.
   This is a manual check; just prompt the user.

5. **Carry forward unfinished tasks**:
   - Identify `[>]` ongoing, `[~]` needs attention, `[!]` blocked items
   - Present to user; ask which should carry forward and to which date
   - Ask if any status should change
   - If the target day's note doesn't exist, create it from template
   - Only label tasks "(carried from YYYY-MM-DD)" if they were untouched/postponed
   - Tasks that saw active progress today are ongoing; add them to tomorrow without the carried label

6. **Update feature progress files**:
   - Check if any tasks relate to tracked features (look for progress `.md` files in project folders)
   - If found, ask user if `← RESUME HERE` markers need updating

7. **Review for zettelkasten insights**: delegate to the `note-reviewer` agent
   - Pass it the path of today's note (`~/notes-vault/dailies/{today}.md`)
     and let it scan for permanent-note-worthy insights
   - Present suggestions to user and create any approved permanent notes
   - The user may have already created permanent notes earlier in the day.
     Frame this step as "any *additional* insights to extract?" not "no notes needed"

8. **Sketch tomorrow**: rough plan for the next workday
   - Ask user for tomorrow's **Three**, the three most important/impactful tasks
   - Any fixed commitments/meetings to plan around?
   - What deep work blocks are planned?
   - Add The Three to tomorrow's note (created in step 5 if needed)

9. **Mark today's note**: set `processed: true` in frontmatter

10. **Shutdown complete**: confirm everything is captured and say:
    > "Schedule shutdown, complete."

## Important

- Don't rush; walk through each step with the user
- Don't carry `[x]` done items
- Don't automatically carry everything; let user decide
- Don't update weekly notes; they're high-level only
- Follow zettelkasten conventions in `~/notes-vault/1764149776-zettelkasten-approach.md`
- Always check `~/notes-vault/templates/` before creating notes
- Use task statuses: `[ ]` pending, `[x]` done, `[>]` ongoing, `[~]` needs attention, `[!]` blocked
