---
name: commit
description: Create a git commit following strict message conventions. Use when user says "commit", "commit changes", or similar.
user-invocable: true
disable-model-invocation: false
allowed-tools: Bash, Read, Grep, Glob
---

# Commit

Create a git commit with a well-crafted message.

## Commit Message Rules

1. **Subject under 50 characters.** Hard limit.
2. **Imperative mood.** "Add feature", not "Added feature".
3. **No project jargon.** Someone who does not know the project should get
   the gist.
4. **No Claude Code references.** No emoji, no co-authored-by, no AI mentions.
5. **Concise.** Body is 2 to 4 lines on the why and the high level what, not
   a list of files. Cut any sentence that adds nothing.
6. **Body wrapped at 72 characters.**
7. **Blank line between subject and body.**
8. **No point-in-time state.** Commit messages live forever. Lines like "not
   yet on npm", "currently in beta" or "for now" are true when written and
   stale within weeks. Write the lasting why.
9. **Plain English.** Readers are not all native English speakers. Short
   sentences, everyday words. Pick the simplest word that is still correct.
   Product terms like SharePoint or retry are fine.
10. **No em-dashes.** Use a period, a comma, or "so" and "and".
11. **Atomic.** One logical change per commit. If the staged files cover
    unrelated changes, split them into separate commits.
12. **State what is.** The body says what the code does now, in present
    tense. No story of the old behaviour, no flags or process internals.
13. **Match the repo's form.** Read full messages (`git log -10
    --format='%s%n%b'`), not just subjects. If small changes there are
    subject only, so is yours.

## Steps

1. Run `git status` (never `-uall`) and `git diff --staged`. Run `git diff`
   for unstaged changes. Summarise both for the user.

2. If nothing is staged, ask what to stage. Suggest specific files from the
   diff. Never stage everything blindly.

3. Read `git log -10 --format='%s%n%b'` to match repo style where it does
   not conflict with these rules.

4. Draft the message, present it, then **STOP and end the turn.** Never
   present and commit in the same turn. "Commit" approves staging and
   drafting, not the commit itself. Wait for a separate go-ahead.

   ```
   Subject line here

   Short body on why the change was made and what it does.
   ```

5. Once approved, create the commit.

   Subject only, no special characters (`'`, `"`, `` ` ``, `$`):
   ```bash
   git commit -m "Subject line here"
   ```

   With a body or special characters, use a heredoc:
   ```bash
   git commit -m "$(cat <<'EOF'
   Subject line here

   Body here.
   EOF
   )"
   ```

6. Run `git status` after to confirm it worked.

## Important

- Present the message and run `git commit` in separate turns
- Never push unless the user asks
- Never use `git add -A` or `git add .`, add specific files
- Never amend unless the user asks, always create new commits
- Never skip hooks (`--no-verify`)
- If a pre-commit hook fails, fix the problem and create a new commit
- If a hook cannot run (e.g. `Can't find lefthook in PATH`), stop and tell
  the user. Commit from where the hook runs, such as the dev container
- Never stash, edit or revert uncommitted work outside the commit. To split
  one file over two commits, ask first
- If a command is rejected, check whether it ran before reporting state
