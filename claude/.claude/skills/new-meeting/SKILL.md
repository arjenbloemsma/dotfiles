---
name: new-meeting
description: Create a meeting note from template with stakeholder lookup. Use when user says "new meeting", "meeting note", "create meeting note", or similar.
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
argument-hint: "[subject]"
---

# New Meeting Note

Create a meeting note using the vault template and populate with stakeholder info.

**Subject:** $ARGUMENTS

## Steps

1. **Read template** at `~/notes-vault/templates/meeting-note-template.md`

2. **Ask user for**:
   - Subject (if not provided as argument)
   - Participants (first names are enough)
   - Project (if applicable)
   - Date (default: today)

3. **Look up participants** in `~/notes-vault/reference/*-stakeholders.md`
   - Pull full names and titles
   - If a name is not found, ask user and offer to add to reference file

4. **Search for related meeting notes**:
   - Grep vault for `meeting-note` tagged files mentioning same subject or participants
   - Check index files related to the project/topic
   - Present found notes to user as context
   - Add relevant ones as links in a `## Related` section

5. **Create the note**:
   - Generate timestamp: `date +%s`
   - Filename: `{timestamp}-meeting-{kebab-case-subject}.md`
   - Location: vault root (`~/notes-vault/`)
   - Frontmatter: subject, project, date, participants list, tags
   - Add participant details (name, title) in notes section
   - Add `## Related` section with links to previous meeting notes and relevant index files

6. **Link to today's daily note** if it exists

## Important

- Follow zettelkasten conventions (`~/notes-vault/1764149776-zettelkasten-approach.md`)
- Use standard markdown links, not wiki-style
- Meeting notes go to vault root (flat structure), not a meetings folder
