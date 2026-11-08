---
name: process-note
description: Process a daily note: review for permanent note candidates, mark as processed. Use when user says "process note", "process yesterday", or similar.
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
argument-hint: "[YYYY-MM-DD]"
---

# Process Note

Process a daily note for zettelkasten-worthy insights.

If an argument is provided, process that date's note. Otherwise process
yesterday's note.

**Target date:** $ARGUMENTS

## Steps

1. **Read the daily note** at `~/notes-vault/dailies/{date}.md`

2. **Review content** for:
   - Insights or learnings worth a permanent note
   - Decisions made that should be documented
   - New information about projects or stakeholders
   - Patterns or recurring themes across recent notes

3. **Present findings** to user:
   - List potential permanent note candidates with brief description
   - For each, explain why it's worth capturing
   - Ask which ones to create

4. **Create permanent notes** if user approves:
   - Follow zettelkasten conventions (`~/notes-vault/1764149776-zettelkasten-approach.md`)
   - Use `date +%s` for timestamp
   - Link to relevant index files
   - Link back from the daily note if appropriate

5. **Mark note as processed**: set `processed: true` in frontmatter

## Important

- Not every daily note produces permanent notes, that's fine
- Focus on non-obvious insights, not routine task completion
- Check stakeholders reference at `~/notes-vault/reference/*-stakeholders.md` if new people appear
