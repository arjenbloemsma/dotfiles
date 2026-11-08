---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Bash, Edit, Agent, Skill
---

# Grill Me

Interview me relentlessly about every aspect of this plan until we reach a
shared understanding. Walk down each branch of the design tree, resolving
dependencies between decisions one-by-one. For each question, provide your
recommended answer.

Ask one question per turn. Wait for my answer before posing the next.
Never dump a list of questions in a single message.

If a question can be answered by exploring the codebase, explore the codebase
instead.

## Before starting

Read `~/notes-vault/1775216770-prd-lifecycle-management.md` for the grilling
categories and the readiness checklist.

## First question: who will be present

- **Supervised**. I am in the loop. Close the design decisions.
- **Unattended**. Close the design decisions and every failure path: the call
  fails, the field is empty, the value is out of range, the same run happens
  twice.

The bar for unattended is that an agent could implement it three days from now,
having never seen this conversation.

## Domain language

Run the domain-language skill alongside the interview.

## Recording the outcome

When grilling a PRD in `docs/backlog/`:

- Closed decisions go into **Design Decisions** as positive statements of the
  chosen design.
- The matching entries leave **Open Questions**.
- No transcript, no rejected alternatives, no "considered X but".

Touch no other section. No amendment row.

With no PRD in play, stay read-only.

## Closing verdict

End with:

1. **Decisions closed.** One line each.
2. **Still open.** What is unresolved and what it blocks.
3. **Grade.** Supervised or unattended.

Unattended grade needs Open Questions and Not yet specified both empty, a
decided answer for every failure path, and a command behind every criterion.
