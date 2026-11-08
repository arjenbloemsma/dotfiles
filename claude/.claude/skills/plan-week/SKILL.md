---
name: plan-week
description: Weekly planning workflow. Process previous week's weekly note, create this week's weekly from template, and pick goals. Use when user says "plan week", "weekly", "new week", "start week", or similar.
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent
---

# Plan Week

Execute the weekly planning workflow: process the previous week's
weekly note, create this week's from template, and pick goals.

## Steps

1. **Determine ISO week labels**: run `date +%G-%V` for this week and
   `date -v-7d +%G-%V 2>/dev/null || date -d '7 days ago' +%G-%V` for
   the previous week. Use `%G` ISO year and `%V` ISO week, never `%Y`
   or `%W`, because they diverge at year boundaries.

2. **Process previous week's weekly**: find
   `~/notes-vault/weeklies/{prev-YYYY-WW}.md`
   - If it exists and `processed: false`, flip the field to `true`
   - If it does not exist, skip silently

3. **Check this week's weekly**:
   `~/notes-vault/weeklies/{YYYY-WW}.md`
   - If it exists, read it; present goals to the user and ask whether
     to keep, edit, or replace before proceeding
   - If it does not exist, create from
     `~/notes-vault/templates/weekly-note-template.md`

4. **Suggest goals**: offer to delegate to the `weekly-planner` agent
   - Brief the agent with last week's open items, carried tasks, and
     recent vault activity
   - Present the agent's suggestions to the user
   - If the agent drops a carry-over from the previous week without
     explanation, flag it to the user

5. **Pick + write goals**: let the user pick, drop, merge, or
   rephrase
   - Write goals as **concise one-liners in plain English** matching
     the template's bullet style, no multi-line elaborations
   - If a goal needs context (deadline, owner, scope), put it inline
     in parentheses

## Important

- Weekly notes are high-level planning only. Never offer progress
  updates after creation (only modify on user request)
- The `weekly-planner` agent is read-only (Read/Glob/Grep). It
  cannot write the weekly note; this skill does the writes
