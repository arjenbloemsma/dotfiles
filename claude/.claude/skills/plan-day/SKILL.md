---
name: plan-day
description: Morning planning workflow: process yesterday's note, create today's note, set The Three. Use when user says "start today", "plan the day", "morning planning", or similar.
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, Skill
---

# Plan Day

Execute the morning planning workflow from
[Daily Note Processing Workflow](~/notes-vault/1770971587-daily-note-processing-workflow.md).

## Steps

1. **Weekly check**: if today is Monday (or first workday of the week):
   - Invoke the `plan-week` skill via the `Skill` tool
   - It handles: processing previous week's weekly, creating this
     week's from template, and picking goals
   - Continue with daily planning once `plan-week` finishes

2. **Syncthing health check**: delegate to the `syncthing-check` agent
   - If anything is wrong, warn the user before continuing

3. **Check yesterday's note**: read the most recent daily note before today
   - If `processed: false`, summarize unfinished tasks and insights
   - Present carried items (`[>]`, `[~]`, `[!]`) to the user

4. **Check today's note**: read `~/notes-vault/dailies/{today}.md`
   - If it doesn't exist, create from `~/notes-vault/templates/daily-note-template.md`
   - Set frontmatter `id` to today's date (YYYY-MM-DD)

5. **Read current weekly note**: `~/notes-vault/weeklies/YYYY-WW.md`
   - Show high-level goals for context (do NOT offer to update the weekly)

6. **Present summary** to user:
   - Yesterday's carried items
   - Today's current state
   - Weekly goals for reference
   - Ask user to define The Three

7. **After user provides The Three**: update today's note

## Important

- Follow zettelkasten conventions in `~/notes-vault/1764149776-zettelkasten-approach.md`
- Always check `~/notes-vault/templates/` before creating notes
- Weekly notes are high-level only. Never offer to update them (except at creation)
- Use task statuses: `[ ]` pending, `[x]` done, `[>]` ongoing, `[~]` needs attention, `[!]` blocked
