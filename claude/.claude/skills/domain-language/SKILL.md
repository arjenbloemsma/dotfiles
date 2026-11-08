---
name: domain-language
description: Keep the repo's domain language in docs/domain-language.md current. Use when a domain term is used loosely, means two different things, or turns out not to match the code. Runs alongside grilling, code review, or implementation.
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, Agent
---

# Domain Language

`docs/domain-language.md` holds the domain terms and what they mean, so the same
word means the same thing in a PRD, in the code and in the next conversation.

No implementation detail, no file paths, no schema. A definition needing a code
sample is wrong.

- A term used loosely gets pinned down and written in.
- A term used differently from the file gets raised, and one of the two changes.
- A claim contradicting the code gets raised. Check the code.

Write the entry as soon as the term is settled, not at the end.

Create the file if it does not exist yet.
